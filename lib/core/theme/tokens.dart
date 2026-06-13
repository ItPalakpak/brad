import 'package:flutter/material.dart';

class AppColorTokens {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color primary;
  final Color accent;
  final Color accentSoft;
  final Color accentRing;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color textInvert;
  final Color border;
  final Color borderStrong;
  final Color inputBg;
  final Color inputBorder;
  final Color inputFocus;
  final Color hover;
  final Color active;
  final Color shadowColor;

  const AppColorTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.accent,
    required this.accentSoft,
    required this.accentRing,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.textInvert,
    required this.border,
    required this.borderStrong,
    required this.inputBg,
    required this.inputBorder,
    required this.inputFocus,
    required this.hover,
    required this.active,
    required this.shadowColor,
  });
}

class AppShadows {
  // Hard offset shadow — blurRadius is ALWAYS 0
  static BoxShadow offsetXs(Color c) =>
      BoxShadow(color: c, offset: const Offset(1, 1), blurRadius: 0);
  static BoxShadow offsetSm(Color c) =>
      BoxShadow(color: c, offset: const Offset(1.5, 1.5), blurRadius: 0);
  static BoxShadow offsetMd(Color c) =>
      BoxShadow(color: c, offset: const Offset(3, 3), blurRadius: 0);
  static BoxShadow offsetLg(Color c) =>
      BoxShadow(color: c, offset: const Offset(5, 5), blurRadius: 0);
  static BoxShadow offsetXl(Color c) =>
      BoxShadow(color: c, offset: const Offset(7.5, 7.5), blurRadius: 0);
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const xs = BorderRadius.zero;
  static const sm = BorderRadius.zero;
  static const md = BorderRadius.zero;
  static const lg = BorderRadius.zero;
  static const full = BorderRadius.zero;
}

// Semantic status colors — same across all themes
class AppStatusColors {
  static const success = Color(0xFF10B981);
  static const successSoft = Color(0x2010B981);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0x20F59E0B);
  static const error = Color(0xFFEF4444);
  static const errorSoft = Color(0x20EF4444);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0x203B82F6);
}
