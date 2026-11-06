// lib/home/services/goal_calculator.dart
// Conservative app activity goals. These are coaching targets, not medical advice.
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';

class GoalCalculator {
  GoalCalculator._();

  static const int standardStepsGoal = 7500;
  static const double standardCaloriesGoal = 300.0;
  static const int standardActiveMinutesGoal = 30;

  static int get _age => AgeStore.age ?? 30;

  /// Activity goals need age and activity level only.
  /// Height, weight and gender are deliberately not used to grade activity.
  static bool get isProfileComplete {
    final age = AgeStore.age;
    final activity = ActivityStore.activityLevel;
    return age != null &&
        age >= 6 &&
        age <= 120 &&
        activity != null &&
        activity >= 0 &&
        activity <= 4;
  }

  /// 0 sedentary … 4 very active (from setup).
  static int get _activityIndex {
    final value = ActivityStore.activityLevel;
    if (value == null) return 1;
    return value.clamp(0, 4).toInt();
  }

  /// Step goals are app-level targets, not a diagnostic or a required minimum.
  /// For users under 18, no BMI, body-weight or sex adjustment is applied.
  static int stepsGoal() {
    if (!isProfileComplete) return standardStepsGoal;

    const childAndTeenBands = [5000, 6000, 7000, 8000, 9000];
    const adultBands = [4000, 5500, 7500, 9500, 11000];

    final bands = _age < 18 ? childAndTeenBands : adultBands;
    return bands[_activityIndex].clamp(3000, 12000).toInt();
  }

  /// A rough movement-energy estimate per step.
  /// It is not an estimate of food intake or an individual energy requirement.
  static double kcalPerStep() => 0.04;

  /// Keep the existing activity-card target stable instead of deriving a
  /// calorie target from body weight or treating it as a nutritional goal.
  static double caloriesGoal() => standardCaloriesGoal;

  /// Duration target for detected walking. It is an app activity target,
  /// not a substitute for measuring moderate-to-vigorous activity intensity.
  static int activeMinutesGoal() {
    if (!isProfileComplete) return standardActiveMinutesGoal;

    const dailyWalkingMinutes = [15, 20, 30, 40, 45];
    final value = dailyWalkingMinutes[_activityIndex];

    if (_age >= 65) return (value * 0.85).round().clamp(15, 45).toInt();
    return value;
  }
}
