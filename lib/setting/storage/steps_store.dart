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

  static void _ensureToday() {
    final today = _todayKey();
    final saved = _b.get('day')?.toString();
    if (saved != today) {
      _b.put('day', today);
      _b.put('steps', 0);
      _b.put('activeMinutes', 0);
      _b.put('baseDeviceSteps', null);
      _b.put('activeMs', 0);
    }
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

  // ── اهداف سفارشی (روزبه‌روز ریست نمی‌شوند) ──────────────
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
