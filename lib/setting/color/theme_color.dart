import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';
import 'theme_palette.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ColorPalette.mintPrimary,
      onPrimary: Colors.white,
      secondary: ColorPalette.mintAccent,
      onSecondary: ColorPalette.textMainLight,
      tertiary: ColorPalette.calorieBurn,
      onTertiary: Colors.white,
      surface: ColorPalette.surfaceLight,
      onSurface: ColorPalette.textMainLight,
      error: ColorPalette.error,
      onError: Colors.white,
      outline: ColorPalette.borderLight,
    ),
    scaffoldBackgroundColor: ColorPalette.bgLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorPalette.textMainLight,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: ColorPalette.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ColorPalette.borderLight, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ColorPalette.mintPrimary,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: ColorPalette.textMainLight,
          fontWeight: FontWeight.bold,
          fontSize: 20),
      titleMedium: TextStyle(
          color: ColorPalette.textMainLight,
          fontWeight: FontWeight.w600,
          fontSize: 16),
      bodyLarge: TextStyle(color: ColorPalette.textMainLight, fontSize: 15),
      bodyMedium: TextStyle(color: ColorPalette.textSubLight, fontSize: 14),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: ColorPalette.mintPrimary,
      onPrimary: ColorPalette.bgDark,
      secondary: ColorPalette.mintAccent,
      onSecondary: ColorPalette.bgDark,
      tertiary: ColorPalette.calorieBurn,
      onTertiary: Colors.white,
      surface: ColorPalette.surfaceDark,
      onSurface: ColorPalette.textMainDark,
      error: ColorPalette.error,
      onError: Colors.white,
      outline: ColorPalette.borderDark,
    ),
    scaffoldBackgroundColor: ColorPalette.bgDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorPalette.textMainDark,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: ColorPalette.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ColorPalette.borderDark, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ColorPalette.mintPrimary,
      foregroundColor: ColorPalette.bgDark,
      elevation: 4,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: ColorPalette.textMainDark,
          fontWeight: FontWeight.bold,
          fontSize: 20),
      titleMedium: TextStyle(
          color: ColorPalette.textMainDark,
          fontWeight: FontWeight.w600,
          fontSize: 16),
      bodyLarge: TextStyle(color: ColorPalette.textMainDark, fontSize: 15),
      bodyMedium: TextStyle(color: ColorPalette.textSubDark, fontSize: 14),
    ),
  );

  static final ThemeData zenVitality = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ColorPalette.mintPrimary,
      onPrimary: Colors.white,
      secondary: ColorPalette.mintAccent,
      onSecondary: ColorPalette.textMainLight,
      tertiary: ColorPalette.calorieBurn,
      onTertiary: Colors.white,
      surface: Color(0xFFF0FDF4),
      onSurface: ColorPalette.textMainLight,
      error: ColorPalette.error,
      outline: Color(0xFFDCFCE7),
    ),
    scaffoldBackgroundColor: const Color(0xFFFEFAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ColorPalette.textMainLight,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF0FDF4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFDCFCE7), width: 1.5),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ColorPalette.mintPrimary,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: ColorPalette.textMainLight, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: ColorPalette.textMainLight),
      bodyLarge: TextStyle(color: ColorPalette.textMainLight),
      bodyMedium: TextStyle(color: ColorPalette.textSubLight),
    ),
  );

  static ThemeData getTheme(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark
        ? darkTheme
        : lightTheme;
  }

  /// Build ThemeData from a Helsa palette + day/night flag.
  static ThemeData fromPalette(HelsaPalette palette, {required bool night}) {
    final cs = palette.scheme(night);
    final onSurf = cs.onSurface;
    final sub = onSurf.withValues(alpha: 0.70);
    final bg = night
        ? Color.alphaBlend(
            const Color(0xFF000000).withValues(alpha: 0.25), cs.surface)
        : Color.alphaBlend(
            const Color(0xFFFFFFFF).withValues(alpha: 0.35), cs.surface);

    return ThemeData(
      useMaterial3: true,
      brightness: night ? Brightness.dark : Brightness.light,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      canvasColor: cs.surface,
      cardColor: cs.surface,
      dividerColor: cs.outline.withValues(alpha: 0.5),
      iconTheme: IconThemeData(color: onSurf, size: 24),
      primaryIconTheme: IconThemeData(color: cs.onPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: onSurf,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurf),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: night ? Brightness.light : Brightness.dark,
          statusBarBrightness: night ? Brightness.dark : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 1),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onSurf,
        textColor: onSurf,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
            color: onSurf, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(
            color: onSurf, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: onSurf, fontSize: 15),
        bodyMedium: TextStyle(color: sub, fontSize: 14),
        bodySmall: TextStyle(color: sub, fontSize: 12),
        labelLarge: TextStyle(color: onSurf, fontWeight: FontWeight.w600),
      ),
    );
  }
}
