import 'speeds.dart';
import 'curves.dart';
import 'package:flutter/animation.dart';

enum ThemePackage {
  standard,
  softAndSmooth,
  glassAndModern,
  playfulAndEnergetic,
  minimalAndClean,
}

class AnimatorThemeConfig {
  final Duration defaultEnSpeed;
  final Duration defaultExSpeed;
  final Duration defaultToSpeed;
  final Curve defaultEnCurve;
  final Curve defaultExCurve;
  final Curve defaultToCurve;
  final bool enableBlur;
  final bool enable3D;

  const AnimatorThemeConfig({
    required this.defaultEnSpeed,
    required this.defaultExSpeed,
    required this.defaultToSpeed,
    required this.defaultEnCurve,
    required this.defaultExCurve,
    required this.defaultToCurve,
    this.enableBlur = true,
    this.enable3D = true,
  });

  static AnimatorThemeConfig of(ThemePackage package) {
    switch (package) {
      case ThemePackage.standard:
        return const AnimatorThemeConfig(
          defaultEnSpeed: AS.balanced,
          defaultExSpeed: AS.fast,
          defaultToSpeed: AS.veryFast,
          defaultEnCurve: AC.easeOutCubic,
          defaultExCurve: AC.easeInCubic,
          defaultToCurve: AC.decelerate,
        );
      case ThemePackage.softAndSmooth:
        return const AnimatorThemeConfig(
          defaultEnSpeed: AS.slow,
          defaultExSpeed: AS.balanced,
          defaultToSpeed: AS.veryFast,
          defaultEnCurve: AC.easeInOutSine,
          defaultExCurve: AC.easeInOutSine,
          defaultToCurve: AC.easeInOutSine,
        );
      case ThemePackage.glassAndModern:
        return const AnimatorThemeConfig(
          defaultEnSpeed: AS.slow,
          defaultExSpeed: AS.balanced,
          defaultToSpeed: AS.balanced,
          defaultEnCurve: AC.easeInOutSine,
          defaultExCurve: AC.easeInCubic,
          defaultToCurve: AC.easeOutCubic,
          enableBlur: true,
          enable3D: true,
        );
      case ThemePackage.playfulAndEnergetic:
        return const AnimatorThemeConfig(
          defaultEnSpeed: AS.veryFast,
          defaultExSpeed: AS.fast,
          defaultToSpeed: AS.veryFast,
          defaultEnCurve: AC.elasticOut,
          defaultExCurve: AC.easeInBack,
          defaultToCurve: AC.bounceOut,
        );
      case ThemePackage.minimalAndClean:
        return const AnimatorThemeConfig(
          defaultEnSpeed: AS.balanced,
          defaultExSpeed: AS.fast,
          defaultToSpeed: AS.veryFast,
          defaultEnCurve: AC.easeOutCubic,
          defaultExCurve: AC.easeInCubic,
          defaultToCurve: AC.decelerate,
          enableBlur: false,
          enable3D: false,
        );
    }
  }
}
