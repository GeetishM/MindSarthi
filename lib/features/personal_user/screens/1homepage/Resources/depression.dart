import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';
import 'package:mindsarthi/core/services/notification_service.dart';

class Depression extends StatefulWidget {
  const Depression({super.key});

  @override
  State<Depression> createState() => _DepressionState();
}

class _DepressionState extends State<Depression> {
  // Positive Affirmations list
  final List<String> _affirmations = [
    "I am worthy of love, peace, and happiness, exactly as I am.",
    "This feeling is temporary. I have survived difficult days before, and I will get through this.",
    "I am allowed to rest. Taking care of myself is productive.",
    "My worth is not defined by my productivity or my mood.",
    "I release the pressure to be perfect and embrace myself with kindness.",
    "Small steps forward are still steps forward. I celebrate my tiny victories.",
    "I am surrounded by support, even when my mind tells me I am alone.",
    "I choose to treat myself with the same compassion I show to others."
  ];
  
  int _currentAffirmationIndex = 0;
  bool _isFlipped = false; // For card transition effect
  
  // Activity checklist state
  final List<String> _activities = [
    'Drink a full glass of water',
    'Open the blinds / let light in',
    'Stretch or walk for 5 minutes',
    'Write down one tiny thing you are grateful for',
    'Reach out to one supportive person (text or call)',
  ];
  final Map<String, bool> _activityStates = {};
  late Box<Task> _tasksBox;

  @override
  void initState() {
    super.initState();
    _tasksBox = Hive.box<Task>('tasksBox');
    _loadDailyData();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getCategoryForActivity(String activity) {
    switch (activity) {
      case 'Drink a full glass of water':
        return 'Health';
      case 'Open the blinds / let light in':
        return 'Self-Care';
      case 'Stretch or walk for 5 minutes':
        return 'Health';
      case 'Write down one tiny thing you are grateful for':
        return 'Mindfulness';
      case 'Reach out to one supportive person (text or call)':
        return 'Personal';
      default:
        return 'Self-Care';
    }
  }

  void _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final lastResetDate = prefs.getString('dep_last_reset_date') ?? '';

    int affIndex = prefs.getInt('dep_daily_affirmation_index') ?? 0;

    if (lastResetDate != todayStr) {
      affIndex = (affIndex + 1) % _affirmations.length;
      await prefs.setString('dep_last_reset_date', todayStr);
      await prefs.setInt('dep_daily_affirmation_index', affIndex);
    }

    setState(() {
      _currentAffirmationIndex = affIndex;
    });

    await prefs.setBool('has_visited_depression_support', true);
    NotificationService.scheduleDailyReminders();

    _loadActivityChecklist();
  }

  void _loadActivityChecklist() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    setState(() {
      for (var activity in _activities) {
        Task? existingTask;
        try {
          existingTask = _tasksBox.values.firstWhere(
            (task) => task.title == activity && _isSameDay(task.date, todayStart)
          );
        } catch (_) {
          existingTask = null;
        }

        if (existingTask != null) {
          _activityStates[activity] = existingTask.isCompleted;
        } else {
          final category = _getCategoryForActivity(activity);
          final newTask = Task(
            title: activity,
            isCompleted: false,
            date: todayStart,
            category: category,
          );
          _tasksBox.add(newTask);
          _activityStates[activity] = false;
        }
      }
    });
  }

  void _toggleActivity(String activity) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    setState(() {
      final current = _activityStates[activity] ?? false;
      final newVal = !current;
      _activityStates[activity] = newVal;

      Task? existingTask;
      try {
        existingTask = _tasksBox.values.firstWhere(
          (task) => task.title == activity && _isSameDay(task.date, todayStart)
        );
      } catch (_) {
        existingTask = null;
      }

      if (existingTask != null) {
        existingTask.isCompleted = newVal;
        existingTask.save();
      } else {
        final newTask = Task(
          title: activity,
          isCompleted: newVal,
          date: todayStart,
          category: _getCategoryForActivity(activity),
        );
        _tasksBox.add(newTask);
      }
    });
  }

  void _cycleAffirmation() async {
    HapticFeedback.selectionClick();
    setState(() {
      _isFlipped = true;
    });
    final nextIndex = (_currentAffirmationIndex + 1) % _affirmations.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dep_daily_affirmation_index', nextIndex);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _currentAffirmationIndex = nextIndex;
        _isFlipped = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        title: const Text('Depression support'),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/navbar');
          },
          icon: Icon(
            CupertinoIcons.back,
            size: 22,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Interactive Affirmations Card (Flip-style transition)
              GestureDetector(
                onTap: _cycleAffirmation,
                child: AnimatedScale(
                  scale: _isFlipped ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF151930), AppColors.darkSurface]
                            : [const Color(0xFFEEF0FC), Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.indigo.shade800.withValues(alpha: 0.3)
                            : Colors.indigo.shade200.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'DAILY AFFIRMATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigoAccent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.sparkles,
                              size: 16,
                              color: isDark ? Colors.indigo.shade300 : Colors.indigoAccent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _isFlipped ? 0.0 : 1.0,
                          child: Text(
                            '"${_affirmations[_currentAffirmationIndex]}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.refresh_thin,
                              size: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap card to cycle affirmation',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Activity Checklist Header
              Text(
                'DAILY MINDFUL PROGRESS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Activity checklist list
              ..._activities.map((activity) {
                final completed = _activityStates[activity] ?? false;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Card(
                    color: isDark ? AppColors.darkSurface : AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: completed
                            ? Colors.indigoAccent.withValues(alpha: 0.3)
                            : (isDark ? AppColors.darkBorder : AppColors.border),
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      leading: Checkbox(
                        value: completed,
                        activeColor: Colors.indigoAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (_) => _toggleActivity(activity),
                      ),
                      title: Text(
                        activity,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          decoration: completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? (isDark ? AppColors.darkTextHint : AppColors.textHint)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 28),

              // 3. Navigation resources
              Text(
                'COPING RESOURCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // Journal Prompt Navigation
              _buildIOSResourceCard(
                icon: CupertinoIcons.pencil_outline,
                title: 'Guided Reflection Journal',
                subtitle: 'Write down your feelings with helper prompts',
                color: AppColors.primary,
                isDark: isDark,
                onTap: () {
                  // Direct to /journal route
                  Navigator.pushNamed(context, '/journal');
                },
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSResourceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
