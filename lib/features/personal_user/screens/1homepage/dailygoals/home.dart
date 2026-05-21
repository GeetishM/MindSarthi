import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/notification_service.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/analytics_helper.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/database.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/progress_card.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/streak_calendar.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/streak_model.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/task.dart';

class TodaysGoals extends StatefulWidget {
  const TodaysGoals({super.key});

  @override
  State<TodaysGoals> createState() => _TodaysGoalsState();
}

class _TodaysGoalsState extends State<TodaysGoals> {
  final ToDoDataBase db = ToDoDataBase();
  int _activeTab = 0; // 0 for Goals list, 1 for Calendar/Streaks
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'All';

  // Available categories
  final List<String> _categories = [
    'All',
    'Self-Care',
    'Work',
    'Personal',
    'Health',
    'Mindfulness',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    db.loadData();
    // Align _selectedDate to start of day for accurate comparison
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  // Checkbox tapped
  void _checkboxChanged(Task task) {
    final bool wasCompleted = task.isCompleted;
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
    db.updateDataBase();

    // Check if the task was newly marked as completed
    if (!wasCompleted && task.isCompleted) {
      final todayTasks = db.toDoList.where((t) => AnalyticsHelper.isSameDay(t.date, DateTime.now())).toList();
      if (todayTasks.isNotEmpty && todayTasks.every((t) => t.isCompleted)) {
        final completedDays = _getCompletedDays();
        final streakModel = StreakModel(completedDays: completedDays);
        final streakVal = streakModel.currentStreak;
        if (streakVal > 0) {
          NotificationService.showStreakCelebration(streakVal);
        }
      }
    }
  }

  // Delete task
  void _deleteTask(Task task) {
    setState(() {
      db.toDoList.remove(task);
    });
    db.updateDataBase();
  }

  // Reschedule task to tomorrow
  void _rescheduleTask(Task task) {
    setState(() {
      task.date = task.date.add(const Duration(days: 1));
      task.rescheduleCount += 1;
    });
    db.updateDataBase();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Rescheduled '${task.title}' to tomorrow"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Generate a list of 7 days centered around today (2 days past, today, 4 days future)
  List<DateTime> _getDateStrip() {
    final today = DateTime.now();
    final startDay = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 2));
    return List.generate(7, (index) {
      return startDay.add(Duration(days: index));
    });
  }

  // Map category to Emojis
  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Self-Care':
        return '🌸';
      case 'Work':
        return '💼';
      case 'Personal':
        return '👤';
      case 'Health':
        return '🍏';
      case 'Mindfulness':
        return '🧠';
      default:
        return '📝';
    }
  }

  // Category specific coloring
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Self-Care':
        return Colors.pink;
      case 'Work':
        return Colors.indigo;
      case 'Personal':
        return Colors.blue;
      case 'Health':
        return Colors.green;
      case 'Mindfulness':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }

  // Show Bottom Sheet to Add or Edit tasks
  void _showTaskBottomSheet({Task? taskToEdit}) {
    final titleController = TextEditingController(text: taskToEdit?.title ?? '');
    String selectedCat = taskToEdit?.category ?? 'Self-Care';
    DateTime selectedDate = taskToEdit?.date ?? _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColors.darkSurface2 : AppColors.white;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  border: Border.all(color: borderCol, width: 0.8),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: borderCol,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      taskToEdit == null ? "New Goal" : "Edit Goal",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Title Field
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "What do you want to achieve?",
                        hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                        filled: true,
                        fillColor: isDark ? AppColors.darkBackground : Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol, width: 0.8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol, width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Category Selection
                    Text(
                      "Category",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categories.where((c) => c != 'All').map((cat) {
                          bool isSelected = selectedCat == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Row(
                                children: [
                                  Text(_getCategoryEmoji(cat)),
                                  const SizedBox(width: 4),
                                  Text(cat),
                                ],
                              ),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                              onSelected: (val) {
                                setModalState(() {
                                  selectedCat = cat;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Schedule Date",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textSecondary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton.filledTonal(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = DateTime(picked.year, picked.month, picked.day);
                              });
                            }
                          },
                          icon: const Icon(CupertinoIcons.calendar),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              if (taskToEdit == null) {
                                // Add
                                setState(() {
                                  db.toDoList.add(Task(
                                    title: titleController.text.trim(),
                                    category: selectedCat,
                                    date: selectedDate,
                                  ));
                                });
                              } else {
                                // Update
                                setState(() {
                                  taskToEdit.title = titleController.text.trim();
                                  taskToEdit.category = selectedCat;
                                  taskToEdit.date = selectedDate;
                                });
                              }
                              db.updateDataBase();
                              Navigator.pop(context);
                            },
                            child: Text(
                              taskToEdit == null ? "Add Goal" : "Save Changes",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Calculate completed days dynamically for the streak model
  Set<DateTime> _getCompletedDays() {
    final Map<String, List<Task>> tasksPerDay = {};
    for (var task in db.toDoList) {
      final key = "${task.date.year}-${task.date.month}-${task.date.day}";
      tasksPerDay.putIfAbsent(key, () => []).add(task);
    }

    final Set<DateTime> completedDays = {};
    tasksPerDay.forEach((key, tasks) {
      if (tasks.isNotEmpty && tasks.every((t) => t.isCompleted)) {
        completedDays.add(DateTime(tasks.first.date.year, tasks.first.date.month, tasks.first.date.day));
      }
    });
    return completedDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    // Filtered tasks for the selected date
    final List<Task> dayTasks = db.toDoList.where((t) => AnalyticsHelper.isSameDay(t.date, _selectedDate)).toList();
    final List<Task> filteredTasks = dayTasks.where((t) {
      if (_selectedCategory == 'All') return true;
      return t.category == _selectedCategory;
    }).toList();

    // Counts for selected day
    final int completedCount = dayTasks.where((t) => t.isCompleted).length;
    final int totalCount = dayTasks.length;

    // Streak calculations
    final completedDays = _getCompletedDays();
    final streakModel = StreakModel(completedDays: completedDays);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Daily Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _activeTab,
              backgroundColor: isDark ? AppColors.darkBackground : Colors.grey.shade100,
              thumbColor: primaryColor,
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.square_list_fill,
                        size: 16,
                        color: _activeTab == 0 ? Colors.white : textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Goals",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _activeTab == 0 ? Colors.white : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.calendar,
                        size: 16,
                        color: _activeTab == 1 ? Colors.white : textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Streaks",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _activeTab == 1 ? Colors.white : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _activeTab = value;
                  });
                }
              },
            ),
          ),
        ),
      ),
      body: _activeTab == 0
          ? RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  db.loadData();
                });
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Progress Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ProgressCard(
                      completed: completedCount,
                      total: totalCount,
                      title: "Checklist Progress",
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Strip Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Select Date",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Date Strip (iOS clean minimal pill style)
                  SizedBox(
                    height: 76,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _getDateStrip().map((date) {
                        bool isSelected = AnalyticsHelper.isSameDay(date, _selectedDate);
                        bool isToday = AnalyticsHelper.isSameDay(date, DateTime.now());
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 58,
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? primaryColor 
                                  : isToday 
                                    ? primaryColor.withOpacity(0.08)
                                    : surfaceColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected 
                                    ? primaryColor 
                                    : isToday
                                      ? primaryColor.withOpacity(0.4)
                                      : borderCol,
                                  width: isSelected ? 1.2 : 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E').format(date).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected 
                                        ? Colors.white 
                                        : textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected 
                                        ? Colors.white 
                                        : textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category Chips Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Filter Category",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category list
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _categories.map((cat) {
                        bool isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Row(
                              children: [
                                if (cat != 'All') ...[
                                  Text(_getCategoryEmoji(cat)),
                                  const SizedBox(width: 4),
                                ],
                                Text(cat),
                              ],
                            ),
                            selected: isSelected,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            selectedColor: primaryColor,
                            backgroundColor: surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isSelected ? primaryColor : borderCol,
                                width: 0.8,
                              ),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tasks List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Goals Checklist",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "${filteredTasks.length} goals",
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tasks List Builder
                  if (filteredTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 64,
                            color: textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No goals found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Tap the '+' button below to add your goals for this category / date.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final catColor = _getCategoryColor(task.category);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: task.isCompleted 
                                  ? AppColors.success.withOpacity(0.3) 
                                  : borderCol,
                                width: task.isCompleted ? 1.2 : 0.8,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(left: 14, right: 8, top: 4, bottom: 4),
                              
                              // Custom Cupertino Checkbox
                              leading: GestureDetector(
                                onTap: () => _checkboxChanged(task),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: task.isCompleted 
                                      ? AppColors.success 
                                      : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: task.isCompleted 
                                        ? AppColors.success 
                                        : textSecondary.withOpacity(0.4),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: task.isCompleted
                                    ? const Icon(
                                        CupertinoIcons.checkmark,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                                ),
                              ),
                              
                              // Task Title & Category Badges
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: task.isCompleted 
                                        ? textSecondary 
                                        : textPrimary,
                                      decoration: task.isCompleted 
                                        ? TextDecoration.lineThrough 
                                        : TextDecoration.none,
                                      decorationColor: textSecondary,
                                      decorationThickness: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      // Category Tag
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _getCategoryEmoji(task.category),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              task.category,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: catColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Reschedule tag if rescheduled
                                      if (task.rescheduleCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                CupertinoIcons.arrow_counterclockwise,
                                                size: 10,
                                                color: Colors.orange,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Rescheduled ${task.rescheduleCount}x",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Edit, reschedule and delete actions
                              trailing: PopupMenuButton<String>(
                                icon: Icon(CupertinoIcons.ellipsis, color: textSecondary, size: 20),
                                color: surfaceColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: borderCol, width: 0.8),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showTaskBottomSheet(taskToEdit: task);
                                  } else if (value == 'reschedule') {
                                    _rescheduleTask(task);
                                  } else if (value == 'delete') {
                                    _deleteTask(task);
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(CupertinoIcons.pencil, color: primaryColor, size: 18),
                                      title: Text('Edit', style: TextStyle(color: textPrimary, fontSize: 14)),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'reschedule',
                                    child: ListTile(
                                      leading: const Icon(CupertinoIcons.arrow_right_circle, color: Colors.orange, size: 18),
                                      title: Text('Reschedule', style: TextStyle(color: textPrimary, fontSize: 14)),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
                                      title: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 14)),
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            )
          : StreakCalendar(
              streakModel: streakModel,
              onDaySelected: (selectedDay) {
                setState(() {
                  _selectedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                  _activeTab = 0;
                });
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskBottomSheet(),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 24),
      ),
    );
  }
}
