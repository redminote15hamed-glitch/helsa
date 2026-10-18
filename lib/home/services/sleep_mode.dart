// lib/home/services/sleep_mode.dart
// آیا الان در بازه خواب کاربر هستیم؟ (sleep → wake، ممکن است از نیمه‌شب رد شود)
import 'package:helsa/setting/storage/sleep_store.dart';

class SleepMode {
  SleepMode._();

  /// "23:30" / "11:30 PM" / "23:30:00" → دقیقه از نیمه‌شب
  static int? _toMinutes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var s = raw.trim().toLowerCase();
    var pm = false;
    var am = false;
    if (s.contains('pm')) {
      pm = true;
      s = s.replaceAll('pm', '').trim();
    } else if (s.contains('am')) {
      am = true;
      s = s.replaceAll('am', '').trim();
    }
    final parts = s.split(RegExp(r'[:\.]'));
    if (parts.isEmpty) return null;
    final h0 = int.tryParse(parts[0].trim());
    final m0 = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    if (h0 == null) return null;
    var h = h0;
    if (pm && h < 12) h += 12;
    if (am && h == 12) h = 0;
    if (h > 23 || m0 > 59) return null;
    return h * 60 + m0;
  }

  /// true اگر الان بین sleepTime و wakeTime باشد
  static bool get isNightNow {
    try {
      final sleep = _toMinutes(SleepStore.sleepTime);
      final wake = _toMinutes(SleepStore.wakeTime);
      if (sleep == null || wake == null) return false;

      final n = DateTime.now();
      final now = n.hour * 60 + n.minute;

      if (sleep == wake) return false;

      // مثال: 23:00 → 07:00  یا  22:00 → 06:30
      if (sleep > wake) {
        // عبور از نیمه‌شب
        return now >= sleep || now < wake;
      }
      // همان روز: مثلاً 01:00 → 08:00 (نادر)
      return now >= sleep && now < wake;
    } catch (_) {
      return false;
    }
  }
}
