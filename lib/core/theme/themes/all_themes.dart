import 'package:flutter/material.dart';
import '../tokens.dart';

class AppThemes {
  // 1. PURE BOLD (Clean, high-contrast, professional - Default: Light)
  static const pureBoldLight = AppColorTokens(
    bg: Color(0xFFF4F6F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE2E8F0),
    primary: Color(0xFF0F172A),
    accent: Color(0xFF2563EB),
    accentSoft: Color(0x152563EB),
    accentRing: Color(0x302563EB),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF334155),
    textSubtle: Color(0xFF64748B),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF0F172A),
    borderStrong: Color(0xFF000000),
    inputBg: Color(0xFFF8FAFC),
    inputBorder: Color(0xFFCBD5E1),
    inputFocus: Color(0xFF2563EB),
    hover: Color(0x0A0F172A),
    active: Color(0x142563EB),
    shadowColor: Color(0xFF0F172A),
  );

  static const pureBoldDark = AppColorTokens(
    bg: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceAlt: Color(0xFF334155),
    primary: Color(0xFFF8FAFC),
    accent: Color(0xFF3B82F6),
    accentSoft: Color(0x203B82F6),
    accentRing: Color(0x403B82F6),
    text: Color(0xFFF8FAFC),
    textMuted: Color(0xFFE2E8F0),
    textSubtle: Color(0xFF94A3B8),
    textInvert: Color(0xFF0F172A),
    border: Color(0xFF334155),
    borderStrong: Color(0xFFF8FAFC),
    inputBg: Color(0xFF0F172A),
    inputBorder: Color(0xFF475569),
    inputFocus: Color(0xFF3B82F6),
    hover: Color(0x0AF8FAFC),
    active: Color(0x143B82F6),
    shadowColor: Color(0xFF000000),
  );

  // 2. TECHY (Neon-on-dark, hacker aesthetic - Default: Dark)
  static const techyLight = AppColorTokens(
    bg: Color(0xFFE8F5E9),
    surface: Color(0xFFC8E6C9),
    surfaceAlt: Color(0xFFA5D6A7),
    primary: Color(0xFF1B5E20),
    accent: Color(0xFF00C853),
    accentSoft: Color(0x2000C853),
    accentRing: Color(0x4000C853),
    text: Color(0xFF1B5E20),
    textMuted: Color(0xFF2E7D32),
    textSubtle: Color(0xFF4CAF50),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF1B5E20),
    borderStrong: Color(0xFF000000),
    inputBg: Color(0xFFE8F5E9),
    inputBorder: Color(0xFF81C784),
    inputFocus: Color(0xFF00C853),
    hover: Color(0x0A1B5E20),
    active: Color(0x1400C853),
    shadowColor: Color(0xFF1B5E20),
  );

  static const techyDark = AppColorTokens(
    bg: Color(0xFF050505),
    surface: Color(0xFF0F0F0F),
    surfaceAlt: Color(0xFF1A1A1A),
    primary: Color(0xFF00FF66),
    accent: Color(0xFF00FF66),
    accentSoft: Color(0x2000FF66),
    accentRing: Color(0x4000FF66),
    text: Color(0xFFE5E5E5),
    textMuted: Color(0xFFA3A3A3),
    textSubtle: Color(0xFF525252),
    textInvert: Color(0xFF050505),
    border: Color(0xFF00FF66),
    borderStrong: Color(0xFF00FF66),
    inputBg: Color(0xFF000000),
    inputBorder: Color(0xFF262626),
    inputFocus: Color(0xFF00FF66),
    hover: Color(0x1000FF66),
    active: Color(0x2000FF66),
    shadowColor: Color(0xFF00FF66),
  );

  // 3. FRIENDLY (Warm oranges, approachable - Default: Light)
  static const friendlyLight = AppColorTokens(
    bg: Color(0xFFFFF7ED),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFFEDD5),
    primary: Color(0xFF7C2D12),
    accent: Color(0xFFEA580C),
    accentSoft: Color(0x15EA580C),
    accentRing: Color(0x30EA580C),
    text: Color(0xFF431407),
    textMuted: Color(0xFF7C2D12),
    textSubtle: Color(0xFF9A3412),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF7C2D12),
    borderStrong: Color(0xFF431407),
    inputBg: Color(0xFFFFFDFA),
    inputBorder: Color(0xFFFED7AA),
    inputFocus: Color(0xFFEA580C),
    hover: Color(0x0A7C2D12),
    active: Color(0x14EA580C),
    shadowColor: Color(0xFF7C2D12),
  );

  static const friendlyDark = AppColorTokens(
    bg: Color(0xFF1C0D02),
    surface: Color(0xFF2D1606),
    surfaceAlt: Color(0xFF45220B),
    primary: Color(0xFFFFEDD5),
    accent: Color(0xFFF97316),
    accentSoft: Color(0x20F97316),
    accentRing: Color(0x40F97316),
    text: Color(0xFFFFEDD5),
    textMuted: Color(0xFFFED7AA),
    textSubtle: Color(0xFFFDBA74),
    textInvert: Color(0xFF1C0D02),
    border: Color(0xFF45220B),
    borderStrong: Color(0xFFF97316),
    inputBg: Color(0xFF1C0D02),
    inputBorder: Color(0xFF7C2D12),
    inputFocus: Color(0xFFF97316),
    hover: Color(0x0AFFFFED),
    active: Color(0x14F97316),
    shadowColor: Color(0xFF000000),
  );

  // 4. CORPORATE (Purple-toned, polished - Default: Light)
  static const corporateLight = AppColorTokens(
    bg: Color(0xFFFAF5FF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF3E8FF),
    primary: Color(0xFF3B0764),
    accent: Color(0xFF7E22CE),
    accentSoft: Color(0x157E22CE),
    accentRing: Color(0x307E22CE),
    text: Color(0xFF1E1B4B),
    textMuted: Color(0xFF3B0764),
    textSubtle: Color(0xFF581C87),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF3B0764),
    borderStrong: Color(0xFF1E1B4B),
    inputBg: Color(0xFFFDFAFF),
    inputBorder: Color(0xFFE9D5FF),
    inputFocus: Color(0xFF7E22CE),
    hover: Color(0x0A3B0764),
    active: Color(0x147E22CE),
    shadowColor: Color(0xFF3B0764),
  );

  static const corporateDark = AppColorTokens(
    bg: Color(0xFF120024),
    surface: Color(0xFF1F0833),
    surfaceAlt: Color(0xFF32134D),
    primary: Color(0xFFF3E8FF),
    accent: Color(0xFFA855F7),
    accentSoft: Color(0x20A855F7),
    accentRing: Color(0x40A855F7),
    text: Color(0xFFF3E8FF),
    textMuted: Color(0xFFE9D5FF),
    textSubtle: Color(0xFFD8B4FE),
    textInvert: Color(0xFF120024),
    border: Color(0xFF32134D),
    borderStrong: Color(0xFFA855F7),
    inputBg: Color(0xFF120024),
    inputBorder: Color(0xFF581C87),
    inputFocus: Color(0xFFA855F7),
    hover: Color(0x0AF3E8FF),
    active: Color(0x14A855F7),
    shadowColor: Color(0xFF000000),
  );

  // 5. PLAYFUL (Vibrant pink/purple, energetic - Default: Dark)
  static const playfulLight = AppColorTokens(
    bg: Color(0xFFFFF1F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFFE4E6),
    primary: Color(0xFF881337),
    accent: Color(0xFFD01B5E),
    accentSoft: Color(0x15D01B5E),
    accentRing: Color(0x30D01B5E),
    text: Color(0xFF4C0519),
    textMuted: Color(0xFF881337),
    textSubtle: Color(0xFF9F1239),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF881337),
    borderStrong: Color(0xFF4C0519),
    inputBg: Color(0xFFFFF8F9),
    inputBorder: Color(0xFFFECDD3),
    inputFocus: Color(0xFFD01B5E),
    hover: Color(0x0A881337),
    active: Color(0x14D01B5E),
    shadowColor: Color(0xFF881337),
  );

  static const playfulDark = AppColorTokens(
    bg: Color(0xFF280018),
    surface: Color(0xFF3D0C27),
    surfaceAlt: Color(0xFF5A163C),
    primary: Color(0xFFFFECEF),
    accent: Color(0xFFEC4899),
    accentSoft: Color(0x20EC4899),
    accentRing: Color(0x40EC4899),
    text: Color(0xFFFFECEF),
    textMuted: Color(0xFFFBCFE8),
    textSubtle: Color(0xFFF472B6),
    textInvert: Color(0xFF280018),
    border: Color(0xFF5A163C),
    borderStrong: Color(0xFFEC4899),
    inputBg: Color(0xFF280018),
    inputBorder: Color(0xFF9F1239),
    inputFocus: Color(0xFFEC4899),
    hover: Color(0x0AFFECEF),
    active: Color(0x14EC4899),
    shadowColor: Color(0xFF000000),
  );

  // 6. TRAILBLAZER (Navy + golden yellow, bold - Default: Dark)
  static const trailblazerLight = AppColorTokens(
    bg: Color(0xFFF0F4F8),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFD9E2EC),
    primary: Color(0xFF06152B),
    accent: Color(0xFFD97706),
    accentSoft: Color(0x15D97706),
    accentRing: Color(0x30D97706),
    text: Color(0xFF06152B),
    textMuted: Color(0xFF102A43),
    textSubtle: Color(0xFF243B53),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF06152B),
    borderStrong: Color(0xFF000000),
    inputBg: Color(0xFFF8FAFC),
    inputBorder: Color(0xFFBCCCDC),
    inputFocus: Color(0xFFD97706),
    hover: Color(0x0A06152B),
    active: Color(0x14D97706),
    shadowColor: Color(0xFF06152B),
  );

  static const trailblazerDark = AppColorTokens(
    bg: Color(0xFF0B131F),
    surface: Color(0xFF172237),
    surfaceAlt: Color(0xFF23314A),
    primary: Color(0xFFE0E6ED),
    accent: Color(0xFFF59E0B),
    accentSoft: Color(0x20F59E0B),
    accentRing: Color(0x40F59E0B),
    text: Color(0xFFE0E6ED),
    textMuted: Color(0xFF9FB3C8),
    textSubtle: Color(0xFF627D98),
    textInvert: Color(0xFF0B131F),
    border: Color(0xFF23314A),
    borderStrong: Color(0xFFF59E0B),
    inputBg: Color(0xFF0B131F),
    inputBorder: Color(0xFF334E68),
    inputFocus: Color(0xFFF59E0B),
    hover: Color(0x0AE0E6ED),
    active: Color(0x14F59E0B),
    shadowColor: Color(0xFFF59E0B),
  );

  // 7. MONOCHROME (Cool grays only, minimal - Default: Dark)
  static const monochromeLight = AppColorTokens(
    bg: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE5E5E5),
    primary: Color(0xFF171717),
    accent: Color(0xFF262626),
    accentSoft: Color(0x15262626),
    accentRing: Color(0x30262626),
    text: Color(0xFF171717),
    textMuted: Color(0xFF404040),
    textSubtle: Color(0xFF737373),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFF171717),
    borderStrong: Color(0xFF000000),
    inputBg: Color(0xFFFAFAFA),
    inputBorder: Color(0xFFD4D4D4),
    inputFocus: Color(0xFF171717),
    hover: Color(0x0A171717),
    active: Color(0x14262626),
    shadowColor: Color(0xFF171717),
  );

  static const monochromeDark = AppColorTokens(
    bg: Color(0xFF0A0A0A),
    surface: Color(0xFF171717),
    surfaceAlt: Color(0xFF262626),
    primary: Color(0xFFF5F5F5),
    accent: Color(0xFFE5E5E5),
    accentSoft: Color(0x20E5E5E5),
    accentRing: Color(0x40E5E5E5),
    text: Color(0xFFF5F5F5),
    textMuted: Color(0xFFA3A3A3),
    textSubtle: Color(0xFF525252),
    textInvert: Color(0xFF171717),
    border: Color(0xFF262626),
    borderStrong: Color(0xFFE5E5E5),
    inputBg: Color(0xFF0A0A0A),
    inputBorder: Color(0xFF404040),
    inputFocus: Color(0xFFF5F5F5),
    hover: Color(0x0AF5F5F5),
    active: Color(0x14E5E5E5),
    shadowColor: Color(0xFFE5E5E5),
  );

  // 8. RIDER GREEN (High-visibility green, outdoor readability - Default: Dark)
  static const riderGreenLight = AppColorTokens(
    bg: Color(0xFFDCEEE2),
    surface: Color(0xFFEAF5EE),
    surfaceAlt: Color(0xFFC8DECE),
    primary: Color(0xFF0A1A0F),
    accent: Color(0xFF16A34A),
    accentSoft: Color(0x2016A34A),
    accentRing: Color(0x3516A34A),
    text: Color(0xFF0F1117),
    textMuted: Color(0xFF3A3F4A),
    textSubtle: Color(0xFF6B7385),
    textInvert: Color(0xFFFFFFFF),
    border: Color(0xFFAAC8B4),
    borderStrong: Color(0xFF8AAD96),
    inputBg: Color(0xFFF2F9F4),
    inputBorder: Color(0xFFAAC8B4),
    inputFocus: Color(0xFF16A34A),
    hover: Color(0x0A0A1A0F),
    active: Color(0x1416A34A),
    shadowColor: Color(0xFF0A1A0F),
  );

  static const riderGreenDark = AppColorTokens(
    bg: Color(0xFF0A1A0F),
    surface: Color(0xFF122A19),
    surfaceAlt: Color(0xFF1A3D24),
    primary: Color(0xFFF0FFF4),
    accent: Color(0xFF22C55E),
    accentSoft: Color(0x2622C55E),
    accentRing: Color(0x4022C55E),
    text: Color(0xFFF0F2F5),
    textMuted: Color(0xFFC8CDD8),
    textSubtle: Color(0xFF8E95A6),
    textInvert: Color(0xFF0A1A0F),
    border: Color(0xFF1E3A28),
    borderStrong: Color(0xFF2D5A3C),
    inputBg: Color(0xFF122A19),
    inputBorder: Color(0xFF1E3A28),
    inputFocus: Color(0xFF22C55E),
    hover: Color(0x0AF0FFF4),
    active: Color(0x1422C55E),
    shadowColor: Color(0xB3D1FAE5),
  );

  static AppColorTokens getTokens(String themeId, bool isDark) {
    switch (themeId) {
      case 'techy':
        return isDark ? techyDark : techyLight;
      case 'friendly':
        return isDark ? friendlyDark : friendlyLight;
      case 'corporate':
        return isDark ? corporateDark : corporateLight;
      case 'playful':
        return isDark ? playfulDark : playfulLight;
      case 'trailblazer':
        return isDark ? trailblazerDark : trailblazerLight;
      case 'monochrome':
        return isDark ? monochromeDark : monochromeLight;
      case 'rider-green':
        return isDark ? riderGreenDark : riderGreenLight;
      case 'pure-bold':
      default:
        return isDark ? pureBoldDark : pureBoldLight;
    }
  }

  static String getThemeName(String id) {
    switch (id) {
      case 'pure-bold':
        return 'Pure Bold';
      case 'techy':
        return 'Techy';
      case 'friendly':
        return 'Friendly';
      case 'corporate':
        return 'Corporate';
      case 'playful':
        return 'Playful';
      case 'trailblazer':
        return 'Trailblazer';
      case 'monochrome':
        return 'Monochrome';
      case 'rider-green':
        return 'Rider Green';
      default:
        return 'Unknown';
    }
  }
}
