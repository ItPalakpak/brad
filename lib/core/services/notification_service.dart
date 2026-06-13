import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(Ref ref) {
  final service = NotificationService();
  // We initialize it inside the provider or app startup
  return service;
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested manually at launch
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle tap - can route to details using path in payload
    final packageId = response.payload;
    if (packageId != null && packageId.isNotEmpty) {
      // Navigation can be handled via global router or a listener
    }
  }

  Future<void> showProximityAlert({
    required String title,
    required String body,
    required String packageId,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'proximity_alerts',
      'Proximity Alerts',
      channelDescription: 'Alerts when near a delivery location',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    await _plugin.show(
      id: packageId.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: packageId,
    );
  }

  Future<void> showTimerDone() async {
    const androidDetails = AndroidNotificationDetails(
      'timer_alerts',
      'Timer Alerts',
      channelDescription: 'Alerts when delivery timer ends',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    await _plugin.show(
      id: 9999,
      title: '⏱ Timer done!',
      body: 'Your delivery timer has ended.',
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
  
  Future<void> requestPermissions() async {
    // Request for Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}
