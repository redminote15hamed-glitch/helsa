// lib/home/services/goal_calculator.dart
// Profile-aware activity targets and energy estimates.
// Coaching numbers for the app — not medical advice or lab-grade calorimetry.
import 'dart:math' as math;

import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';

class GoalCalculator {
  GoalCalculator._();

  static const int standardStepsGoal = 7500;
  static const double standardCaloriesGoal = 300.0;
  static const int standardActiveMinutesGoal = 30;

  // ---- profile helpers -------------------------------------------------

  static int get _age => AgeStore.age ?? 30;

  static int get _activityIndex {
    final value = ActivityStore.activityLevel;
    if (value == null) return 1;
    return value.clamp(0, 4).toInt();
  }

  /// True when age + activity are set (enough for step / active goals).
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

  /// Body data improves calorie accuracy; missing values fall back to averages.
  static bool get hasBodyMetrics {
    final w = BodyStore.weight;
    final h = BodyStore.height;
    return w != null && w >= 25 && w <= 300 && h != null && h >= 80 && h <= 250;
  }

  static bool get isMale {
    final raw = (GenderStore.gender ?? '').trim().toLowerCase();
    if (raw.isEmpty) return true; // neutral default for stride tables
    if (raw.startsWith('f') ||
        raw.contains('female') ||
        raw.contains('زن') ||
        raw.contains('خانم')) {
      return false;
    }
    if (raw.startsWith('m') ||
        raw.contains('male') ||
        raw.contains('مرد') ||
        raw.contains('آقا')) {
      return true;
    }
    return true;
  }

  static double get weightKg {
    final w = BodyStore.weight;
    if (w != null && w >= 25 && w <= 300) return w;
    // Population-ish defaults by sex when weight not entered
    return isMale ? 75.0 : 65.0;
  }

  static double get heightCm {
    final h = BodyStore.height;
    if (h != null && h >= 80 && h <= 250) return h;
    return isMale ? 175.0 : 162.0;
  }

  /// Walking stride length (meters) from height × sex factor.
  static double strideLengthMeters() {
    final factor = isMale ? 0.415 : 0.413;
    return (heightCm * factor) / 100.0;
  }

  // ---- steps goal ------------------------------------------------------

  static int stepsGoal() {
    if (!isProfileComplete) return standardStepsGoal;

    const childAndTeenBands = [5000, 6000, 7000, 8000, 9000];
    const adultBands = [4000, 5500, 7500, 9500, 11000];

    final bands = _age < 18 ? childAndTeenBands : adultBands;
    return bands[_activityIndex].clamp(3000, 12000).toInt();
  }

  // ---- calories (distance + optional intensity from active time) --------

  /// MET for level walking by estimated speed (km/h). Compendium-inspired bands.
  static double metFromWalkingSpeedKmh(double kmh) {
    if (kmh <= 0) return 2.5;
    if (kmh < 3.2) return 2.0; // very slow
    if (kmh < 4.0) return 2.8;
    if (kmh < 4.8) return 3.5; // moderate
    if (kmh < 5.6) return 4.3;
    if (kmh < 6.4) return 5.0; // brisk
    if (kmh < 8.0) return 6.5; // jog transition
    return 8.0;
  }

  /// Energy for [steps], optionally refined with measured active minutes.
  static double caloriesForSteps(int steps, {int? activeMinutes}) {
    final safeSteps = steps < 0 ? 0 : steps;
    if (safeSteps == 0) return 0;

    final w = weightKg;
    final distKm = safeSteps * strideLengthMeters() / 1000.0;

    final minutes = activeMinutes;
    if (minutes != null && minutes > 0 && distKm > 0) {
      final hours = minutes / 60.0;
      final speed = distKm / hours;
      final met = metFromWalkingSpeedKmh(speed);
      // kcal ≈ MET × body mass (kg) × hours
      return (met * w * hours).clamp(0.0, 2500.0);
    }

    // Distance-only fallback (~0.57 kcal per kg per km for level walking)
    return (distKm * w * 0.57).clamp(0.0, 2500.0);
  }

  /// Backward-compatible average kcal/step (for simple displays).
  static double kcalPerStep() {
    // One step at current body profile, no active-time intensity.
    return caloriesForSteps(1);
  }

  /// Daily calorie movement target from step goal + body profile.
  static double caloriesGoal() {
    final steps = stepsGoal();
    // Assume moderate pace (~3.5 MET equivalent via typical active-minute goal).
    final mins = activeMinutesGoal();
    final fromProfile = caloriesForSteps(steps, activeMinutes: mins);
    return fromProfile.clamp(150.0, 900.0);
  }

  // ---- active minutes --------------------------------------------------

  /// Implied walking minutes from step count (cadence ≈ 110 steps/min).
  static int estimatedActiveMinutesFromSteps(int steps) {
    if (steps <= 0) return 0;
    // Cadence rises slightly for younger / more active users.
    var cadence = 110.0;
    if (_age < 18) {
      cadence = 115.0;
    } else if (_age >= 65) {
      cadence = 100.0;
    }
    cadence += (_activityIndex - 2) * 3.0; // sedentary slower, very active faster
    cadence = cadence.clamp(95.0, 125.0);
    return (steps / cadence).floor().clamp(0, 24 * 60);
  }

  /// Combine sensor walking time with step-implied time (never under-count movement).
  static int reconcileActiveMinutes({
    required int sensorMinutes,
    required int steps,
  }) {
    final fromSteps = estimatedActiveMinutesFromSteps(steps);
    final s = sensorMinutes < 0 ? 0 : sensorMinutes;
    if (s <= 0) return fromSteps;
    if (fromSteps <= 0) return s;
    // Sensor is primary; step estimate floors a lower bound (75%).
    final floorFromSteps = (fromSteps * 0.75).round();
    return math.max(s, floorFromSteps);
  }

  static int activeMinutesGoal() {
    if (!isProfileComplete) return standardActiveMinutesGoal;

    const dailyWalkingMinutes = [15, 20, 30, 40, 45];
    final value = dailyWalkingMinutes[_activityIndex];

    if (_age >= 65) return (value * 0.85).round().clamp(15, 45);
    if (_age < 18) return (value * 1.05).round().clamp(15, 50);
    return value;
  }
}
