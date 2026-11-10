// lib/setting/motion/motion_settings.dart
// Global animation speed + simplified motion (performance / accessibility).
import 'package:flutter/animation.dart';
import 'package:helsa/setting/storage/settings_store.dart';

enum AnimationSpeed {
  calm,
  medium,
  fast,
}

class MotionSettings {
  MotionSettings._();

  static AnimationSpeed get speed {
    try {
      switch (SettingsStore.animationSpeedKey) {
        case 'calm':
          return AnimationSpeed.calm;
        case 'fast':
          return AnimationSpeed.fast;
        default:
          return AnimationSpeed.medium;
      }
    } catch (_) {
      return AnimationSpeed.medium;
    }
  }

  static bool get simple {
    try {
      return SettingsStore.simpleMotion;
    } catch (_) {
      return false;
    }
  }

  static double get timeScale {
    switch (speed) {
      case AnimationSpeed.calm:
        return 1.45;
      case AnimationSpeed.medium:
        return 1.0;
      case AnimationSpeed.fast:
        return 0.62;
    }
  }

  static Duration ms(int milliseconds) {
    var scaled = (milliseconds * timeScale).round().clamp(1, 8000);
    if (simple && scaled > 420) {
      scaled = (420 * timeScale.clamp(0.55, 1.15)).round().clamp(1, 420);
    }
    return Duration(milliseconds: scaled);
  }

  static Duration get expandOpen => simple ? ms(280) : ms(1300);
  static Duration get pageDefault => simple ? ms(280) : ms(500);
  static Duration get short => ms(220);
  static Duration get micro => ms(120);

  static Curve get curve =>
      simple ? Curves.easeOut : Curves.easeInOutCubic;

  static Curve get emphasize =>
      simple ? Curves.easeOut : Curves.easeOutCubic;
}
