// lib/setting/storage/settings_store.dart
// User preferences that belong only in Settings (not profile / privacy).
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/setting/storage/secure_hive.dart';

class SettingsStore {
  SettingsStore._();

  static const String boxName = 'helsa_settings';
  static Box<dynamic>? _box;

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> open() async {
    _box ??= await SecureHive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('SettingsStore.open() required');
    }
    return b;
  }

  static void _bump() => revision.value++;

  // ── Activity goals (null / missing = auto from GoalCalculator) ──

  static int? get stepsGoalOverride {
    final v = _b.get('stepsGoal');
    if (v is int && v > 0) return v.clamp(1000, 30000);
    if (v is num && v > 0) return v.toInt().clamp(1000, 30000);
    return null;
  }

  static double? get caloriesGoalOverride {
    final v = _b.get('caloriesGoal');
    if (v is num && v > 0) return v.toDouble().clamp(50.0, 2000.0);
    return null;
  }

  static int? get activeMinutesGoalOverride {
    final v = _b.get('activeMinutesGoal');
    if (v is int && v > 0) return v.clamp(5, 300);
    if (v is num && v > 0) return v.toInt().clamp(5, 300);
    return null;
  }

  static Future<void> setStepsGoalOverride(int? value) async {
    if (value == null || value <= 0) {
      await _b.delete('stepsGoal');
    } else {
      await _b.put('stepsGoal', value.clamp(1000, 30000));
    }
    _bump();
  }

  static Future<void> setCaloriesGoalOverride(double? value) async {
    if (value == null || value <= 0) {
      await _b.delete('caloriesGoal');
    } else {
      await _b.put('caloriesGoal', value.clamp(50.0, 2000.0));
    }
    _bump();
  }

  static Future<void> setActiveMinutesGoalOverride(int? value) async {
    if (value == null || value <= 0) {
      await _b.delete('activeMinutesGoal');
    } else {
      await _b.put('activeMinutesGoal', value.clamp(5, 300));
    }
    _bump();
  }

  // ── Notification (content of the required FG notification only) ──
  /// When false: static quiet title, no live step numbers in the shade.
  static bool get liveStepNotification {
    return _b.get('liveStepNotification', defaultValue: true) == true;
  }

  static Future<void> setLiveStepNotification(bool value) async {
    await _b.put('liveStepNotification', value);
    _bump();
  }

  /// Quiet hours: while enabled, treat like liveStepNotification=false.
  static bool get quietHoursEnabled {
    return _b.get('quietHoursEnabled', defaultValue: false) == true;
  }

  static int get quietHoursStart {
    final v = _b.get('quietHoursStart');
    if (v is int) return v.clamp(0, 23);
    if (v is num) return v.toInt().clamp(0, 23);
    return 22;
  }

  static int get quietHoursEnd {
    final v = _b.get('quietHoursEnd');
    if (v is int) return v.clamp(0, 23);
    if (v is num) return v.toInt().clamp(0, 23);
    return 7;
  }

  static Future<void> setQuietHours({
    required bool enabled,
    int? startHour,
    int? endHour,
  }) async {
    await _b.put('quietHoursEnabled', enabled);
    if (startHour != null) await _b.put('quietHoursStart', startHour.clamp(0, 23));
    if (endHour != null) await _b.put('quietHoursEnd', endHour.clamp(0, 23));
    _bump();
  }

  /// Whether the notification should show live step numbers right now.
  static bool get shouldShowLiveSteps {
    if (!liveStepNotification) return false;
    if (!quietHoursEnabled) return true;
    final h = DateTime.now().hour;
    final a = quietHoursStart;
    final b = quietHoursEnd;
    if (a == b) return true;
    // Quiet if in [a, b) wrapping midnight
    if (a < b) {
      return h < a || h >= b;
    }
    return h >= b && h < a;
  }

  // ── Day reset hour (0 = midnight calendar day) ──
  static int get dayResetHour {
    final v = _b.get('dayResetHour');
    if (v is int) return v.clamp(0, 23);
    if (v is num) return v.toInt().clamp(0, 23);
    return 0;
  }

  static Future<void> setDayResetHour(int hour) async {
    await _b.put('dayResetHour', hour.clamp(0, 23));
    _bump();
  }

  // ── Haptics ──
  static bool get hapticsEnabled {
    return _b.get('hapticsEnabled', defaultValue: true) == true;
  }

  static Future<void> setHapticsEnabled(bool value) async {
    await _b.put('hapticsEnabled', value);
    _bump();
  }

  // ── Motion ──
  /// Stored as: calm | medium | fast  (default medium)
  static String get animationSpeedKey {
    final raw = (_b.get('animationSpeed')?.toString() ?? 'medium').toLowerCase();
    if (raw == 'calm' || raw == 'slow') return 'calm';
    if (raw == 'fast') return 'fast';
    return 'medium';
  }

  static Future<void> setAnimationSpeedKey(String key) async {
    final k = key.toLowerCase();
    final normalized =
        (k == 'calm' || k == 'slow') ? 'calm' : (k == 'fast' ? 'fast' : 'medium');
    await _b.put('animationSpeed', normalized);
    _bump();
  }

  /// Simplified motion: fade instead of multi-phase expand, no liquid wave, etc.
  static bool get simpleMotion {
    return _b.get('simpleMotion', defaultValue: false) == true;
  }

  static Future<void> setSimpleMotion(bool value) async {
    await _b.put('simpleMotion', value);
    _bump();
  }

  // ── Units: metric (cm/kg) | imperial (in/lb) ──
  /// Always store body metrics in metric; this only affects display & input.
  static String get unitsKey {
    final raw = (_b.get('units')?.toString() ?? 'metric').toLowerCase();
    return raw == 'imperial' ? 'imperial' : 'metric';
  }

  static Future<void> setUnitsKey(String key) async {
    final k = key.toLowerCase() == 'imperial' ? 'imperial' : 'metric';
    await _b.put('units', k);
    _bump();
  }

  // ── Backup metadata ──
  static String? get lastBackupAt {
    final v = _b.get('lastBackupAt')?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setLastBackupAt(String? iso) async {
    if (iso == null || iso.isEmpty) {
      await _b.delete('lastBackupAt');
    } else {
      await _b.put('lastBackupAt', iso);
    }
    _bump();
  }

  static String? get googleBackupEmail {
    final v = _b.get('googleBackupEmail')?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setGoogleBackupEmail(String? email) async {
    if (email == null || email.isEmpty) {
      await _b.delete('googleBackupEmail');
    } else {
      await _b.put('googleBackupEmail', email);
    }
    _bump();
  }

  /// Preferred Gmail typed by user (hint for Google account picker).
  static String? get preferredGoogleEmail {
    final v = _b.get('preferredGoogleEmail')?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setPreferredGoogleEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      await _b.delete('preferredGoogleEmail');
    } else {
      await _b.put('preferredGoogleEmail', email.trim().toLowerCase());
    }
    _bump();
  }

  /// When true, encrypted Drive backup runs once per day after day rollover.
  static bool get autoSyncEnabled {
    return _b.get('autoSyncEnabled', defaultValue: false) == true;
  }

  static Future<void> setAutoSyncEnabled(bool value) async {
    await _b.put('autoSyncEnabled', value);
    _bump();
  }

  /// Local calendar day key of last successful auto-sync.
  static String? get lastAutoSyncDayKey {
    final v = _b.get('lastAutoSyncDayKey')?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static Future<void> setLastAutoSyncDayKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _b.delete('lastAutoSyncDayKey');
    } else {
      await _b.put('lastAutoSyncDayKey', key);
    }
    _bump();
  }

  static Future<void> clear() => _b.clear();
}
