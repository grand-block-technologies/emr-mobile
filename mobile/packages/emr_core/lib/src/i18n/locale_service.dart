import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../storage/secure_store.dart';
import '../ui/theme/app_theme.dart';

/// Current UI language. Arabic is the default; `GET /me` `preferredLanguage` wins after login.
class LocaleService extends GetxService {
  LocaleService(this._store);

  static const _key = 'ui_lang';
  static const supported = [Locale('ar'), Locale('en')];
  static const fallback = Locale('ar');

  final SecureStore _store;
  final locale = fallback.obs;

  String get lang => locale.value.languageCode;

  /// Reads the saved choice. Call before `runApp` so the first frame has the right direction.
  Future<LocaleService> init() async {
    final saved = await _store.read(_key);
    locale.value = _supported(saved) ?? fallback;
    return this;
  }

  Future<void> set(String? languageCode) async {
    final l = _supported(languageCode);
    if (l == null || l == locale.value) return;
    // Update GetX first so listeners of [locale] already translate in the new language.
    await Get.updateLocale(l);
    Get.changeTheme(appTheme(l));
    locale.value = l;
    await _store.write(_key, l.languageCode);
  }

  static Locale? _supported(String? code) =>
      supported.firstWhereOrNull((l) => l.languageCode == code);
}

/// Language code for picking `message_ar` / `message_en` and other server pairs.
String currentLang() => Get.locale?.languageCode == 'en' ? 'en' : 'ar';
