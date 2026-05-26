import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/Journal/journal_entry.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Initialize Timezones (required for scheduled notifications)
      tz.initializeTimeZones();

      // 2. Request Android 13+ Local Notification Permission
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      // 3. Initialize Local Notifications settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification clicked: ${response.payload}');
        },
      );

      // 4. Schedule Daily Reminders
      await scheduleDailyReminders();

      // 5. Seed Welcome Notification if empty
      final box = Hive.box('notificationsBox');
      if (box.isEmpty) {
        await addNotification(
          title: 'Welcome to MindSarthi! 🧘',
          body: 'We are thrilled to have you here. Let\'s make self-care a daily habit.',
        );
      }

    } catch (e) {
      debugPrint('NotificationService: Initialization failed - $e');
    }
  }

  static Future<bool> checkIfUserIsDepressed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasVisitedDepression = prefs.getBool('has_visited_depression_support') ?? false;
      if (hasVisitedDepression) return true;

      final journalBox = Hive.box<JournalEntry>('journalBox');
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final distressedEntry = journalBox.values.any((entry) {
        if (entry.createdAt.isBefore(sevenDaysAgo)) return false;
        if (entry.sentimentScore != null && entry.sentimentScore! <= 4.0) return true;
        if (entry.crisisFlag == true) return true;
        if (entry.sentimentEmotions != null) {
          final depressedEmotions = {
            'sad',
            'sadness',
            'depressed',
            'depression',
            'grief',
            'lonely',
            'loneliness',
            'hopeless',
            'hopelessness'
          };
          if (entry.sentimentEmotions!.any((emotion) => depressedEmotions.contains(emotion.toLowerCase()))) {
            return true;
          }
        }
        return false;
      });
      if (distressedEntry) return true;
    } catch (_) {
      // In case boxes are not open or other error
    }
    return false;
  }

  /// Schedule daily notifications for Mood Check-in and Goal Reflection.
  static Future<void> scheduleDailyReminders() async {
    try {
      // 1. Schedule Morning Mood Check-in at 9:00 AM
      await _localNotifications.zonedSchedule(
        1, // Notification ID
        'How is your mood today? 🌸',
        "Good morning! Take a moment to check in with your mind.",
        _nextInstanceOfTime(9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_mood_channel',
            'Daily Mood Reminders',
            channelDescription: 'Reminds you to check in your mood daily',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // 2. Schedule Evening Goal Reflection at 8:00 PM
      await _localNotifications.zonedSchedule(
        2, // Notification ID
        'Time to reflect 🧠',
        'Have you completed your goals today? Keep your streak alive! 🔥',
        _nextInstanceOfTime(20, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_goals_channel',
            'Daily Goal Reminders',
            channelDescription: 'Reminds you to complete your goals daily',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // 3. Schedule Daily Depression Support reminder if they are flagged/detected as depressed
      final isDepressed = await checkIfUserIsDepressed();
      if (isDepressed) {
        await _localNotifications.zonedSchedule(
          10, // Depression support reminder ID
          'You are not alone 🌟',
          'Remember to take it one small step at a time today. Open Depression Support for gentle coping tools.',
          _nextInstanceOfTime(14, 0), // 2:00 PM
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'depression_support_channel',
              'Depression Support Reminders',
              channelDescription: 'Sends daily gentle reminders if feeling down',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('NotificationService: Depression support daily reminder scheduled at 2:00 PM.');
      } else {
        await _localNotifications.cancel(10);
        debugPrint('NotificationService: Depression support daily reminder cancelled/disabled.');
      }
      
      debugPrint('NotificationService: Daily reminders scheduled successfully.');
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule daily reminders - $e');
    }
  }

  /// Helper to get next instance of a specific time.
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Add a notification to local storage
  static Future<void> addNotification({
    required String title,
    required String body,
  }) async {
    try {
      final box = Hive.box('notificationsBox');
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Store as a Map<String, dynamic>
      await box.put(id, {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
      debugPrint('NotificationService: Saved notification locally: $title');
    } catch (e) {
      debugPrint('NotificationService: Failed to save notification - $e');
    }
  }

  /// Show an instant notification for streak milestones.
  static Future<void> showStreakCelebration(int streakCount) async {
    try {
      const String title = 'Goal Streak! 🔥';
      final String body = 'Incredible! You have maintained a $streakCount-day streak! Keep going! 🚀';

      await addNotification(title: title, body: body);

      await _localNotifications.show(
        3, // Notification ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'streak_channel',
            'Streak Celebrations',
            channelDescription: 'Celebrates your streak achievements',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('NotificationService: Streak celebration shown.');
    } catch (e) {
      debugPrint('NotificationService: Failed to show streak celebration - $e');
    }
  }

  /// Show an instant notification immediately.
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await addNotification(title: title, body: body);

      await _localNotifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_reminders_channel',
            'Instant Reminders',
            channelDescription: 'Shows immediate supportive notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('NotificationService: Instant notification shown.');
    } catch (e) {
      debugPrint('NotificationService: Failed to show instant notification - $e');
    }
  }

  /// Schedule a daily reminder to complete profile if it is incomplete.
  static Future<void> scheduleProfileCompletionReminder(bool isProfileIncomplete) async {
    try {
      if (isProfileIncomplete) {
        await _localNotifications.zonedSchedule(
          11, // Profile completion reminder ID
          'Complete your MindSarthi Profile 🧘',
          'Help us personalize your wellness experience by completing your profile details.',
          _nextInstanceOfTime(12, 0), // Daily at 12:00 PM
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'profile_completion_channel',
              'Profile Completion Reminders',
              channelDescription: 'Reminds you to complete your profile details',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        debugPrint('NotificationService: Profile completion daily reminder scheduled at 12:00 PM.');
      } else {
        await _localNotifications.cancel(11);
        debugPrint('NotificationService: Profile completion daily reminder cancelled/disabled.');
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule profile completion reminder - $e');
    }
  }
}
