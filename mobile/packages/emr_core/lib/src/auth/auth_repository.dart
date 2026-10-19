import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/apis.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../services/device_service.dart';

/// Auth calls with the device/app fields filled in. Controllers depend on this, not on Retrofit.
class AuthRepository {
  AuthRepository({required ApiClient api, required DeviceService device, required AppConfig config})
      : _api = api,
        _device = device,
        _config = config;

  final ApiClient _api;
  final DeviceService _device;
  final AppConfig _config;

  Future<LoginResult> login(String username, String password) async => _api.auth.login(
        LoginBody(
          username: username.trim(),
          password: password,
          clientApp: _config.clientApp.wire,
          deviceId: await _device.id(),
          appVersion: _config.version,
        ),
      );

  Future<LoginTokens> verify(String challengeId, String code) =>
      _api.auth.verify(VerifyBody(challengeId: challengeId, code: code.trim()));

  Future<Challenge> resend(String challengeId) => _api.auth.resend({'challengeId': challengeId});

  Future<void> changePassword(String oldPassword, String newPassword) =>
      _api.auth.changePassword(ChangePasswordBody(oldPassword: oldPassword, newPassword: newPassword));

  Future<ResetRequested> forgot(String username) =>
      _api.auth.forgot(ForgotBody(username: username.trim(), clientApp: _config.clientApp.wire));

  Future<void> reset(String challengeId, String code, String newPassword) =>
      _api.auth.reset(ResetBody(challengeId: challengeId, code: code.trim(), newPassword: newPassword));

  Future<void> registerPushToken(String token) => _api.auth.pushToken(PushTokenBody(token));

  /// Development only: the last SMS code sent to [phone] (`GET /dev/sms/latest`).
  Future<String?> devLatestCode(String phone) async {
    if (!_config.devTools) return null;
    final res = await _api.dio.get<Map<String, dynamic>>(
      '/dev/sms/latest',
      queryParameters: {'phone': phone},
      options: Options(extra: {kPublicExtra: true}),
    );
    return res.data?['code'] as String?;
  }
}
