import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import '../models/mood.dart';
import '../screens/emotion_selection_page.dart';
import 'mood_insights_page.dart';

class MoodTrackerHomePage extends StatelessWidget {
  const MoodTrackerHomePage({super.key});

  final List<Mood> moods = const [
    Mood('Awesome', Icons.sentiment_very_satisfied_rounded, Color(0xFFFFB300)), // Soft Gold
    Mood('Good', Icons.sentiment_satisfied_rounded, AppColors.success), // Soft Green
    Mood('Okay', Icons.sentiment_neutral_rounded, AppColors.primary), // Healing Teal
    Mood('Bad', Icons.sentiment_dissatisfied_rounded, AppColors.accent), // Warm Coral
    Mood('Terrible', Icons.sentiment_very_dissatisfied_rounded, AppColors.error), // Soft Red
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track daily wellness trends',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const MoodInsightsPage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Insights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 14,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods.map((mood) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildMoodButton(context, mood, isDark),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodButton(BuildContext context, Mood mood, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => EmotionSelectionPage(mood: mood),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.border).withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: mood.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mood.icon,
                size: 24,
                color: mood.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mood.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
