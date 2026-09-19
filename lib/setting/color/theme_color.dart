import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_palette.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: ColorPalette.mintPrimary,
      onPrimary: Colors.white,
      secondary: ColorPalette.tealSecondary,
      onSecondary: Colors.white,
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
      secondary: ColorPalette.tealSecondary,
      onSecondary: Colors.white,
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
      primary: ColorPalette.weightGraph,
      onPrimary: Colors.white,
      secondary: ColorPalette.calorieBurn,
      onSecondary: Colors.white,
      surface: Color(0xFFF0FDF4),
      onSurface: ColorPalette.textMainLight,
      error: ColorPalette.error,
      outline: Color(0xFFDCFCE7),
    ),
    scaffoldBackgroundColor: const Color(0x0ffefafc),
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
      backgroundColor: ColorPalette.weightGraph,
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
}
