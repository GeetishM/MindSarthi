import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import '../models/mood.dart';
import '../screens/emotion_selection_page.dart';

class MoodTrackerHomePage extends StatelessWidget {
  const MoodTrackerHomePage({super.key});

  final List<Mood> moods = const [
    Mood('Awesome', Icons.sentiment_very_satisfied_rounded, Color(0xFFFFD700)), // Gold
    Mood('Good', Icons.sentiment_satisfied_rounded, Color(0xFF4CAF50)), // Green
    Mood('Okay', Icons.sentiment_neutral_rounded, Color(0xFF2196F3)), // Blue
    Mood('Bad', Icons.sentiment_dissatisfied_rounded, Color(0xFFFF9800)), // Orange
    Mood('Terrible', Icons.sentiment_very_dissatisfied_rounded, Color(0xFFF44336)), // Red
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Track your daily mood to see patterns',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildMoodButton(context, moods[index], isDark);
            },
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
          MaterialPageRoute(
            builder: (context) => EmotionSelectionPage(mood: mood),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: mood.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: mood.color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mood.color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mood.icon,
                size: 36,
                color: mood.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mood.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
