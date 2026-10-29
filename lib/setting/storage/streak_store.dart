// lib/setting/storage/streak_store.dart
// Ø±ÙˆØ²Ù‡Ø§ÛŒÛŒ Ú©Ù‡ Ø­Ø¯Ø§Ù‚Ù„ ÛŒÚ© Ù‡Ø¯Ù (Ù‚Ø¯Ù…/Ú©Ø§Ù„Ø±ÛŒ/Ø²Ù…Ø§Ù†) Ú©Ø§Ù…Ù„ Ø´Ø¯Ù‡
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

  /// Ø§Ù…Ø±ÙˆØ² Ø­Ø¯Ø§Ù‚Ù„ ÛŒÚ© Ù‡Ø¯Ù Ø²Ø¯Ù‡ Ø´Ø¯Ù‡ØŸ
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
    // Ø§Ø² Ø§Ù…Ø±ÙˆØ² Ø¹Ù‚Ø¨ Ø¨Ø±Ùˆ ØªØ§ Ø²Ù†Ø¬ÛŒØ±Ù‡ Ù¾ÛŒÙˆØ³ØªÙ‡
    var count = 0;
    var day = DateTime.now();
    // Ø§Ú¯Ø± Ø§Ù…Ø±ÙˆØ² Ù‡Ù†ÙˆØ² done Ù†ÛŒØ³ØªØŒ Ø§Ø² Ø¯ÛŒØ±ÙˆØ² Ø´Ø±ÙˆØ¹ Ú©Ù† (Ø§Ø³ØªØ±ÛŒÚ© Ø²Ù†Ø¯Ù‡ Ù…ÛŒâ€ŒÙ…Ø§Ù†Ø¯ ØªØ§ Ø¢Ø®Ø± Ø±ÙˆØ²)
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

  /// Ø¨Ø¹Ø¯ Ø§Ø² ØªØºÛŒÛŒØ± Ù…ØªØ±ÛŒÚ©â€ŒÙ‡Ø§ ØµØ¯Ø§ Ø¨Ø²Ù†
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
      // ÙÙ‚Ø· recomput Ø¨Ø±Ø§ÛŒ Ù†Ù…Ø§ÛŒØ´Ø› Ø§Ù…Ø±ÙˆØ² Ø±Ø§ Ù¾Ø§Ú© Ù†Ú©Ù† Ø§Ú¯Ø± Ù‚Ø¨Ù„Ø§Ù‹ Ø²Ø¯Ù‡
      await _recompute();
    }
  }
}

