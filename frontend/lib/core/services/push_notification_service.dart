import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'local_notification_service.dart';
import '../network/api_client.dart';
import '../utils/notification_navigation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _ready = false;
  String? _currentToken;
  bool _tapHandlersBound = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final n = message.notification;
        final data = message.data;
        final type = data['type']?.toString() ?? '';
        final payload = NotificationNavigation.encodePayload(
          type: type,
          data: Map<String, dynamic>.from(data),
        );
        if (n != null) {
          LocalNotificationService.instance.show(
            title: n.title ?? 'AS ONE',
            body: n.body ?? '',
            payload: payload,
          );
        }
      });

      _bindTapHandlers(messaging);

      _currentToken = await messaging.getToken();
      messaging.onTokenRefresh.listen((t) {
        _currentToken = t;
      });

      _ready = true;
      debugPrint('FCM ready token=${_currentToken?.substring(0, 12)}…');
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  void _bindTapHandlers(FirebaseMessaging messaging) {
    if (_tapHandlersBound) return;
    _tapHandlersBound = true;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message);
    });

    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _navigateFromMessage(message);
        });
      }
    });
  }

  void _navigateFromMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    final type = data['type']?.toString() ?? '';
    NotificationNavigation.handleData(type: type, data: data);
  }

  Future<void> registerWithBackend(ApiClient api) async {
    try {
      if (!_ready) await init();
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _currentToken = token;
      await api.dio.post(
        '/notifications/device-token',
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      debugPrint('FCM token registered with API');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }

  Future<void> unregisterFromBackend(ApiClient api) async {
    final token = _currentToken;
    if (token == null) return;
    try {
      await api.dio.delete(
        '/notifications/device-token',
        data: {'token': token},
      );
    } catch (_) {}
  }
}
