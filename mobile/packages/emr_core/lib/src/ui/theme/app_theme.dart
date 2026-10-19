import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled in `emr_core` (referenced from the apps with the package prefix).
abstract final class AppFonts {
  static const latin = 'packages/emr_core/IBMPlexSans';
  static const arabic = 'packages/emr_core/IBMPlexSansArabic';

  static String forLocale(Locale l) => l.languageCode == 'ar' ? arabic : latin;

  /// The other script falls back to the other Plex family, never to Roboto/SF.
  static List<String> fallbackFor(Locale l) => [l.languageCode == 'ar' ? latin : arabic];
}

/// Theme built from the tokens. Rebuild it when the language changes (the family differs).
ThemeData appTheme(Locale locale) {
  final family = AppFonts.forLocale(locale);
  final fallback = AppFonts.fallbackFor(locale);
  const radius = BorderRadius.all(Radius.circular(Space.controlRadius));
  const outline = OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.lineStrong));

  final text = TextTheme(
    displaySmall: const TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w600),
    headlineSmall: const TextStyle(fontSize: 26, height: 1.25, fontWeight: FontWeight.w600),
    titleMedium: const TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w600),
    bodyLarge: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
    bodyMedium: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w400),
    labelLarge: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
    labelMedium: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
    bodySmall: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.inkMuted),
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink, fontFamily: family, fontFamilyFallback: fallback);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: family,
    fontFamilyFallback: fallback,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      secondary: AppColors.brand,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.line,
    ),
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      // Page title: 26 / 1.25 / 600 (docs/mobile-app.md › Type).
      titleTextStyle: text.headlineSmall,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Space.cardRadius)),
        side: BorderSide(color: AppColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.onBrand,
        disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.6),
        disabledForegroundColor: AppColors.onBrand,
        minimumSize: const Size(Space.minTarget, Space.minTarget),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: family),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ).copyWith(overlayColor: const WidgetStatePropertyAll(AppColors.brandActive)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(Space.minTarget, Space.minTarget),
        side: const BorderSide(color: AppColors.lineSoft),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: family),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ).copyWith(overlayColor: const WidgetStatePropertyAll(AppColors.surfaceStrong)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        minimumSize: const Size(Space.minTarget, Space.minTarget),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: family),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ).copyWith(overlayColor: const WidgetStatePropertyAll(AppColors.brandSoft)),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(Space.minTarget, Space.minTarget),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: outline,
      enabledBorder: outline,
      focusedBorder: outline.copyWith(borderSide: const BorderSide(color: AppColors.brand, width: 2)),
      errorBorder: outline.copyWith(borderSide: const BorderSide(color: AppColors.danger)),
      focusedErrorBorder: outline.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 2)),
      hintStyle: const TextStyle(color: AppColors.inkSubtle, fontSize: 14),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500),
      errorMaxLines: 3,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: AppColors.onBrand, fontSize: 14, fontFamily: family),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Space.cardRadius))),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBarrierColor: AppColors.scrim,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Space.cardRadius))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: AppColors.brandSoft,
      indicatorShape: const StadiumBorder(),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 22, color: s.contains(WidgetState.selected) ? AppColors.brand : AppColors.inkMuted),
      ),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: family)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.brand, linearTrackColor: AppColors.surfaceStrong),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface,
        selectedBackgroundColor: AppColors.brandSoft,
        selectedForegroundColor: AppColors.brandActive,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineSoft),
        minimumSize: const Size(Space.minTarget, Space.minTarget),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: family),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.brandSoft,
      side: const BorderSide(color: AppColors.lineSoft),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink, fontFamily: family),
      checkmarkColor: AppColors.brandActive,
      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.inkMuted, minVerticalPadding: Space.md),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
  );
}
