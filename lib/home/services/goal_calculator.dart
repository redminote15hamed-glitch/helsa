// lib/home/services/goal_calculator.dart
// اهداف پیش‌فرض از پروفایل کاربر — فرمول‌های استاندارد
import 'dart:math' as math;
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';

/// محاسبه هدف روزانه قدم / کالری / زمان حرکت از داده Hive کاربر.
///
/// کالری پایه (BMR): Mifflin–St Jeor
/// TDEE: BMR × ضریب فعالیت
/// هدف کالری «حرکت»: بخشی از هزینه فعالیت روزانه
/// هدف قدم: بر اساس سطح فعالیت + تعدیل سن/جنسیت + هم‌خوانی با کالری
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

  /// 0..4 از استارت‌آپ
  static int get _activityIndex {
    final a = ActivityStore.activityLevel;
    if (a == null) return 1;
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

  /// Mifflin–St Jeor BMR (kcal/day)
  /// مرد: 10w + 6.25h − 5a + 5
  /// زن:  10w + 6.25h − 5a − 161
  static double bmr() {
    final base = 10 * _weight + 6.25 * _height - 5 * _age;
    return _isMale ? base + 5 : base - 161;
  }

  /// ضرایب فعالیت استاندارد (TDEE = BMR × factor)
  /// 0 نشسته … 4 خیلی فعال
  static double activityFactor() {
    const factors = [1.2, 1.375, 1.55, 1.725, 1.9];
    return factors[_activityIndex];
  }

  static double tdee() => bmr() * activityFactor();

  /// کالری هدف از «حرکت/قدم» در روز
  /// ≈ ۲۰٪ تا ۳۵٪ از (TDEE − BMR) بسته به سطح فعالیت
  /// کف و سقف معقول برای UI
  static double caloriesGoal() {
    final activityKcal = math.max(0.0, tdee() - bmr());
    const shares = [0.20, 0.25, 0.30, 0.35, 0.40];
    final target = activityKcal * shares[_activityIndex];
    // اگر پروفایل ناقص باشد، حداقل بر اساس وزن
    final fallback = _weight * 3.5; // ~kcal سبک روزانه
    final goal = math.max(target, fallback);
    return goal.clamp(120.0, 1200.0);
  }

  /// kcal تقریبی هر قدم (بر اساس وزن)
  /// قاعده رایج: ~0.04 kcal/step در 70kg → مقیاس با وزن
  static double kcalPerStep() => 0.04 * (_weight / 70.0);

  /// هدف قدم: از کالری هدف ÷ کالری هر قدم
  /// + تعدیل سن (بالای ۵۰ کمی کمتر، زیر ۲۵ کمی بیشتر)
  static int stepsGoal() {
    final fromCal = (caloriesGoal() / kcalPerStep()).round();

    // پایه جایگزین اگر محاسبه خیلی پرت بود
    const activityBase = [5000, 7000, 9000, 11000, 13000];
    final base = activityBase[_activityIndex];

    var goal = ((fromCal * 0.7) + (base * 0.3)).round();

    final age = _age;
    if (age >= 65) {
      goal = (goal * 0.85).round();
    } else if (age >= 50) {
      goal = (goal * 0.92).round();
    } else if (age < 25) {
      goal = (goal * 1.05).round();
    }

    // مردان حدود ۵٪ بیشتر (جرم عضلانی / عادت‌های مرجع)
    if (_isMale) goal = (goal * 1.05).round();

    return goal.clamp(3000, 20000);
  }

  /// دقایق فعال هدف — نزدیک توصیه WHO (~150 min/week متوسط)
  /// + سطح فعالیت کاربر
  static int activeMinutesGoal() {
    // پایه هفتگی معادل روزانه
    const dailyBase = [20, 25, 30, 40, 50];
    var m = dailyBase[_activityIndex];

    final age = _age;
    if (age >= 65) {
      m = (m * 0.9).round();
    } else if (age < 25) {
      m = (m * 1.05).round();
    }

    return m.clamp(15, 90);
  }
}
