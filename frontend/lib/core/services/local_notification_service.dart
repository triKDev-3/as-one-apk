import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/notification_navigation.dart';

/// Notifications système locales (bandeau + son).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _id = 0;

  Future<void> init() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onSelect,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await Permission.notification.request();

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'asone_alerts',
        'Alertes AS ONE',
        description: 'Affectations, pointages, incidents',
        importance: Importance.high,
        playSound: true,
      ),
    );

    _ready = true;
  }

  static void _onSelect(NotificationResponse response) {
    NotificationNavigation.handlePayload(response.payload);
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) await init();
    _id = (_id + 1) % 100000;

    const android = AndroidNotificationDetails(
      'asone_alerts',
      'Alertes AS ONE',
      channelDescription: 'Affectations, pointages, incidents',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      _id,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Payload traité au prochain démarrage si nécessaire.
}
