import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // 1. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 2. Request notification permission
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
        debugPrint('NotificationService: User granted permission');
      } else {
        debugPrint('NotificationService: User declined or restricted permission');
      }

      // 3. Get and print FCM registration token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');

      // 4. Listen for foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground notification: ${message.notification?.title} - ${message.notification?.body}');
      });

      // 5. Handle user interactions when tapping a notification from background/terminated states
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('User tapped background notification: ${message.data}');
      });
      
      // Check if opened from a terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state via notification: ${initialMessage.data}');
      }

    } catch (e) {
      debugPrint('NotificationService: Initialization failed - $e');
    }
  }
}
