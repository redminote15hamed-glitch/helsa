import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_palette.dart';

class AppTheme {
  /// Default light theme (mint palette). Prefer [fromPalette] / ThemeStore.
  static ThemeData get lightTheme =>
      fromPalette(HelsaPalette.byId('mint'), night: false);

  /// Default dark theme (mint palette). Prefer [fromPalette] / ThemeStore.
  static ThemeData get darkTheme =>
      fromPalette(HelsaPalette.byId('mint'), night: true);

  static ThemeData of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
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
