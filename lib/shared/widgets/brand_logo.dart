import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum BrandLogoType {
  icon,
  mark,
  wordmark,
}

class BrandLogo extends StatelessWidget {
  final BrandLogoType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? tintColor;

  const BrandLogo({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeId = context.themeId;
    final isDark = context.isDarkTheme;

    final String typeStr;
    switch (type) {
      case BrandLogoType.icon:
        typeStr = 'icon';
        break;
      case BrandLogoType.mark:
        typeStr = 'mark';
        break;
      case BrandLogoType.wordmark:
        typeStr = 'wordmark';
        break;
    }

    // Determine the theme suffix and mode suffix
    String themeSuffix = 'pure_bold';
    String modeSuffix = isDark ? 'dark' : 'light';

    // Map themeId
    if (themeId == 'pure-bold') {
      themeSuffix = 'pure_bold';
      modeSuffix = isDark ? 'dark' : 'light';
    } else if (themeId == 'friendly') {
      if (!isDark) {
        themeSuffix = 'friendly';
        modeSuffix = 'light';
      } else {
        // friendly doesn't have a dark logo, fallback to pure_bold_dark
        themeSuffix = 'pure_bold';
        modeSuffix = 'dark';
      }
    } else if (themeId == 'techy') {
      if (isDark) {
        themeSuffix = 'techy';
        modeSuffix = 'dark';
      } else {
        // techy doesn't have a light logo, fallback to pure_bold_light
        themeSuffix = 'pure_bold';
        modeSuffix = 'light';
      }
    } else if (themeId == 'trailblazer') {
      if (isDark) {
        themeSuffix = 'trailblazer';
        modeSuffix = 'dark';
      } else {
        themeSuffix = 'pure_bold';
        modeSuffix = 'light';
      }
    } else if (themeId == 'rider-green') {
      if (isDark) {
        themeSuffix = 'rider_green';
        modeSuffix = 'dark';
      } else {
        themeSuffix = 'pure_bold';
        modeSuffix = 'light';
      }
    } else {
      // corporate, playful, monochrome fallbacks
      themeSuffix = 'pure_bold';
      modeSuffix = isDark ? 'dark' : 'light';
    }

    final assetPath = 'assets/photos/brad_${typeStr}_${themeSuffix}_$modeSuffix.png';

    if (type == BrandLogoType.wordmark) {
      final h = height;
      return Image.asset(
        assetPath,
        width: width ?? (h != null ? h * 4.0 : null),
        height: height,
        fit: width != null ? fit : BoxFit.fill,
        color: tintColor,
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: tintColor,
    );
  }
}
