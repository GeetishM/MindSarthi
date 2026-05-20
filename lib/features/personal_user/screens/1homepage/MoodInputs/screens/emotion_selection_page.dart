import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import '../models/mood.dart';
import '../models/mood_provider.dart';

class EmotionSelectionPage extends StatefulWidget {
  final Mood mood;

  const EmotionSelectionPage({super.key, required this.mood});

  @override
  State<EmotionSelectionPage> createState() => _EmotionSelectionPageState();
}

class _EmotionSelectionPageState extends State<EmotionSelectionPage> {
  final List<String> _selectedEmotions = [];
  final List<String> _selectedActivities = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  final List<String> _positiveEmotions = [
    'Happy', 'Proud', 'Calm', 'Confident', 'Content', 'Hopeful', 'Joyful', 'Excited', 'Grateful'
  ];
  final List<String> _negativeEmotions = [
    'Sad', 'Angry', 'Afraid', 'Ashamed', 'Disappointed', 'Lonely', 'Guilty', 'Nervous', 'Upset'
  ];

  final List<Map<String, dynamic>> _activitiesList = const [
    {'name': 'Sleep', 'icon': CupertinoIcons.bed_double},
    {'name': 'Work', 'icon': CupertinoIcons.briefcase},
    {'name': 'Study', 'icon': CupertinoIcons.book},
    {'name': 'Health', 'icon': CupertinoIcons.heart},
    {'name': 'Exercise', 'icon': CupertinoIcons.sportscourt},
    {'name': 'Friends', 'icon': CupertinoIcons.person_2},
    {'name': 'Family', 'icon': CupertinoIcons.house},
    {'name': 'Hobbies', 'icon': CupertinoIcons.gamecontroller},
    {'name': 'Food', 'icon': CupertinoIcons.cart},
    {'name': 'Weather', 'icon': CupertinoIcons.cloud_sun},
  ];

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);
    try {
      final moodProvider = Provider.of<MoodProvider>(context, listen: false);
      await moodProvider.saveMoodEntry(
        mood: widget.mood.name,
        emotions: _selectedEmotions,
        activities: _selectedActivities,
        notes: _notesController.text,
      );

      if (mounted) {
        AppToast.success(
          context,
          'Mood Tracked',
          description: 'Your daily mood log was captured successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          'Error Logging Mood',
          description: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleEmotion(String emotion) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else if (_selectedEmotions.length < 3) {
        _selectedEmotions.add(emotion);
      } else {
        AppToast.warning(
          context,
          'Limit Reached',
          description: 'You can select up to 3 sub-emotions.',
        );
      }
    });
  }

  void _toggleActivity(String activity) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Log Mood',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.mood.color.withOpacity(0.85),
                      widget.mood.color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.mood.color.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.mood.icon, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YOU FEEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.mood.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Part 1: Emotions Selection ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'What feelings describe this?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${_selectedEmotions.length}/3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _selectedEmotions.length == 3 ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildEmotionChips('Positive Vibes', _positiveEmotions, AppColors.success, isDark),
              const SizedBox(height: 20),
              _buildEmotionChips('Challenging Emotions', _negativeEmotions, AppColors.error, isDark),
              const SizedBox(height: 32),

              // --- Part 2: Factors Selection ---
              Text(
                'What is making you feel this way?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildActivitiesGrid(isDark),
              const SizedBox(height: 32),

              // --- Part 3: Notes ---
              Text(
                'Add any details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: TextField(
                  controller: _notesController,
                  maxLines: 4,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Notes or thoughts...',
                    hintStyle: TextStyle(
                      color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Complete Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.mood.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Text(
                          'Save Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionChips(String sectionTitle, List<String> emotions, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emotions.map((emotion) {
            final isSelected = _selectedEmotions.contains(emotion);
            return GestureDetector(
              onTap: () => _toggleEmotion(emotion),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : (isDark ? AppColors.darkSurface : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: 1,
                  ),
                ),
                child: Text(
                  emotion,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? color
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActivitiesGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _activitiesList.length,
      itemBuilder: (context, index) {
        final activity = _activitiesList[index];
        final name = activity['name'] as String;
        final icon = activity['icon'] as IconData;
        final isSelected = _selectedActivities.contains(name);

        return GestureDetector(
          onTap: () => _toggleActivity(name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.mood.color.withOpacity(0.15)
                  : (isDark ? AppColors.darkSurface : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? widget.mood.color
                    : (isDark ? AppColors.darkBorder : AppColors.border),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? widget.mood.color
                      : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? widget.mood.color
                        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
