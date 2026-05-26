import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final Box _prefsBox;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _prefsBox = await Hive.openBox('notification_prefs');
    setState(() => _isInitialized = true);
  }

  Future<void> _toggleSetting(String key, bool currentValue) async {
    await _prefsBox.put(key, !currentValue);
    setState(() {});
    
    // Proactively reschedule or cancel daily reminders if needed
    if (key == 'mood_reminders' ||
        key == 'goal_streak_reminders' ||
        key == 'depression_support_reminders' ||
        key == 'journal_streak_reminders') {
      await NotificationService.scheduleDailyReminders();
    }
    
    if (mounted) {
      AppToast.success(context, 'Notification settings updated');
    }
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required String prefKey,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final bool value = _prefsBox.get(prefKey, defaultValue: true) as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NeumorphicContainer(
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.0,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              activeColor: AppColors.primary,
              onChanged: (_) => _toggleSetting(prefKey, value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 20),
                  child: Text(
                    'Customize your MindSarthi alerts to stay connected with your wellness journey.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
                _buildToggleTile(
                  title: 'Mood Reminders',
                  subtitle: 'Daily gentle check-ins in the morning to track your mood.',
                  prefKey: 'mood_reminders',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: Colors.amber,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'Journal Streaks',
                  subtitle: 'Evening reminders to keep your writing habit active and prevent losing streaks.',
                  prefKey: 'journal_streak_reminders',
                  icon: Icons.edit_note_rounded,
                  iconColor: AppColors.primary,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'Goal Streaks',
                  subtitle: 'Reflect on your daily goals and celebrate continuous streaks.',
                  prefKey: 'goal_streak_reminders',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orange,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'New Insights',
                  subtitle: 'Get notified when professional therapists publish new mental health insights.',
                  prefKey: 'new_insight_notifications',
                  icon: Icons.lightbulb_rounded,
                  iconColor: Colors.teal,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'Session Alerts',
                  subtitle: 'Timely reminders before your scheduled counselling sessions start.',
                  prefKey: 'session_reminders',
                  icon: Icons.calendar_today_rounded,
                  iconColor: Colors.blueAccent,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'Profile Reminders',
                  subtitle: 'Helpful nudges to complete your profile for a customized experience.',
                  prefKey: 'profile_completion_reminders',
                  icon: Icons.account_circle_rounded,
                  iconColor: Colors.purple,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildToggleTile(
                  title: 'Depression Support',
                  subtitle: 'Supportive guidance reminders if you feel distressed or down.',
                  prefKey: 'depression_support_reminders',
                  icon: Icons.healing_rounded,
                  iconColor: Colors.pinkAccent,
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
    );
  }
}
