import 'api_client.dart';

class NotificationApi {
  final ApiClient _client;
  NotificationApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Registers an FCM device token with the Fineract backend so the
  /// authenticated user can receive push notifications.
  ///
  /// POST /notifications/register-device
  /// Body: { appUserId, platform, deviceId, fcmToken }
  Future<void> registerDevice({
    required int appUserId,
    required String platform,
    required String deviceId,
    required String fcmToken,
  }) async {
    await _client.post(
      '/notifications/register-device',
      body: {
        'appUserId': appUserId,
        'platform': platform,
        'deviceId': deviceId,
        'fcmToken': fcmToken,
      },
    );
  }
}
