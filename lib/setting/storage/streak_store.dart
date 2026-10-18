// lib/setting/storage/streak_store.dart
// روزهایی که حداقل یک هدف (قدم/کالری/زمان) کامل شده
import 'package:hive_flutter/hive_flutter.dart';

class StreakStore {
  StreakStore._();
  static const String boxName = 'helsa_streak';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('StreakStore.open() required');
    }
    return b;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String get _today => _dayKey(DateTime.now());

  static String get _yesterday {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return _dayKey(y);
  }

  /// امروز حداقل یک هدف زده شده؟
  static bool get todayDone => _b.get('done_$_today') == true;

  static Future<void> markTodayDone() async {
    await _b.put('done_$_today', true);
    await _recompute();
  }

  static int get currentStreak {
    final v = _b.get('streak');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static Future<void> _recompute() async {
    // از امروز عقب برو تا زنجیره پیوسته
    var count = 0;
    var day = DateTime.now();
    // اگر امروز هنوز done نیست، از دیروز شروع کن (استریک زنده می‌ماند تا آخر روز)
    if (_b.get('done_${_dayKey(day)}') != true) {
      day = day.subtract(const Duration(days: 1));
    }
    for (int i = 0; i < 365; i++) {
      final key = 'done_${_dayKey(day)}';
      if (_b.get(key) == true) {
        count++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    await _b.put('streak', count);
  }

  /// بعد از تغییر متریک‌ها صدا بزن
  static Future<void> evaluate({
    required int steps,
    required int stepsGoal,
    required double calories,
    required double caloriesGoal,
    required int activeMinutes,
    required int activeMinutesGoal,
  }) async {
    final hit = (stepsGoal > 0 && steps >= stepsGoal) ||
        (caloriesGoal > 0 && calories >= caloriesGoal) ||
        (activeMinutesGoal > 0 && activeMinutes >= activeMinutesGoal);
    if (hit) {
      await markTodayDone();
    } else {
      // فقط recomput برای نمایش؛ امروز را پاک نکن اگر قبلاً زده
      await _recompute();
    }
  }
}
