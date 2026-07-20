import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppThemeScope extends InheritedWidget {
  final String themeId;
  final AppColorTokens tokens;
  final bool isDark;

  const AppThemeScope({
    super.key,
    required this.themeId,
    required this.tokens,
    required this.isDark,
    required super.child,
  });

  static AppThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    if (scope == null) {
      throw Exception('No AppThemeScope found in context');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) {
    return themeId != oldWidget.themeId || tokens != oldWidget.tokens || isDark != oldWidget.isDark;
  }
}

extension AppThemeContextExtension on BuildContext {
  AppColorTokens get tokens => AppThemeScope.of(this).tokens;
  bool get isDarkTheme => AppThemeScope.of(this).isDark;
  String get themeId => AppThemeScope.of(this).themeId;
}

class AppTheme {
  static ThemeData generateThemeData(AppColorTokens tokens, bool isDark) {
    final textTheme = GoogleFonts.dmSansTextTheme().apply(
      bodyColor: tokens.text,
      displayColor: tokens.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: tokens.bg,
      primaryColor: tokens.primary,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: tokens.primary,
        onPrimary: tokens.textInvert,
        secondary: tokens.accent,
        onSecondary: tokens.textInvert,
        error: AppStatusColors.error,
        onError: Colors.white,
        surface: tokens.surface,
        onSurface: tokens.text,
      ),
      fontFamily: 'DM Sans',
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontFamily: 'Syne', // headings use Syne
          fontWeight: FontWeight.bold,
          color: tokens.text,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w600,
          color: tokens.text,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w500,
          color: tokens.text,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: tokens.text,
        ),
        shape: Border(
          bottom: BorderSide(color: tokens.border, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surface,
        selectedItemColor: tokens.accent,
        unselectedItemColor: tokens.textSubtle,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.text,
        shape: Border.all(color: tokens.border, width: 1.5),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.inputBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.inputBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: tokens.inputFocus, width: 2.0),
        ),
        hintStyle: TextStyle(color: tokens.textSubtle, fontSize: 14),
        labelStyle: TextStyle(color: tokens.textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.textInvert,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: tokens.shadowColor, width: 1.5),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: tokens.border, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
