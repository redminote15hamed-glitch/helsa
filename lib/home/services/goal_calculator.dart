// lib/home/services/goal_calculator.dart
// Default daily goals from profile — conservative, evidence-aligned bands.
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';

/// Goals from Hive profile.
///
/// Steps: activity band (CDC / common coaching ranges), then age + BMI soft adjust.
/// Calories (movement): steps × kcal/step, kept in the *hundreds* (≤ 900).
/// Active minutes: ~WHO 150 min/week moderate, spread daily by activity.
class GoalCalculator {
  GoalCalculator._();

  static int get _age => AgeStore.age ?? 30;

  static double get _weight {
    final w = BodyStore.weight;
    if (w != null && w > 0) return w;
    return 65.0;
  }

  static double get _height {
    final h = BodyStore.height;
    if (h != null && h > 0) return h;
    return 165.0;
  }

  /// 0 sedentary … 4 very active (from setup)
  static int get _activityIndex {
    final a = ActivityStore.activityLevel;
    if (a == null) return 1;
    return a.clamp(0, 4);
  }

  static bool get _isMale {
    final g = (GenderStore.gender ?? '').toLowerCase().trim();
    return g == 'male' ||
        g == 'm' ||
        g == 'man' ||
        g == 'آقا' ||
        g == 'مرد' ||
        g.contains('male') ||
        g.contains('مرد') ||
        g.contains('آقا');
  }

  static double get _bmi {
    final m = _height / 100.0;
    if (m <= 0) return 22.0;
    return _weight / (m * m);
  }

  /// Mifflin–St Jeor (reference only; not shown as a goal by itself)
  static double bmr() {
    final base = 10 * _weight + 6.25 * _height - 5 * _age;
    return _isMale ? base + 5 : base - 161;
  }

  static double activityFactor() {
    const factors = [1.2, 1.375, 1.55, 1.725, 1.9];
    return factors[_activityIndex];
  }

  static double tdee() => bmr() * activityFactor();

  /// ~kcal burned per step (scales mildly with body weight).
  static double kcalPerStep() => 0.04 * (_weight / 70.0).clamp(0.75, 1.35);

  /// Step goal — lower bands for weak/sedentary profiles.
  ///
  /// Bands (daily):
  ///   0 sedentary ≈ 4 000 · 1 light ≈ 5 500 · 2 moderate ≈ 7 500
  ///   3 active ≈ 9 500 · 4 very active ≈ 11 500
  static int stepsGoal() {
    const band = [4000, 5500, 7500, 9500, 11500];
    double goal = band[_activityIndex].toDouble();

    // Age: older adults start lower (safer progression)
    final age = _age;
    if (age >= 65) {
      goal *= 0.78;
    } else if (age >= 55) {
      goal *= 0.85;
    } else if (age >= 45) {
      goal *= 0.92;
    } else if (age < 18) {
      goal *= 0.88;
    }

    // BMI: higher weight → slightly lower initial step target
    final bmi = _bmi;
    if (bmi >= 35) {
      goal *= 0.80;
    } else if (bmi >= 30) {
      goal *= 0.88;
    } else if (bmi >= 25) {
      goal *= 0.94;
    }

    // Very light body + sedentary stays gentle
    if (_activityIndex == 0 && _weight < 55) {
      goal *= 0.90;
    }

    // Sex: small offset only
    if (_isMale) {
      goal *= 1.03;
    } else {
      goal *= 0.97;
    }

    // Round to nearest 100 for clean UI
    var out = ((goal / 100).round() * 100);
    return out.clamp(2500, 15000);
  }

  /// Movement-calorie goal for the day — **hundreds only** (max 900).
  /// Derived from step goal × kcal/step, then rounded to 10s.
  static double caloriesGoal() {
    final fromSteps = stepsGoal() * kcalPerStep();

    // Cap: stay in hundreds (not 1000+)
    var goal = fromSteps.clamp(80.0, 900.0);

    // Round to nearest 10
    goal = (goal / 10).round() * 10.0;
    if (goal < 80) goal = 80;
    if (goal > 900) goal = 900;
    return goal;
  }

  /// Active minutes — daily share of ~150 min moderate / week.
  static int activeMinutesGoal() {
    const daily = [18, 22, 30, 40, 50];
    double m = daily[_activityIndex].toDouble();

    final age = _age;
    if (age >= 65) {
      m *= 0.85;
    } else if (age >= 50) {
      m *= 0.92;
    }

    final bmi = _bmi;
    if (bmi >= 30) m *= 0.90;

    return m.round().clamp(15, 75);
  }
}
