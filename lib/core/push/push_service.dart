import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../data/remote/api_client.dart';
import '../../features/session/session_controller.dart';
import '../../firebase_options.dart';
import '../utils/app_log.dart';

const _channelId = 'rpd_push';
const _channelName = 'RPD';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

class PushService extends GetxService {
  final token = RxnString();
  final _local = FlutterLocalNotificationsPlugin();

  Future<PushService> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true, sound: false);
      await _initLocal();
      token.value = await messaging.getToken();
      AppLog.info('FCM token ${token.value ?? 'missing'}', tag: 'PUSH');
      messaging.onTokenRefresh.listen((value) {
        token.value = value;
        AppLog.info('FCM token refresh $value', tag: 'PUSH');
        syncToken();
      });
      FirebaseMessaging.onMessage.listen(_onForeground);
    } catch (e, stack) {
      AppLog.error('push init failed', error: e, stack: stack, tag: 'PUSH');
    }
    return this;
  }

  Future<void> _initLocal() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_notify'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'RPD notifications',
            importance: Importance.high,
          ),
        );
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final title = (message.notification?.title ?? message.data['title'] ?? 'RPD').toString();
    final body = (message.notification?.body ?? message.data['body'] ?? '').toString();
    if (title.isEmpty && body.isEmpty) return;
    try {
      final id = (message.messageId ?? message.hashCode.toString()).hashCode & 0x7fffffff;
      await _local.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'RPD notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e, stack) {
      AppLog.error('foreground notification failed', error: e, stack: stack, tag: 'PUSH');
    }
    if (Get.isRegistered<SessionController>()) {
      unawaited(Get.find<SessionController>().refreshUnreadNotifications());
    }
  }

  Future<void> rotateToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.deleteToken();
      token.value = await messaging.getToken();
      AppLog.info('FCM token rotated ${token.value ?? 'missing'}', tag: 'PUSH');
    } catch (e, stack) {
      AppLog.error('fcm rotate failed', error: e, stack: stack, tag: 'PUSH');
    }
  }

  Future<void> syncToken() async {
    final value = token.value?.trim();
    if (value == null || value.isEmpty) return;
    if (!Get.isRegistered<SessionController>() || !Get.find<SessionController>().hasSession) return;
    try {
      AppLog.info('FCM token sync $value', tag: 'PUSH');
      await Get.find<ApiClient>().patch('/members/me', data: {'fcmToken': value});
    } catch (e, stack) {
      AppLog.error('fcm token sync failed', error: e, stack: stack, tag: 'PUSH');
    }
  }
}
