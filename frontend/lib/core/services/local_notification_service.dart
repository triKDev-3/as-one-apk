import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notifications système locales (bandeau + son) quand l'app reçoit un événement.
/// Pour le push app fermée : configurer Firebase FCM (voir docs).
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
    );

    // Android 13+
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
