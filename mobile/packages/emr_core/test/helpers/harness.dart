import 'package:emr_core/emr_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Pumps [child] inside a GetMaterialApp with the real theme, translations and direction.
Future<void> pumpApp(WidgetTester tester, Widget child, {String lang = 'en', Map<String, Map<String, String>> extra = const {}}) async {
  Get.reset();
  Get.testMode = true;
  final locale = Locale(lang);
  await tester.pumpWidget(
    GetMaterialApp(
      translations: AppTranslations(extra: extra),
      locale: locale,
      fallbackLocale: const Locale('ar'),
      supportedLocales: LocaleService.supported,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: appTheme(locale),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}
