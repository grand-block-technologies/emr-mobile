import 'dart:io';

import 'package:emr_core/emr_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  group('DeviceService', () {
    test('creates one id per install and reuses it', () async {
      final secure = MemorySecureStore();
      final first = await DeviceService(secure).id();
      expect(first, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(await DeviceService(secure).id(), first, reason: 'a new service instance reads the stored id');
    });
  });

  group('HiveKeyValueStore', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('emr_hive_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('round-trips JSON, sorts keys and clears', () async {
      final secure = MemorySecureStore();
      final s = await HiveKeyValueStore.open('t1', secure);
      await s.put('b', {'x': 1});
      await s.put('a', [1, 2]);
      expect(await s.get('b'), {'x': 1});
      expect(await s.keys(), ['a', 'b']);
      await s.clear();
      expect(await s.keys(), isEmpty);
    });

    test('is encrypted at rest: plain text never reaches the file', () async {
      final secure = MemorySecureStore();
      final s = await HiveKeyValueStore.open('t2', secure);
      await s.put('patient', {'fullNameAr': 'PLAINTEXT-MARKER'});
      await Hive.close();

      final bytes = await File('${dir.path}/t2.hive').readAsBytes();
      expect(String.fromCharCodes(bytes).contains('PLAINTEXT-MARKER'), isFalse);
      expect(secure.values[SecureKeys.cacheKey], isNotNull);
    });

    test('reopening with the same secure store reads the data back', () async {
      final secure = MemorySecureStore();
      await (await HiveKeyValueStore.open('t3', secure)).put('k', 'v');
      await Hive.close();
      Hive.init(dir.path);
      expect(await (await HiveKeyValueStore.open('t3', secure)).get('k'), 'v');
    });
  });

  group('ConnectivityService', () {
    test('reports going back online once per transition', () async {
      final src = FakeConnectivity(false);
      final svc = await ConnectivityService(src).init();
      var back = 0;
      svc.backOnline.listen((_) => back++);

      src.set(true);
      src.set(true);
      src.set(false);
      src.set(true);
      await pumpEventQueue();

      expect(back, 2);
      expect(svc.online.value, isTrue);
    });
  });

  group('jwtExpiry', () {
    test('reads exp and ignores garbage', () {
      // {"alg":"none"}.{"exp":1760515200}
      const t = 'eyJhbGciOiJub25lIn0.eyJleHAiOjE3NjA1MTUyMDB9.x';
      expect(jwtExpiry(t), DateTime.fromMillisecondsSinceEpoch(1760515200 * 1000, isUtc: true));
      expect(jwtExpiry('not.a.jwt'), isNull);
      expect(jwtExpiry('nope'), isNull);
    });
  });
}
