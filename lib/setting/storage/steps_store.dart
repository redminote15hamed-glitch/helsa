// lib/setting/storage/steps_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class StepsStore {
  StepsStore._();
  static const String boxName = 'helsa_steps_daily';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
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
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Ensures daily values belong to the current local calendar day.
  /// The previous day's recap is archived exactly once before resetting.
  static void _ensureToday() {
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
        previousSteps is num ? previousSteps.toInt() : 0,
      );
      _b.put(
        'last_day_active_ms',
        previousActiveMs is num ? previousActiveMs.toInt() : 0,
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

  static DateTime? get pauseUntil {
    final value = _b.get('pause_until');
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static bool get isCountingPaused {
    final until = pauseUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _b.delete('pause_until');
      return false;
    }
    return true;
  }

  static Future<void> setPauseForOneHour() async {
    final until = DateTime.now().add(const Duration(hours: 1));
    await _b.put('pause_until', until.millisecondsSinceEpoch);
  }

  static Future<void> clearPause() => _b.delete('pause_until');

  static Future<void> saveSteps(int value) async {
    _ensureToday();
    await _b.put('steps', value < 0 ? 0 : value);
  }

  static Future<void> saveBaseDeviceSteps(int value) async {
    _ensureToday();
    await _b.put('baseDeviceSteps', value < 0 ? 0 : value);
  }

  static Future<void> saveActiveMs(int value) async {
    _ensureToday();
    final safeValue = value < 0 ? 0 : value;
    await _b.put('activeMs', safeValue);
    await _b.put('activeMinutes', (safeValue / 60000).floor());
  }

  static Future<void> saveStepsGoal(int value) =>
      _b.put('goal_steps', value.clamp(100, 100000));

  static Future<void> saveCaloriesGoal(int value) =>
      _b.put('goal_calories', value.clamp(10, 10000));

  static Future<void> saveActiveGoal(int value) =>
      _b.put('goal_active', value.clamp(1, 600));
}
