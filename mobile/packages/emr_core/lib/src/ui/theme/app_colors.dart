import 'package:flutter/material.dart';

/// Tokens copied from the staff web portal (`docs/mobile-app.md` › Colour). Light mode only.
abstract final class AppColors {
  static const brand = Color(0xFF0D6873);
  static const brandHover = Color(0xFF0A5760);
  static const brandActive = Color(0xFF08454C);
  static const onBrand = Color(0xFFFFFFFF);
  static const brandSoft = Color(0xFFEAF5F6);
  static const brandSoftPressed = Color(0xFFD5EBED);

  static const canvas = Color(0xFFF5F7F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceStrong = Color(0xFFEBEFF0);

  static const line = Color(0xFFE0E6E8);
  static const lineSoft = Color(0xFFD2DADD);
  static const lineStrong = Color(0xFF7E8D94);

  static const ink = Color(0xFF131A1E);
  static const inkMuted = Color(0xFF4B5960);
  static const inkSubtle = Color(0xFF66757D);

  static const danger = Color(0xFFA01F17);
  static const dangerSurface = Color(0xFFFDEDEC);
  static const warning = Color(0xFF875907);
  static const warningSurface = Color(0xFFFDF5E6);
  static const transit = Color(0xFF2457BD);
  static const transitSurface = Color(0xFFECF2FD);
  static const scene = Color(0xFF5E3DB8);
  static const sceneSurface = Color(0xFFF2EEFC);
  static const done = Color(0xFF232E34);
  static const doneSurface = Color(0xFFE0E6E8);

  /// Dialog scrim: ink at 40 %.
  static const scrim = Color(0x66131A1E);

  static const skeleton = line;
}

/// P1–P4: a filled pill with code + words; colour is never the only signal.
enum Priority {
  p1('P1', Color(0xFFC0281E), Colors.white),
  p2('P2', Color(0xFFC2510A), Colors.white),
  p3('P3', Color(0xFFF5C518), Color(0xFF0C1114)),
  p4('P4', Color(0xFF257538), Colors.white);

  const Priority(this.code, this.fill, this.text);
  final String code;
  final Color fill;
  final Color text;

  static Priority? fromCode(String? c) {
    for (final p in values) {
      if (p.code == c) return p;
    }
    return null;
  }

  /// Translation key for the words ("Life in danger" …).
  String get labelKey => 'priority_${code.toLowerCase()}';
}

/// Status chip tones from the design spec.
enum Tone {
  neutral(AppColors.surfaceStrong, AppColors.inkMuted),
  info(AppColors.brandSoft, AppColors.brandActive),
  warning(AppColors.warningSurface, AppColors.warning),
  danger(AppColors.dangerSurface, AppColors.danger),
  transit(AppColors.transitSurface, AppColors.transit),
  scene(AppColors.sceneSurface, AppColors.scene),
  done(AppColors.doneSurface, AppColors.done);

  const Tone(this.fill, this.text);
  final Color fill;
  final Color text;
}

/// Spacing unit 4; build from 4, 8, 12, 16, 20, 24.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;

  static const screen = 16.0;
  static const cardPadding = 20.0;
  static const inCard = 16.0;
  static const betweenCards = 24.0;
  static const controlRadius = 8.0;
  static const cardRadius = 12.0;
  static const minTarget = 48.0;
}

abstract final class Motion {
  static const colour = Duration(milliseconds: 200);
  static const highlight = Duration(milliseconds: 150);
}

const cardShadow = [
  BoxShadow(color: Color(0x0A131A1E), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x2E131A1E), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -12),
];
