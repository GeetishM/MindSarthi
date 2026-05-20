import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/streak_model.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendar extends StatelessWidget {
  final StreakModel streakModel;
  final Function(DateTime) onDaySelected;

  const StreakCalendar({
    super.key,
    required this.streakModel,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Premium Streak Display Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                  ? [AppColors.darkPrimaryLight, AppColors.darkSurface] 
                  : [primaryColor.withOpacity(0.12), AppColors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Flame and current streak
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.redAccent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        CupertinoIcons.flame_fill,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${streakModel.currentStreak}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Current Streak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Vertical divider
                Container(
                  height: 40,
                  width: 1.5,
                  color: borderCol,
                ),

                // Trophy and best streak
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.amber.shade400, Colors.amber.shade800],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: const Icon(
                        CupertinoIcons.star_fill,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${streakModel.bestStreak}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Best Streak',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Calendar Card
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderCol, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(CupertinoIcons.left_chevron, color: primaryColor),
                rightChevronIcon: Icon(CupertinoIcons.right_chevron, color: primaryColor),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                weekendStyle: TextStyle(color: primaryColor.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                weekendTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final truncatedDay = DateTime(day.year, day.month, day.day);
                  bool isCompleted = streakModel.completedDays.contains(truncatedDay);
                  if (isCompleted) {
                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                onDaySelected(selectedDay);
              },
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            "Green days represent fully completed checklists! Tap a day to view or edit tasks.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}