// Read-only smoke test against a real backend. Skipped unless LIVE_API is given:
//   flutter test test/live --dart-define=LIVE_API=https://<host>
// It never creates SOS requests or changes job state, so it is safe on the shared demo backend.
@Tags(['live'])
library;

import 'package:dio/dio.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

const base = String.fromEnvironment('LIVE_API');

class Signed {
  Signed(this.api, this.session);
  final ApiClient api;
  final SessionService session;
}

Future<Signed> signIn(ClientApp app, String username, String phone) async {
  late final ApiClient api;
  final secure = MemorySecureStore();
  final session = SessionService(secure: secure, authApi: () => api.auth);
  final config = AppConfig(clientApp: app, version: '1.0.0', apiBaseUrl: base, devTools: true);
  api = ApiClient(config: config, tokens: session);
  final repo = AuthRepository(api: api, device: DeviceService(secure), config: config);

  final r = await repo.login(username, 'Demo-Pass-2026');
  if (r.tokens != null) {
    await session.start(r.tokens!);
  } else {
    expect(r.step, 'sms_code');
    final code = await repo.devLatestCode(phone);
    expect(code, matches(RegExp(r'^\d{6}$')));
    await session.start(await repo.verify(r.challengeId!, code!));
  }
  return Signed(api, session);
}

void main() {
  final skip = base.isEmpty ? 'pass --dart-define=LIVE_API=<url> to run' : null;

  test('crew: login + SMS, /me, job read, refresh, logout', () async {
    final s = await signIn(ClientApp.crew, 'demo.driver1', '+249999990108');
    final me = await s.session.loadMe();
    expect(me.isDriver, isTrue);

    final job = await s.api.crew.job();
    if (job.hasJob) {
      expect(job.jobStatus, isNotNull, reason: 'status ${job.status} must be a known JobStatus');
      expect(job.pinRadiusM, isNotNull);
    }

    expect(await s.session.refreshAccessToken(), isA<Refreshed>());
    expect((await s.api.auth.me()).username, 'demo.driver1', reason: 'the refreshed token works');
    await s.session.signOut();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('crew: a bad QR is 404 with the bilingual error body', () async {
    final s = await signIn(ClientApp.crew, 'demo.driver2', '+249999990110');
    try {
      await s.api.crew.startShift(const QrBody('definitely-not-a-qr'));
      fail('expected an error');
    } on DioException catch (e) {
      final err = ApiError.of(e);
      expect(err.status, anyOf(404, 409));
      expect(err.ar, isNotEmpty);
      expect(err.en, isNotEmpty);
    }
    await s.session.signOut();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('citizen: profile, requests page, request detail, history gate', () async {
    final s = await signIn(ClientApp.citizen, 'demo.citizen', '+249912345003');
    expect((await s.session.loadMe()).isCitizen, isTrue);

    final p = await s.api.citizen.me();
    expect(p.phone, startsWith('+249'));

    final page = await s.api.citizen.requests(0, 5);
    for (final r in page.content) {
      expect(r.code, isNot(RequestStatusCode.unknown), reason: 'status ${r.statusCode} must be known');
    }
    if (page.content.isNotEmpty) {
      final d = await s.api.citizen.request(page.content.first.id);
      expect(d.status('ar'), isNotEmpty);
    }

    try {
      await s.api.citizen.history(0, 5);
    } on DioException catch (e) {
      expect(ApiError.of(e).code, 'CITIZEN_HISTORY_NOT_VERIFIED');
    }
    await s.session.signOut();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('a crew account is refused by the citizen app', () async {
    final config = AppConfig(clientApp: ClientApp.citizen, version: '1.0.0', apiBaseUrl: base);
    final secure = MemorySecureStore();
    late final ApiClient api;
    final session = SessionService(secure: secure, authApi: () => api.auth);
    api = ApiClient(config: config, tokens: session);
    try {
      await AuthRepository(api: api, device: DeviceService(secure), config: config).login('demo.driver3', 'Demo-Pass-2026');
      fail('expected WRONG_CLIENT_APP');
    } on DioException catch (e) {
      expect(ApiError.of(e).code, 'WRONG_CLIENT_APP');
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}
