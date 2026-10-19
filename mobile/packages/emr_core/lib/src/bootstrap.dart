import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'api/api_client.dart';
import 'auth/auth_flow.dart';
import 'auth/auth_pages.dart';
import 'auth/auth_repository.dart';
import 'config/app_config.dart';
import 'i18n/locale_service.dart';
import 'i18n/translations.dart';
import 'services/connectivity_service.dart';
import 'services/device_service.dart';
import 'services/outbox/outbox_service.dart';
import 'services/push_service.dart';
import 'services/session_service.dart';
import 'storage/kv_store.dart';
import 'storage/secure_store.dart';
import 'ui/theme/app_theme.dart';

/// Swap platform pieces for fakes in tests (and in widget previews).
class CoreOverrides {
  const CoreOverrides({this.secure, this.connectivity, this.adapter, this.outboxStore, this.cacheStore, this.push});
  final SecureStore? secure;
  final ConnectivitySource? connectivity;
  final HttpClientAdapter? adapter;
  final KeyValueStore? outboxStore;
  final KeyValueStore? cacheStore;
  final PushProvider? push;
}

/// Tag for the general encrypted cache (job, shift, profile …).
const kCacheTag = 'cache';

/// Registers every session-long service. Call once before `runApp`.
Future<void> bootstrapCore({
  required AppConfig config,
  required AuthFlowConfig flow,
  bool withOutbox = false,
  CoreOverrides overrides = const CoreOverrides(),
}) async {
  final secure = overrides.secure ?? FlutterSecureStore();
  if (overrides.outboxStore == null || overrides.cacheStore == null) {
    Hive.init((await getApplicationSupportDirectory()).path);
  }

  Get.put<AppConfig>(config, permanent: true);
  Get.put<SecureStore>(secure, permanent: true);
  final locale = Get.put(await LocaleService(secure).init(), permanent: true);
  final net = Get.put(await ConnectivityService(overrides.connectivity ?? PlatformConnectivity()).init(), permanent: true);
  final device = Get.put(DeviceService(secure), permanent: true);

  late final ApiClient api;
  final session = Get.put(SessionService(secure: secure, authApi: () => api.auth), permanent: true);
  api = Get.put(ApiClient(config: config, tokens: session, adapter: overrides.adapter), permanent: true);
  final repo = Get.put(AuthRepository(api: api, device: device, config: config), permanent: true);
  final push = Get.put(PushService(provider: overrides.push ?? const NoPushProvider(), repo: repo), permanent: true);
  session.onWipe(() async => push.forget());

  final cache = overrides.cacheStore ?? await HiveKeyValueStore.open('cache', secure);
  Get.put<KeyValueStore>(cache, tag: kCacheTag, permanent: true);
  session.onWipe(cache.clear);

  if (withOutbox) {
    final outbox = Get.put(
      OutboxService(store: overrides.outboxStore ?? await HiveKeyValueStore.open('outbox', secure), dio: () => api.dio),
      permanent: true,
    );
    await outbox.load();
    session.onWipe(outbox.clear);
    net.backOnline.listen((_) => outbox.nudge());
    // On resume, retry at once rather than waiting out the backoff.
    AppLifecycleListener(onResume: outbox.nudge);
  }

  Get.put(AuthFlow(config: flow, session: session, locale: locale), permanent: true).onSignedIn((_) => push.registerCurrent());
}

/// Root widget shared by both apps.
class EmrApp extends StatelessWidget {
  const EmrApp({required this.title, required this.pages, super.key, this.translations = const {}});

  final String title;
  final List<GetPage<dynamic>> pages;
  final Map<String, Map<String, String>> translations;

  @override
  Widget build(BuildContext context) {
    final locale = Get.find<LocaleService>().locale.value;
    return GetMaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(extra: translations),
      locale: locale,
      fallbackLocale: LocaleService.fallback,
      supportedLocales: LocaleService.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(locale),
      themeMode: ThemeMode.light,
      initialRoute: AuthRoutes.splash,
      getPages: [...authPages(), ...pages],
      defaultTransition: Transition.native,
    );
  }
}
