// lib/home/services/goal_calculator.dart
// اهداف شروعِ روزانه با اعداد رُند و افزایش تدریجی.
// این مقادیر تخمینی‌اند و جایگزین توصیه پزشکی یا ارزیابی فعالیت واقعی نیستند.
import 'dart:math' as math;
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';

/// محاسبه هدف‌های شروع روزانه بر اساس اطلاعات پروفایل.
///
/// نکته: سطح فعالیت انتخاب‌شده در شروع برنامه، اندازه‌گیری واقعی قدم‌های
/// فعلی کاربر نیست. بنابراین هدف‌ها عمداً محافظه‌کارانه و رُند هستند؛
/// بهتر است پس از جمع‌آوری چند هفته داده واقعی، هدف به‌تدریج تنظیم شود.
class GoalCalculator {
  GoalCalculator._();

  static int get _age => AgeStore.age ?? 30;

  static double get _weight {
    final w = BodyStore.weight;
    if (w != null && w > 0) return w;
    return 70.0;
  }

  static double get _height {
    final h = BodyStore.height;
    if (h != null && h > 0) return h;
    return 170.0;
  }

  /// سطح فعالیت انتخاب‌شده در راه‌اندازی، از ۰ تا ۴.
  static int get _activityIndex {
    final a = ActivityStore.activityLevel;
    if (a == null) return 0;
    return a.clamp(0, 4);
  }

  static bool get _isMale {
    final g = (GenderStore.gender ?? '').toLowerCase();
    return g == 'male' ||
        g == 'm' ||
        g == 'man' ||
        g == 'آقا' ||
        g == 'مرد' ||
        g.startsWith('m');
  }

  /// Mifflin–St Jeor برای بزرگسالان؛ تخمینی است و برای افراد زیر ۱۸ سال
  /// نباید به‌عنوان نیاز کالری دقیق یا توصیه غذایی استفاده شود.
  /// مرد: 10w + 6.25h − 5a + 5
  /// زن:  10w + 6.25h − 5a − 161
  static double bmr() {
    final base = 10 * _weight + 6.25 * _height - 5 * _age;
    return _isMale ? base + 5 : base - 161;
  }

  /// ضریب تخمینی فعالیت برای محاسبه انرژی روزانه بزرگسالان.
  static double activityFactor() {
    const factors = [1.2, 1.375, 1.55, 1.725, 1.9];
    return factors[_activityIndex];
  }

  static double tdee() => bmr() * activityFactor();

  /// گرد کردن به نزدیک‌ترین مضرب مشخص، برای جلوگیری از اعداد بی‌دلیل دقیق.
  static int _roundTo(int value, int step) {
    if (step <= 0) return value;
    return ((value / step).round()) * step;
  }

  /// هدف شروع قدم‌ها در روز.
  ///
  /// این مقادیر نسخه شروع هستند، نه حداقل یا حداکثر پزشکی:
  /// کم‌تحرک ۳۰۰۰، فعالیت خیلی سبک ۴۰۰۰، سبک ۶۰۰۰،
  /// متوسط ۸۰۰۰ و فعال ۱۰۰۰۰ قدم.
  ///
  /// عمداً ضریب اضافه بر اساس جنسیت یا جوان بودن اعمال نمی‌شود؛
  /// این عوامل به‌تنهایی دلیل کافی برای بالا بردن هدف قدم نیستند.
  static int stepsGoal() {
    const goals = [3000, 4000, 6000, 8000, 10000];
    return goals[_activityIndex];
  }

  /// کالری تقریبیِ مصرف‌شده از راه قدم‌زدن در هدف روزانه.
  ///
  /// برآورد کالری با وزن و تعداد قدم تغییر می‌کند و به‌دلیل تفاوت طول گام،
  /// سرعت و شرایط بدنی، فقط تخمینی است. خروجی به مضرب ۵۰ گرد می‌شود.
  /// این عدد «هدف دریافت کالری غذایی» نیست.
  static double caloriesGoal() {
    final estimated = stepsGoal() * kcalPerStep();
    final rounded = _roundTo(estimated.round(), 50);
    return rounded.clamp(50, 600).toDouble();
  }

  /// برآورد تقریبی انرژی هر قدم؛ مقدار واقعی می‌تواند متفاوت باشد.
  static double kcalPerStep() => 0.04 * (_weight / 70.0);

  /// هدف شروع دقایق فعالیت در روز، با افزایش تدریجی بر اساس سطح فعالیت.
  ///
  /// برای افراد زیر ۱۸ سال، هدف‌ها به‌صورت مرحله‌ای به ۶۰ دقیقه نزدیک
  /// می‌شوند؛ توصیه عمومی برای این گروه سنی حدود ۶۰ دقیقه فعالیت متوسط
  /// تا شدید در روز است، اما افزایش باید متناسب با توان و شرایط فرد باشد.
  /// برای بزرگسالان این اعداد هدف شروع‌اند، نه جایگزین توصیه هفتگی WHO.
  static int activeMinutesGoal() {
    if (_age < 18) {
      const youthGoals = [20, 30, 40, 50, 60];
      return youthGoals[_activityIndex];
    }

    const adultGoals = [15, 20, 30, 40, 50];
    return adultGoals[_activityIndex];
  }
}
