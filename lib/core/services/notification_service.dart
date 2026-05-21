import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:hive/hive.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      // 1. Initialize Timezones (required for scheduled notifications)
      tz.initializeTimeZones();

      // 2. Register Firebase background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request Firebase notification permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('NotificationService: Firebase permission granted');
      } else {
        debugPrint('NotificationService: Firebase permission declined');
      }

      // 4. Request Android 13+ Local Notification Permission
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      // 5. Initialize Local Notifications settings
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

      // 6. Schedule Daily Reminders
      await scheduleDailyReminders();

      // 7. Get and print FCM registration token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // 8. Listen for foreground notifications (FCM)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground notification: ${message.notification?.title} - ${message.notification?.body}');
        if (message.notification != null) {
          addNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
          );
        }
      });

      // 9. Handle user interactions when tapping a notification from background/terminated states
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('User tapped background notification: ${message.data}');
      });
      
      // Check if opened from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state via notification: ${initialMessage.data}');
      }

      // 10. Seed Welcome Notification if empty
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
}
