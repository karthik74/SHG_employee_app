import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_session.dart';
import 'notification_api.dart';

/// Android channel id MUST match the one declared in AndroidManifest.xml
/// (`com.google.firebase.messaging.default_notification_channel_id`) so that
/// background notifications delivered by the FCM SDK land in the same channel
/// as the foreground ones we display via flutter_local_notifications.
const String _androidChannelId = 'default_channel';
const String _androidChannelName = 'General Notifications';
const String _androidChannelDescription = 'Default channel for app notifications';

/// Top-level background message handler.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[Push:bg] ${message.messageId} data=${message.data}');
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationApi _api = NotificationApi();
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _initialized = false;

  /// Call once on app start (after Firebase.initializeApp). Idempotent.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // On iOS, allow the system to show banners while the app is in foreground.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      debugPrint('[Push] token refreshed');
      if (AuthSession.instance.isLoggedIn) {
        registerWithBackend(fcmToken: token);
      }
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        debugPrint('[Push:tap] payload=${resp.payload}');
      },
    );

    // Pre-create the Android channel so notifications display correctly on
    // Android 8+ (channels are required there).
    final androidPlugin = _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[Push:fg] ${message.messageId} '
        'title=${message.notification?.title} data=${message.data}');

    // On Android, the FCM SDK does not display `notification` payloads while
    // the app is in the foreground — we have to render them ourselves. On
    // iOS, setForegroundNotificationPresentationOptions already does this,
    // but firing a local notification too would double-display, so we skip.
    if (!Platform.isAndroid) return;

    final notification = message.notification;
    if (notification == null) return; // data-only message — handle in app UI

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  /// Fetches the current FCM token and POSTs it to the Fineract backend.
  Future<void> registerWithBackend({String? fcmToken}) async {
    final userId = AuthSession.instance.userId;
    if (userId == null) {
      debugPrint('[Push] skip register — no logged-in user');
      return;
    }

    final token = fcmToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('[Push] skip register — no FCM token');
      return;
    }

    final deviceId = await _deviceId();
    final platform = Platform.isIOS ? 'ios' : 'android';

    debugPrint('[Push] registering appUserId=$userId platform=$platform '
        'deviceId=$deviceId');

    try {
      await _api.registerDevice(
        appUserId: userId,
        platform: platform,
        deviceId: deviceId,
        fcmToken: token,
      );
      debugPrint('[Push] register-device OK');
    } catch (e, st) {
      debugPrint('[Push] register-device failed: $e');
      debugPrint('$st');
    }
  }

  Future<String> _deviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await info.androidInfo;
      return a.id;
    }
    if (Platform.isIOS) {
      final i = await info.iosInfo;
      return i.identifierForVendor ?? 'ios-unknown';
    }
    return 'unknown';
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundSub = null;
    _initialized = false;
  }
}
