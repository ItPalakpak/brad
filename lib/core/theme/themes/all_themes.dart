import 'package:flutter/material.dart';
import '../tokens.dart';

// All themes use true monochromatic palettes:
// every token (bg, surface, text, border, shadow) is derived from
// the same base hue — only lightness and saturation vary.
// No pure whites (#FFF), blacks (#000), or generic grays unless
// the theme's hue IS gray (Monochrome).

class AppThemes {
  // ─────────────────────────────────────────────
  // 1. PURE BOLD — Slate blue monochrome
  //    Light default. Hue: ~220° (cool blue-slate)
  // ─────────────────────────────────────────────
  static const pureBoldLight = AppColorTokens(
    bg:           Color(0xFFF1F4F9), // slate-50 tint
    surface:      Color(0xFFFAFCFF), // near-white, blue-tinted
    surfaceAlt:   Color(0xFFE2E8F2), // slate-100
    primary:      Color(0xFF0D1829), // deep slate navy
    accent:       Color(0xFF1D4ED8), // vivid blue
    accentSoft:   Color(0x181D4ED8),
    accentRing:   Color(0x351D4ED8),
    text:         Color(0xFF0D1829),
    textMuted:    Color(0xFF2D4068),
    textSubtle:   Color(0xFF5A739A),
    textInvert:   Color(0xFFF8FAFD),
    border:       Color(0xFFA8B8D4),
    borderStrong: Color(0xFF2D4068),
    inputBg:      Color(0xFFF8FAFD),
    inputBorder:  Color(0xFFC4D1E6),
    inputFocus:   Color(0xFF1D4ED8),
    hover:        Color(0x0C0D1829),
    active:       Color(0x181D4ED8),
    shadowColor:  Color(0xFF0D1829),
  );

  static const pureBoldDark = AppColorTokens(
    bg:           Color(0xFF080E1A), // deepest slate
    surface:      Color(0xFF0F1A2E), // slate-900
    surfaceAlt:   Color(0xFF182540), // slate-800
    primary:      Color(0xFFD6E2F5), // pale slate-blue
    accent:       Color(0xFF4F87F6), // brighter blue for dark
    accentSoft:   Color(0x204F87F6),
    accentRing:   Color(0x404F87F6),
    text:         Color(0xFFD6E2F5),
    textMuted:    Color(0xFF9DB4D8),
    textSubtle:   Color(0xFF5A739A),
    textInvert:   Color(0xFF080E1A),
    border:       Color(0xFF1E3252),
    borderStrong: Color(0xFF4F87F6),
    inputBg:      Color(0xFF080E1A),
    inputBorder:  Color(0xFF2A3F60),
    inputFocus:   Color(0xFF4F87F6),
    hover:        Color(0x0AD6E2F5),
    active:       Color(0x1A4F87F6),
    shadowColor:  Color(0xFF000610),
  );

  // ─────────────────────────────────────────────
  // 2. TECHY — Terminal green monochrome
  //    Dark default. Hue: ~140° (saturated green)
  // ─────────────────────────────────────────────
  static const techyLight = AppColorTokens(
    bg:           Color(0xFFEEF8F0), // very pale green
    surface:      Color(0xFFF7FDF8), // near-white green tint
    surfaceAlt:   Color(0xFFDCEEE0), // green-100
    primary:      Color(0xFF0B280F), // deep forest text
    accent:       Color(0xFF0D9E3A), // vivid mid-green
    accentSoft:   Color(0x1A0D9E3A),
    accentRing:   Color(0x350D9E3A),
    text:         Color(0xFF0B280F),
    textMuted:    Color(0xFF1C5028),
    textSubtle:   Color(0xFF347A44),
    textInvert:   Color(0xFFF7FDF8),
    border:       Color(0xFF7DC08E),
    borderStrong: Color(0xFF1C5028),
    inputBg:      Color(0xFFF4FCF6),
    inputBorder:  Color(0xFFA8D8B2),
    inputFocus:   Color(0xFF0D9E3A),
    hover:        Color(0x0C0B280F),
    active:       Color(0x1A0D9E3A),
    shadowColor:  Color(0xFF0B280F),
  );

  static const techyDark = AppColorTokens(
    bg:           Color(0xFF010E03), // near-black green
    surface:      Color(0xFF051A08), // very deep green
    surfaceAlt:   Color(0xFF0C2912), // green-950
    primary:      Color(0xFFC6F0CC), // pale mint
    accent:       Color(0xFF00E05A), // neon terminal green
    accentSoft:   Color(0x2200E05A),
    accentRing:   Color(0x4000E05A),
    text:         Color(0xFFC6F0CC),
    textMuted:    Color(0xFF72C480),
    textSubtle:   Color(0xFF2E7A3C),
    textInvert:   Color(0xFF010E03),
    border:       Color(0xFF0C2912),
    borderStrong: Color(0xFF00E05A),
    inputBg:      Color(0xFF010E03),
    inputBorder:  Color(0xFF0F3317),
    inputFocus:   Color(0xFF00E05A),
    hover:        Color(0x12C6F0CC),
    active:       Color(0x2200E05A),
    shadowColor:  Color(0xFF00FF66),
  );

  // ─────────────────────────────────────────────
  // 3. FRIENDLY — Warm amber-orange monochrome
  //    Light default. Hue: ~25° (amber-orange)
  // ─────────────────────────────────────────────
  static const friendlyLight = AppColorTokens(
    bg:           Color(0xFFFFF5EB), // warm cream
    surface:      Color(0xFFFFFCF8), // off-white amber tint
    surfaceAlt:   Color(0xFFFFECD5), // amber-100
    primary:      Color(0xFF5C1E04), // deep burnt sienna
    accent:       Color(0xFFD45200), // vivid amber-orange
    accentSoft:   Color(0x18D45200),
    accentRing:   Color(0x32D45200),
    text:         Color(0xFF5C1E04),
    textMuted:    Color(0xFF8C3210),
    textSubtle:   Color(0xFFB85520),
    textInvert:   Color(0xFFFFFCF8),
    border:       Color(0xFFE8A87A),
    borderStrong: Color(0xFF8C3210),
    inputBg:      Color(0xFFFFFEF8),
    inputBorder:  Color(0xFFF5C9A0),
    inputFocus:   Color(0xFFD45200),
    hover:        Color(0x0C5C1E04),
    active:       Color(0x18D45200),
    shadowColor:  Color(0xFF5C1E04),
  );

  static const friendlyDark = AppColorTokens(
    bg:           Color(0xFF160800), // near-black amber
    surface:      Color(0xFF271200), // very deep amber
    surfaceAlt:   Color(0xFF3A1C04), // amber-950
    primary:      Color(0xFFFFE8D0), // pale apricot
    accent:       Color(0xFFFF7B28), // vivid orange for dark
    accentSoft:   Color(0x22FF7B28),
    accentRing:   Color(0x40FF7B28),
    text:         Color(0xFFFFE8D0),
    textMuted:    Color(0xFFFFBA80),
    textSubtle:   Color(0xFFC06028),
    textInvert:   Color(0xFF160800),
    border:       Color(0xFF3A1C04),
    borderStrong: Color(0xFFFF7B28),
    inputBg:      Color(0xFF160800),
    inputBorder:  Color(0xFF4A2508),
    inputFocus:   Color(0xFFFF7B28),
    hover:        Color(0x10FFE8D0),
    active:       Color(0x22FF7B28),
    shadowColor:  Color(0xFF000000),
  );

  // ─────────────────────────────────────────────
  // 4. CORPORATE — Deep violet monochrome
  //    Light default. Hue: ~275° (violet-purple)
  // ─────────────────────────────────────────────
  static const corporateLight = AppColorTokens(
    bg:           Color(0xFFF5F0FF), // pale violet tint
    surface:      Color(0xFFFDFBFF), // near-white violet
    surfaceAlt:   Color(0xFFEBE0FF), // violet-100
    primary:      Color(0xFF250048), // deep indigo-violet
    accent:       Color(0xFF6B21C8), // vivid violet
    accentSoft:   Color(0x186B21C8),
    accentRing:   Color(0x326B21C8),
    text:         Color(0xFF250048),
    textMuted:    Color(0xFF46107A),
    textSubtle:   Color(0xFF7040A8),
    textInvert:   Color(0xFFFDFBFF),
    border:       Color(0xFFC4A8ED),
    borderStrong: Color(0xFF46107A),
    inputBg:      Color(0xFFFBF8FF),
    inputBorder:  Color(0xFFD8C0F5),
    inputFocus:   Color(0xFF6B21C8),
    hover:        Color(0x0C250048),
    active:       Color(0x186B21C8),
    shadowColor:  Color(0xFF250048),
  );

  static const corporateDark = AppColorTokens(
    bg:           Color(0xFF0C0018), // near-black violet
    surface:      Color(0xFF160828), // very deep violet
    surfaceAlt:   Color(0xFF22103C), // violet-950
    primary:      Color(0xFFEEE0FF), // pale lavender
    accent:       Color(0xFFA855F7), // bright violet for dark
    accentSoft:   Color(0x22A855F7),
    accentRing:   Color(0x40A855F7),
    text:         Color(0xFFEEE0FF),
    textMuted:    Color(0xFFC49AEE),
    textSubtle:   Color(0xFF7B50B0),
    textInvert:   Color(0xFF0C0018),
    border:       Color(0xFF22103C),
    borderStrong: Color(0xFFA855F7),
    inputBg:      Color(0xFF0C0018),
    inputBorder:  Color(0xFF2D1650),
    inputFocus:   Color(0xFFA855F7),
    hover:        Color(0x10EEE0FF),
    active:       Color(0x22A855F7),
    shadowColor:  Color(0xFF000000),
  );

  // ─────────────────────────────────────────────
  // 5. PLAYFUL — Hot pink monochrome
  //    Dark default. Hue: ~340° (rose-pink)
  // ─────────────────────────────────────────────
  static const playfulLight = AppColorTokens(
    bg:           Color(0xFFFFF0F4), // pale rose
    surface:      Color(0xFFFFFBFC), // near-white pink tint
    surfaceAlt:   Color(0xFFFFE0E8), // rose-100
    primary:      Color(0xFF5C0A28), // deep crimson
    accent:       Color(0xFFC81858), // vivid hot pink
    accentSoft:   Color(0x18C81858),
    accentRing:   Color(0x32C81858),
    text:         Color(0xFF5C0A28),
    textMuted:    Color(0xFF8A1840),
    textSubtle:   Color(0xFFB83060),
    textInvert:   Color(0xFFFFFBFC),
    border:       Color(0xFFEDA0C0),
    borderStrong: Color(0xFF8A1840),
    inputBg:      Color(0xFFFFF8FA),
    inputBorder:  Color(0xFFF5C0D4),
    inputFocus:   Color(0xFFC81858),
    hover:        Color(0x0C5C0A28),
    active:       Color(0x18C81858),
    shadowColor:  Color(0xFF5C0A28),
  );

  static const playfulDark = AppColorTokens(
    bg:           Color(0xFF180010), // near-black pink
    surface:      Color(0xFF280520), // very deep rose
    surfaceAlt:   Color(0xFF3C0E30), // rose-950
    primary:      Color(0xFFFFE0EE), // pale blush
    accent:       Color(0xFFF050A8), // vivid hot pink for dark
    accentSoft:   Color(0x22F050A8),
    accentRing:   Color(0x40F050A8),
    text:         Color(0xFFFFE0EE),
    textMuted:    Color(0xFFF098C8),
    textSubtle:   Color(0xFFA84070),
    textInvert:   Color(0xFF180010),
    border:       Color(0xFF3C0E30),
    borderStrong: Color(0xFFF050A8),
    inputBg:      Color(0xFF180010),
    inputBorder:  Color(0xFF4E1240),
    inputFocus:   Color(0xFFF050A8),
    hover:        Color(0x10FFE0EE),
    active:       Color(0x22F050A8),
    shadowColor:  Color(0xFF000000),
  );

  // ─────────────────────────────────────────────
  // 6. TRAILBLAZER — Navy monochrome + gold accent
  //    Dark default. Hue: ~215° navy, accent ~40° gold
  //    Note: navy bg/text family, gold accent only
  // ─────────────────────────────────────────────
  static const trailblazerLight = AppColorTokens(
    bg:           Color(0xFFEEF2F8), // pale navy blue
    surface:      Color(0xFFFAFCFF), // near-white navy tint
    surfaceAlt:   Color(0xFFD6E0EE), // navy-100
    primary:      Color(0xFF050F22), // deepest navy
    accent:       Color(0xFFC27A00), // rich gold
    accentSoft:   Color(0x18C27A00),
    accentRing:   Color(0x32C27A00),
    text:         Color(0xFF050F22),
    textMuted:    Color(0xFF152848),
    textSubtle:   Color(0xFF3A5478),
    textInvert:   Color(0xFFFAFCFF),
    border:       Color(0xFF9AAEC8),
    borderStrong: Color(0xFF152848),
    inputBg:      Color(0xFFF5F8FC),
    inputBorder:  Color(0xFFBAC8DC),
    inputFocus:   Color(0xFFC27A00),
    hover:        Color(0x0C050F22),
    active:       Color(0x18C27A00),
    shadowColor:  Color(0xFF050F22),
  );

  static const trailblazerDark = AppColorTokens(
    bg:           Color(0xFF050A14), // deepest navy-black
    surface:      Color(0xFF0C1526), // navy-950
    surfaceAlt:   Color(0xFF152235), // navy-900
    primary:      Color(0xFFD8E4F5), // pale steel blue
    accent:       Color(0xFFF5A800), // vivid gold for dark
    accentSoft:   Color(0x22F5A800),
    accentRing:   Color(0x40F5A800),
    text:         Color(0xFFD8E4F5),
    textMuted:    Color(0xFF8AA4C8),
    textSubtle:   Color(0xFF4A6488),
    textInvert:   Color(0xFF050A14),
    border:       Color(0xFF152235),
    borderStrong: Color(0xFFF5A800),
    inputBg:      Color(0xFF050A14),
    inputBorder:  Color(0xFF1E3050),
    inputFocus:   Color(0xFFF5A800),
    hover:        Color(0x10D8E4F5),
    active:       Color(0x22F5A800),
    shadowColor:  Color(0xBBF5A800),
  );

  // ─────────────────────────────────────────────
  // 7. MONOCHROME — Warm gray monochrome
  //    Dark default. Hue: ~35° (very low saturation warm)
  // ─────────────────────────────────────────────
  static const monochromeLight = AppColorTokens(
    bg:           Color(0xFFF4F3F0), // warm gray-50
    surface:      Color(0xFFFAFAF8), // warm near-white
    surfaceAlt:   Color(0xFFE8E6E0), // warm gray-100
    primary:      Color(0xFF141210), // warm near-black
    accent:       Color(0xFF3C3830), // deep warm gray (accent = darkest)
    accentSoft:   Color(0x183C3830),
    accentRing:   Color(0x303C3830),
    text:         Color(0xFF141210),
    textMuted:    Color(0xFF3C3830),
    textSubtle:   Color(0xFF706860),
    textInvert:   Color(0xFFFAFAF8),
    border:       Color(0xFFB8B4AC),
    borderStrong: Color(0xFF3C3830),
    inputBg:      Color(0xFFF8F7F5),
    inputBorder:  Color(0xFFD4D0C8),
    inputFocus:   Color(0xFF3C3830),
    hover:        Color(0x0C141210),
    active:       Color(0x183C3830),
    shadowColor:  Color(0xFF141210),
  );

  static const monochromeDark = AppColorTokens(
    bg:           Color(0xFF0A0908), // warm near-black
    surface:      Color(0xFF161410), // warm gray-950
    surfaceAlt:   Color(0xFF222018), // warm gray-900
    primary:      Color(0xFFF0EDE8), // warm near-white
    accent:       Color(0xFFD4D0C8), // light warm gray
    accentSoft:   Color(0x20D4D0C8),
    accentRing:   Color(0x38D4D0C8),
    text:         Color(0xFFF0EDE8),
    textMuted:    Color(0xFFA8A49C),
    textSubtle:   Color(0xFF605C54),
    textInvert:   Color(0xFF0A0908),
    border:       Color(0xFF222018),
    borderStrong: Color(0xFFD4D0C8),
    inputBg:      Color(0xFF0A0908),
    inputBorder:  Color(0xFF2C2A24),
    inputFocus:   Color(0xFFD4D0C8),
    hover:        Color(0x0FF0EDE8),
    active:       Color(0x20D4D0C8),
    shadowColor:  Color(0xFFD4D0C8),
  );

  // ─────────────────────────────────────────────
  // 8. RIDER GREEN — Forest green monochrome
  //    Dark default. Hue: ~145° (deep forest green)
  // ─────────────────────────────────────────────
  static const riderGreenLight = AppColorTokens(
    bg:           Color(0xFFEAF4EE), // pale forest green
    surface:      Color(0xFFF5FBF7), // near-white green tint
    surfaceAlt:   Color(0xFFD0E8D8), // green-100
    primary:      Color(0xFF092014), // deep forest
    accent:       Color(0xFF0E8C40), // vivid forest green
    accentSoft:   Color(0x200E8C40),
    accentRing:   Color(0x380E8C40),
    text:         Color(0xFF092014),
    textMuted:    Color(0xFF1A4A2C),
    textSubtle:   Color(0xFF32784C),
    textInvert:   Color(0xFFF5FBF7),
    border:       Color(0xFF78C094),
    borderStrong: Color(0xFF1A4A2C),
    inputBg:      Color(0xFFF2F9F5),
    inputBorder:  Color(0xFFA8D8B8),
    inputFocus:   Color(0xFF0E8C40),
    hover:        Color(0x0C092014),
    active:       Color(0x200E8C40),
    shadowColor:  Color(0xFF092014),
  );

  static const riderGreenDark = AppColorTokens(
    bg:           Color(0xFF041008), // near-black forest
    surface:      Color(0xFF081A0E), // very deep green
    surfaceAlt:   Color(0xFF0E2818), // green-950
    primary:      Color(0xFFD0F0DA), // pale mint
    accent:       Color(0xFF18C858), // vivid green for dark
    accentSoft:   Color(0x2618C858),
    accentRing:   Color(0x4018C858),
    text:         Color(0xFFD0F0DA),
    textMuted:    Color(0xFF78C894),
    textSubtle:   Color(0xFF2E7A4C),
    textInvert:   Color(0xFF041008),
    border:       Color(0xFF0E2818),
    borderStrong: Color(0xFF2D5A3C),
    inputBg:      Color(0xFF081A0E),
    inputBorder:  Color(0xFF143420),
    inputFocus:   Color(0xFF18C858),
    hover:        Color(0x10D0F0DA),
    active:       Color(0x2618C858),
    shadowColor:  Color(0xAA90E8B0),
  );

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  static AppColorTokens getTokens(String themeId, bool isDark) {
    switch (themeId) {
      case 'techy':        return isDark ? techyDark        : techyLight;
      case 'friendly':     return isDark ? friendlyDark     : friendlyLight;
      case 'corporate':    return isDark ? corporateDark    : corporateLight;
      case 'playful':      return isDark ? playfulDark      : playfulLight;
      case 'trailblazer':  return isDark ? trailblazerDark  : trailblazerLight;
      case 'monochrome':   return isDark ? monochromeDark   : monochromeLight;
      case 'rider-green':  return isDark ? riderGreenDark   : riderGreenLight;
      case 'pure-bold':
      default:             return isDark ? pureBoldDark     : pureBoldLight;
    }
  }

  static String getThemeName(String id) {
    switch (id) {
      case 'pure-bold':   return 'Pure Bold';
      case 'techy':       return 'Techy';
      case 'friendly':    return 'Friendly';
      case 'corporate':   return 'Corporate';
      case 'playful':     return 'Playful';
      case 'trailblazer': return 'Trailblazer';
      case 'monochrome':  return 'Monochrome';
      case 'rider-green': return 'Rider Green';
      default:            return 'Unknown';
    }
  }
}