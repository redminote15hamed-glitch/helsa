// lib/setting/storage/steps_store.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/setting/storage/secure_hive.dart';
import 'package:helsa/setting/storage/settings_store.dart';

class StepsStore {
  StepsStore._();
  static const String boxName = 'helsa_steps_daily';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await SecureHive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('StepsStore.open() required');
    }
    return box;
  }

  static String _todayKey() {
    final now = DateTime.now();
    var day = now;
    try {
      final resetH = SettingsStore.dayResetHour;
      if (resetH > 0 && now.hour < resetH) {
        day = now.subtract(const Duration(days: 1));
      }
    } catch (_) {}
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  /// Ensures daily values belong to the current local calendar day.
  /// The previous day's recap is archived exactly once before resetting.
  static void _ensureToday({int? liveSteps, int? liveActiveMs}) {
    final today = _todayKey();
    final savedDay = _b.get('day')?.toString();

    if (savedDay == today) return;

    if (savedDay != null && savedDay.isNotEmpty) {
      final previousSteps = _b.get('steps');
      final previousActiveMs = _b.get('activeMs');
      final previousGoal = _b.get('goal_steps');

      _b.put('last_day', savedDay);
      _b.put(
        'last_day_steps',
        liveSteps ?? (previousSteps is num ? previousSteps.toInt() : 0),
      );
      _b.put(
        'last_day_active_ms',
        liveActiveMs ??
            (previousActiveMs is num ? previousActiveMs.toInt() : 0),
      );
      if (previousGoal is num) {
        _b.put('last_day_goal_steps', previousGoal.toInt());
      }
      _b.put('pending_recap', true);
    }

    _b.put('day', today);
    _b.put('steps', 0);
    _b.put('activeMinutes', 0);
    _b.put('baseDeviceSteps', null);
    _b.put('activeMs', 0);
  }

  /// Rolls over using the tracker's latest in-memory totals, avoiding loss
  /// of the final debounced steps or active-time seconds at midnight.
  static String rolloverWithCurrentValues({
    required int steps,
    required int activeMs,
  }) {
    _ensureToday(liveSteps: steps, liveActiveMs: activeMs);
    return _todayKey();
  }

  static String get currentDayKey {
    _ensureToday();
    return _todayKey();
  }

  static Map<String, dynamic>? consumePendingRecap() {
    _ensureToday();
    if (_b.get('pending_recap') != true) return null;

    final day = _b.get('last_day')?.toString();
    if (day == null || day.isEmpty) {
      _b.put('pending_recap', false);
      return null;
    }

    final steps = _b.get('last_day_steps');
    final activeMs = _b.get('last_day_active_ms');
    final goal = _b.get('last_day_goal_steps');
    _b.put('pending_recap', false);

    return {
      'day': day,
      'steps': steps is num ? steps.toInt() : 0,
      'activeMs': activeMs is num ? activeMs.toInt() : 0,
      'goalSteps': goal is num ? goal.toInt() : null,
    };
  }

  static bool get hasPendingRecap {
    try {
      _ensureToday();
      return _b.get('pending_recap') == true;
    } catch (_) {
      return false;
    }
  }

  static int get lastDaySteps {
    final value = _b.get('last_day_steps');
    return value is num ? value.toInt() : 0;
  }

  static int? get lastDayGoalSteps {
    final value = _b.get('last_day_goal_steps');
    return value is num ? value.toInt() : null;
  }

  static String? get lastDayKey {
    final value = _b.get('last_day')?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  static int get steps {
    _ensureToday();
    final value = _b.get('steps');
    return value is num ? value.toInt() : 0;
  }

  static int? get baseDeviceSteps {
    _ensureToday();
    final value = _b.get('baseDeviceSteps');
    return value is num ? value.toInt() : null;
  }

  static int get activeMs {
    _ensureToday();
    final value = _b.get('activeMs');
    return value is num ? value.toInt() : 0;
  }

  static int? get customStepsGoal {
    final value = _b.get('goal_steps');
    return value is num ? value.toInt() : null;
  }

  static int? get customCaloriesGoal {
    final value = _b.get('goal_calories');
    return value is num ? value.toInt() : null;
  }

  static int? get customActiveGoal {
    final value = _b.get('goal_active');
    return value is num ? value.toInt() : null;
  }

  /// Clears all step history, custom goals, and legacy pause data.
  static Future<void> clear() async {
    await _b.clear();
  }

  /// Persist the live counter and sensor offset in one Hive write batch.
  static Future<void> saveTrackerState({
    required int steps,
    required int baseDeviceSteps,
  }) async {
    _ensureToday();
    await _b.putAll({
      'steps': steps < 0 ? 0 : steps,
      'baseDeviceSteps': baseDeviceSteps,
    });
  }

  static Future<void> saveSteps(int value) async {
    _ensureToday();
    await _b.put('steps', value < 0 ? 0 : value);
  }

  static Future<void> saveBaseDeviceSteps(int value) async {
    _ensureToday();
    // Negative offsets are valid after the hardware counter resets on reboot.
    await _b.put('baseDeviceSteps', value);
  }

  static Future<void> saveActiveMs(int value) async {
    _ensureToday();
    final safeValue = value < 0 ? 0 : value;
    await _b.putAll({
      'activeMs': safeValue,
      'activeMinutes': (safeValue / 60000).floor(),
    });
  }

  static Future<void> saveStepsGoal(int value) =>
      _b.put('goal_steps', value.clamp(100, 100000));

  static Future<void> saveCaloriesGoal(int value) =>
      _b.put('goal_calories', value.clamp(10, 10000));

  static Future<void> saveActiveGoal(int value) =>
      _b.put('goal_active', value.clamp(1, 600));
}
