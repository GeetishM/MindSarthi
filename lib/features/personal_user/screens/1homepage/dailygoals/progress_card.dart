import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';

class ProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final String title;

  const ProgressCard({
    super.key,
    required this.completed,
    required this.total,
    this.title = "Daily Progress",
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : completed / total;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    // Progress color determination
    Color progressColor = primaryColor;
    if (progress == 1.0) {
      progressColor = AppColors.success;
    } else if (progress > 0.5) {
      progressColor = Colors.teal;
    } else if (progress > 0.0) {
      progressColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:  isDark ? 0.15 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Title and Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha:  0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      progress == 1.0 ? CupertinoIcons.star_fill : CupertinoIcons.chart_bar_fill,
                      color: progress == 1.0 ? Colors.amber[700] : progressColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: progressColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkPrimaryLight : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          
          const SizedBox(height: 14),
          
          // Dynamic motivational text
          Text(
            total == 0
                ? "No goals set for this day."
                : "$completed of $total goals completed",
            style: TextStyle(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 0
                ? "Tap the '+' button below to add your first goal!"
                : completed == 0
                    ? "Every journey begins with a single step. Start today!"
                    : completed < total
                        ? "You're making great progress! Keep going."
                        : "Amazing! You completed all your goals today! 🎉",
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
