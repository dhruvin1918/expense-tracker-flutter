import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
      ),
      onDidReceiveNotificationResponse: (details) {
        // TODO: Navigate to budget screen when notification is tapped.
      },
    );
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
    int id =
        0, // ← custom ID so categories don't overwrite each other
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alert_channel',
      'Budget Alerts',
      channelDescription:
          'Notifications for budget usage alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}
