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
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('StepsStore.open() required');
    }
    return b;
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  /// قبل از ریست روز، خلاصهٔ روز قبلی را نگه می‌دارد (فقط آخرین روز)
  static void _ensureToday() {
    final today = _todayKey();
    final saved = _b.get('day')?.toString();
    if (saved != today) {
      if (saved != null && saved.isNotEmpty) {
        final prevSteps = _b.get('steps');
        final prevMs = _b.get('activeMs');
        final goal = _b.get('goal_steps');
        _b.put('last_day', saved);
        _b.put(
          'last_day_steps',
          prevSteps is num ? prevSteps.toInt() : 0,
        );
        _b.put(
          'last_day_active_ms',
          prevMs is num ? prevMs.toInt() : 0,
        );
        if (goal is num) {
          _b.put('last_day_goal_steps', goal.toInt());
        }
        // گزارش فقط یک‌بار تا وقتی کاربر ببیند
        _b.put('pending_recap', true);
      }
      _b.put('day', today);
      _b.put('steps', 0);
      _b.put('activeMinutes', 0);
      _b.put('baseDeviceSteps', null);
      _b.put('activeMs', 0);
    }
  }

  /// اگر گزارش دیده نشده باشد برمی‌گرداند و flag را پاک می‌کند
  static Map<String, dynamic>? consumePendingRecap() {
    _ensureToday();
    final pending = _b.get('pending_recap') == true;
    if (!pending) return null;
    final day = _b.get('last_day')?.toString();
    if (day == null || day.isEmpty) {
      _b.put('pending_recap', false);
      return null;
    }
    final steps = _b.get('last_day_steps');
    final ms = _b.get('last_day_active_ms');
    final goal = _b.get('last_day_goal_steps');
    _b.put('pending_recap', false);
    return {
      'day': day,
      'steps': steps is num ? steps.toInt() : 0,
      'activeMs': ms is num ? ms.toInt() : 0,
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

  /// آمار آخرین روز آرشیو شده (بدون مصرف recap)
  static int get lastDaySteps {
    final v = _b.get('last_day_steps');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static int? get lastDayGoalSteps {
    final v = _b.get('last_day_goal_steps');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static String? get lastDayKey {
    final v = _b.get('last_day')?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  static int get steps {
    _ensureToday();
    final v = _b.get('steps');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static int? get baseDeviceSteps {
    _ensureToday();
    final v = _b.get('baseDeviceSteps');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int get activeMs {
    _ensureToday();
    final v = _b.get('activeMs');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static int? get customStepsGoal {
    final v = _b.get('goal_steps');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int? get customCaloriesGoal {
    final v = _b.get('goal_calories');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static int? get customActiveGoal {
    final v = _b.get('goal_active');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static DateTime? get pauseUntil {
    final v = _b.get('pause_until');
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
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

  static Future<void> clearPause() async {
    await _b.delete('pause_until');
  }

  static Future<void> saveSteps(int steps) async {
    _ensureToday();
    await _b.put('steps', steps);
  }

  static Future<void> saveBaseDeviceSteps(int base) async {
    _ensureToday();
    await _b.put('baseDeviceSteps', base);
  }

  static Future<void> saveActiveMs(int ms) async {
    _ensureToday();
    await _b.put('activeMs', ms);
    await _b.put('activeMinutes', (ms / 60000).floor());
  }

  static Future<void> saveStepsGoal(int value) =>
      _b.put('goal_steps', value.clamp(100, 100000));

  static Future<void> saveCaloriesGoal(int value) =>
      _b.put('goal_calories', value.clamp(10, 10000));

  static Future<void> saveActiveGoal(int value) =>
      _b.put('goal_active', value.clamp(1, 600));
}
