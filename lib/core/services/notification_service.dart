import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Must be a top-level function — runs in a separate isolate when app is killed/backgrounded.
// Stream sends data-only FCM messages (no notification field), so we must display
// the notification manually here.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  final type = message.data['type'] as String?;
  if (type != 'message.new') return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'animatch_default',
        'Animatch',
        description: 'Matches e mensagens',
        importance: Importance.high,
      ));
  await plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
  );
  await plugin.show(
    message.hashCode,
    'Nova mensagem',
    'Você recebeu uma nova mensagem',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'animatch_default',
        'Animatch',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: message.data['cid'] as String?,
  );
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Emits the route payload whenever a foreground local notification is tapped.
  // Listeners (e.g. the router) use this to navigate.
  final _tapController = StreamController<String?>.broadcast();
  Stream<String?> get onLocalTap => _tapController.stream;

  // Android notification channel for foreground notifications.
  // Must match the channel used in the backend FCM payload.
  static const _channel = AndroidNotificationChannel(
    'animatch_default',
    'Animatch',
    description: 'Matches e mensagens',
    importance: Importance.high,
  );

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) {
        _tapController.add(details.payload);
      },
    );

    // Show alert + badge + sound when app is in foreground on iOS.
    // On Android this is handled by the local notification below.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  Future<NotificationSettings> requestPermission() =>
      _fcm.requestPermission(alert: true, badge: true, sound: true);

  Future<String?> getToken() => _fcm.getToken();

  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  void dispose() => _tapController.close();

  void _showForeground(RemoteMessage message) {
    final type = message.data['type'] as String?;

    // Stream sends data-only messages — synthesise title/body from the type.
    final title = message.notification?.title ??
        (type == 'message.new' ? 'Nova mensagem' : null);
    final body = message.notification?.body ??
        (type == 'message.new' ? 'Você recebeu uma nova mensagem' : null);

    if (title == null) return;

    _local.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['cid'] as String? ?? message.data['route'] as String?,
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});
