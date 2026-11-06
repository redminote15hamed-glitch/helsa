// lib/setting/storage/streak_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class StreakStore {
  StreakStore._();
  static const String boxName = 'helsa_streak';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('StreakStore.open() required');
    }
    return box;
  }

  static String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime _previousCalendarDay(DateTime date) =>
      DateTime(date.year, date.month, date.day - 1);

  static String get _today => _dayKey(DateTime.now());

  static bool get todayDone => _b.get('done_$_today') == true;

  static Future<void> markTodayDone() async {
    await _b.put('done_$_today', true);
    await _recompute();
  }

  static int get currentStreak {
    final value = _b.get('streak');
    return value is num ? value.toInt() : 0;
  }

  static Future<void> _recompute() async {
    var count = 0;
    var day = DateTime.now();

    // A streak remains active through the end of today; otherwise
    // continue counting from yesterday.
    if (_b.get('done_${_dayKey(day)}') != true) {
      day = _previousCalendarDay(day);
    }

    for (var index = 0; index < 365; index++) {
      if (_b.get('done_${_dayKey(day)}') != true) break;
      count++;
      day = _previousCalendarDay(day);
    }

    await _b.put('streak', count);
  }

  static Future<void> evaluate({
    required int steps,
    required int stepsGoal,
    required double calories,
    required double caloriesGoal,
    required int activeMinutes,
    required int activeMinutesGoal,
  }) async {
    final reachedAnyGoal =
        (stepsGoal > 0 && steps >= stepsGoal) ||
        (caloriesGoal > 0 && calories >= caloriesGoal) ||
        (activeMinutesGoal > 0 && activeMinutes >= activeMinutesGoal);

    if (reachedAnyGoal) {
      if (!todayDone) await markTodayDone();
      return;
    }

    // Recompute once per local day, not on every sensor event.
    final lastRecomputedDay = _b.get('last_recomputed_day')?.toString();
    if (lastRecomputedDay != _today) {
      await _recompute();
      await _b.put('last_recomputed_day', _today);
    }
  }

  static Future<void> clear() async {
    await _b.clear();
  }
}
