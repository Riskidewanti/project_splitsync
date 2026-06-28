import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  debugPrint('FCM background message: ${message.messageId}');
  debugPrint('FCM background data: ${message.data}');
}

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _printCurrentToken();
    _listenForTokenRefresh();
    _listenForForegroundMessages();
    _listenForOpenedMessages();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');
  }

  Future<void> _printCurrentToken() async {
    final token = await _messaging.getToken();
    debugPrint('FCM token: $token');
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed: $token');
    });
  }

  void _listenForForegroundMessages() {
    _onMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      (message) async {
        debugPrint('FCM foreground message: ${message.messageId}');
        debugPrint('FCM foreground data: ${message.data}');

        final notification = message.notification;
        final title = notification?.title;
        final body = notification?.body;

        if (title == null && body == null) return;

        await LocalNotificationService.instance.show(
          title: title ?? 'SplitSync',
          body: body ?? '',
        );
      },
    );
  }

  void _listenForOpenedMessages() {
    _onMessageOpenedAppSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM opened message: ${message.messageId}');
      debugPrint('FCM opened data: ${message.data}');
    });
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _onMessageSubscription?.cancel();
    await _onMessageOpenedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _onMessageSubscription = null;
    _onMessageOpenedAppSubscription = null;
  }
}
