// lib/setting/units/unit_system.dart
// Canonical storage is always metric (cm / kg). Display converts for imperial.
import 'package:helsa/setting/storage/settings_store.dart';

class UnitSystem {
  UnitSystem._();

  static bool get isImperial {
    try {
      return SettingsStore.unitsKey == 'imperial';
    } catch (_) {
      return false;
    }
  }

  static bool get isMetric => !isImperial;

  // ── metric → display ──────────────────────────────────────────

  static double cmToIn(double cm) => cm / 2.54;
  static double kgToLb(double kg) => kg * 2.2046226218;
  static double inToCm(double inches) => inches * 2.54;
  static double lbToKg(double lb) => lb / 2.2046226218;

  /// Format a metric height (cm) for the current unit system.
  static String formatHeight(double? cm, {int decimals = 1}) {
    if (cm == null) return '';
    if (isImperial) {
      return cmToIn(cm).toStringAsFixed(decimals);
    }
    return _nice(cm);
  }

  static String formatWeight(double? kg, {int decimals = 1}) {
    if (kg == null) return '';
    if (isImperial) {
      return kgToLb(kg).toStringAsFixed(decimals);
    }
    return _nice(kg);
  }

  static String formatLength(double? cm, {int decimals = 1}) =>
      formatHeight(cm, decimals: decimals);

  static String _nice(double v) {
    if ((v - v.roundToDouble()).abs() < 0.05) return '${v.round()}';
    return v.toStringAsFixed(1);
  }

  /// Parse user input in current display units → metric cm.
  static double? parseHeightToCm(String raw) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (v == null) return null;
    final cm = isImperial ? inToCm(v) : v;
    if (cm < 50 || cm > 250) return null;
    return cm;
  }

  /// Parse user input → metric kg.
  static double? parseWeightToKg(String raw) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (v == null) return null;
    final kg = isImperial ? lbToKg(v) : v;
    if (kg < 20 || kg > 300) return null;
    return kg;
  }

  /// Waist: display length unit, store cm.
  static double? parseWaistToCm(String raw) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (v == null) return null;
    final cm = isImperial ? inToCm(v) : v;
    if (cm < 30 || cm > 200) return null;
    return cm;
  }
}
