import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

// Top-level background message handler required by FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint("Handling a background message: ${message.messageId}");
}

class FcmService {
  final NotificationService _localNotifications;

  FcmService(this._localNotifications);

  Future<void> init() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCM Authorization Status: ${settings.authorizationStatus}');

      // Fetch the FCM token for testing push notifications
      final token = await messaging.getToken();
      debugPrint("FCM Registration Token: $token");

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground Message: ${message.notification?.title}');
        if (message.notification != null) {
          _localNotifications.showProximityAlert(
            title: message.notification?.title ?? 'BRAD Update',
            body: message.notification?.body ?? '',
            packageId: message.data['packageId'] ?? 'fcm_update',
          );
        }
      });

      // Handle notification tap when app opened from terminated status
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      // Handle notification tap when app opened from background status
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    } catch (e) {
      debugPrint('FCM initialization skipped or offline: $e');
    }
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('App opened via FCM notification tap: ${message.data}');
  }
}
