import 'dart:async';

import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_adapter.dart';

class FakePush implements PushProvider {
  String? current = 'tok-1';
  final refreshes = StreamController<String>.broadcast();
  final msgs = StreamController<Map<String, Object?>>.broadcast();

  @override
  Future<String?> token() async => current;
  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
  @override
  Stream<Map<String, Object?>> get messages => msgs.stream;
}

void main() {
  late FakeAdapter http;
  late FakePush provider;
  late PushService push;

  setUp(() {
    http = FakeAdapter();
    final session = SessionService(secure: MemorySecureStore(), authApi: () => throw UnimplementedError());
    final api = ApiClient(config: const AppConfig(clientApp: ClientApp.crew, version: '1', apiBaseUrl: 'http://t'), tokens: session, adapter: http);
    final repo = AuthRepository(api: api, device: DeviceService(MemorySecureStore()), config: const AppConfig(clientApp: ClientApp.crew, version: '1'));
    provider = FakePush();
    push = PushService(provider: provider, repo: repo)..onInit();
  });

  test('registers the token once, and again only when it changes', () async {
    http.reply('PUT /api/v1/devices/current/push-token', 200, {'registered': true});
    await push.registerCurrent();
    await push.registerCurrent();
    provider.refreshes.add('tok-2');
    await pumpEventQueue();
    expect(http.bodies, [
      {'pushToken': 'tok-1'},
      {'pushToken': 'tok-2'},
    ]);
  });

  test('a failed registration is retried next time', () async {
    http
      ..offline('PUT /api/v1/devices/current/push-token')
      ..reply('PUT /api/v1/devices/current/push-token', 200, {'registered': true});
    await push.registerCurrent();
    expect(push.registered, isNull);
    await push.registerCurrent();
    expect(push.registered, 'tok-1');
  });

  test('no provider token means no call', () async {
    provider.current = null;
    await push.registerCurrent();
    expect(http.requests, isEmpty);
  });

  test('messages become refetch hints; junk is ignored', () async {
    final hints = <PushHint>[];
    push.hints.listen(hints.add);
    provider.msgs
      ..add({'type': 'job.new', 'dispatchId': 'd-1'})
      ..add({'type': 'request.status', 'id': 'r-1'})
      ..add({'nope': true});
    await pumpEventQueue();
    expect(hints.map((h) => '${h.type}:${h.id}'), ['job.new:d-1', 'request.status:r-1']);
  });
}
