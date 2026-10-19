import 'package:dio/dio.dart';
import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

class FakeTokens implements AuthTokenSource {
  @override
  Future<RefreshOutcome>? get pendingRefresh => null;
  FakeTokens(this.accessToken);

  @override
  String? accessToken;
  RefreshOutcome nextOutcome = const Refreshed('fresh');
  int refreshCalls = 0;
  final sessionErrors = <ApiError>[];

  @override
  Future<RefreshOutcome> refreshAccessToken() async {
    refreshCalls++;
    final o = nextOutcome;
    if (o is Refreshed) accessToken = o.accessToken;
    return o;
  }

  @override
  void onSessionError(ApiError error) => sessionErrors.add(error);
}

void main() {
  late FakeAdapter http;
  late FakeTokens tokens;
  late ApiClient api;

  setUp(() {
    http = FakeAdapter();
    tokens = FakeTokens('old');
    api = ApiClient(
      config: const AppConfig(clientApp: ClientApp.crew, version: '1.0.0', apiBaseUrl: 'http://test'),
      tokens: tokens,
      adapter: http,
    );
  });

  test('adds the bearer token to private calls', () async {
    http.reply('GET /api/v1/me', 200, {'id': 'u1', 'username': 'demo'});
    await api.auth.me();
    expect(http.requests.single.headers['Authorization'], 'Bearer old');
  });

  test('never sends a token on public calls', () async {
    http.reply('POST /api/v1/auth/login', 200, {'step': 'sms_code', 'challengeId': 'c1'});
    await api.auth.login(const LoginBody(username: 'u', password: 'p', clientApp: 'crew_app', deviceId: 'd', appVersion: '1'));
    expect(http.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('on 401 UNAUTHORIZED refreshes once and replays with the new token', () async {
    http.reply('GET /api/v1/me', 401, errorBody('UNAUTHORIZED'));
    http.reply('GET /api/v1/me', 200, {'id': 'u1', 'username': 'demo'});

    final me = await api.auth.me();

    expect(me.id, 'u1');
    expect(tokens.refreshCalls, 1);
    final calls = http.calls('GET /api/v1/me');
    expect(calls, hasLength(2));
    expect(calls.last.headers['Authorization'], 'Bearer fresh');
    expect(tokens.sessionErrors, isEmpty);
  });

  test('a replay that fails 401 again is not retried a second time', () async {
    http.reply('GET /api/v1/me', 401, errorBody('UNAUTHORIZED'));

    await expectLater(api.auth.me(), throwsA(isA<DioException>()));
    expect(tokens.refreshCalls, 1);
    expect(http.calls('GET /api/v1/me'), hasLength(2));
  });

  test('a rejected refresh ends the session with the server error', () async {
    tokens.nextOutcome = const RefreshRejected(ApiError(status: 401, code: 'SESSION_INVALID', ar: 'a', en: 'b'));
    http.reply('GET /api/v1/me', 401, errorBody('UNAUTHORIZED'));

    await expectLater(api.auth.me(), throwsA(isA<DioException>()));
    expect(tokens.sessionErrors.single.code, 'SESSION_INVALID');
  });

  test('an unreachable refresh keeps the session (crew may be offline)', () async {
    tokens.nextOutcome = const RefreshUnreachable();
    http.reply('GET /api/v1/me', 401, errorBody('UNAUTHORIZED'));

    await expectLater(api.auth.me(), throwsA(isA<DioException>()));
    expect(tokens.sessionErrors, isEmpty);
    expect(tokens.accessToken, 'old');
  });

  test('DEVICE_BLOCKED ends the session at once without trying to refresh', () async {
    http.reply('GET /api/v1/crew/job', 401, errorBody('DEVICE_BLOCKED'));

    final err = await api.crew.job().then<Object?>((_) => null, onError: (Object e) => e);

    expect(ApiError.of(err!).code, 'DEVICE_BLOCKED');
    expect(tokens.refreshCalls, 0);
    expect(tokens.sessionErrors.single.code, 'DEVICE_BLOCKED');
  });

  test('APP_UPDATE_REQUIRED on the public login still reaches the session', () async {
    http.reply('POST /api/v1/auth/login', 426, errorBody('APP_UPDATE_REQUIRED'));

    await expectLater(
      api.auth.login(const LoginBody(username: 'u', password: 'p', clientApp: 'crew_app', deviceId: 'd', appVersion: '0.1')),
      throwsA(isA<DioException>()),
    );
    expect(tokens.sessionErrors.single.code, 'APP_UPDATE_REQUIRED');
  });

  test('a wrong password on the public login neither refreshes nor ends a session', () async {
    http.reply('POST /api/v1/auth/login', 401, errorBody('INVALID_CREDENTIALS'));

    await expectLater(
      api.auth.login(const LoginBody(username: 'u', password: 'p', clientApp: 'crew_app', deviceId: 'd', appVersion: '1')),
      throwsA(isA<DioException>()),
    );
    expect(tokens.refreshCalls, 0);
    expect(tokens.sessionErrors, isEmpty);
  });

  test('PASSWORD_CHANGE_REQUIRED is reported to the session', () async {
    http.reply('GET /api/v1/crew/job', 403, errorBody('PASSWORD_CHANGE_REQUIRED'));
    await expectLater(api.crew.job(), throwsA(isA<DioException>()));
    expect(tokens.sessionErrors.single.code, 'PASSWORD_CHANGE_REQUIRED');
  });
}
