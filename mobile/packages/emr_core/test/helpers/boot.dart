import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'fake_adapter.dart';

/// A booted core with fakes for every platform piece.
class TestCore {
  TestCore({required this.http, required this.secure, required this.net});
  final FakeAdapter http;
  final MemorySecureStore secure;
  final FakeConnectivity net;

  SessionService get session => Get.find<SessionService>();
}

const testHome = '/home';

Future<TestCore> bootCore({
  ClientApp app = ClientApp.crew,
  bool Function(Me me)? roleAllowed,
  Map<String, String>? secureSeed,
  bool online = true,
  bool withOutbox = false,
  bool devTools = false,
}) async {
  Get.reset();
  Get.testMode = true;
  final core = TestCore(http: FakeAdapter(), secure: MemorySecureStore(secureSeed), net: FakeConnectivity(online));
  await bootstrapCore(
    config: AppConfig(clientApp: app, version: '1.0.0', apiBaseUrl: 'http://test', devTools: devTools),
    flow: AuthFlowConfig(
      homeRoute: testHome,
      appTitleKey: 'app_title',
      roleAllowed: roleAllowed ?? (me) => me.isCrew,
      devPhones: const {'demo.driver1': '+249999990108'},
    ),
    withOutbox: withOutbox,
    overrides: CoreOverrides(
      secure: core.secure,
      connectivity: core.net,
      adapter: core.http,
      outboxStore: MemoryKeyValueStore(),
      cacheStore: MemoryKeyValueStore(),
    ),
  );
  return core;
}

/// Pumps the real app shell with a trivial home page and lets the splash decide.
Future<void> pumpEmrApp(WidgetTester tester, {List<GetPage<dynamic>> pages = const []}) async {
  await tester.pumpWidget(
    EmrApp(
      title: 'test',
      translations: const {
        'en': {'app_title': 'Test app'},
        'ar': {'app_title': 'تطبيق'},
      },
      pages: [
        GetPage<void>(name: testHome, page: () => const Scaffold(body: Text('HOME'))),
        ...pages,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

const driverMe = {
  'id': 'u1',
  'username': 'demo.driver1',
  'fullNameAr': 'سائق',
  'fullNameEn': 'Driver',
  'role': 'DRIVER',
  'preferredLanguage': 'en',
  'scopes': <Object>[],
  'stateCodes': ['KH'],
  'mustChangePassword': false,
};
