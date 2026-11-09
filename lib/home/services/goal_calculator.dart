// lib/home/services/goal_calculator.dart
// Profile-aware activity targets and energy estimates.
// Coaching numbers for the app — not medical advice or lab-grade calorimetry.
import 'dart:math' as math;

import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/settings_store.dart';

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
    if (raw.isEmpty) return true;
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
    return (heightCm * factor / 100.0).clamp(0.45, 0.95);
  }

  // ---- steps goal ------------------------------------------------------

  static int stepsGoal() {
    try {
      final o = SettingsStore.stepsGoalOverride;
      if (o != null) return o;
    } catch (_) {}
    if (!isProfileComplete) return standardStepsGoal;

    const bases = [4000, 5500, 7500, 9500, 11000];
    var goal = bases[_activityIndex].toDouble();

    if (_age >= 65) {
      goal *= 0.88;
    } else if (_age >= 50) {
      goal *= 0.94;
    } else if (_age < 18) {
      goal *= 1.05;
    }

    final rounded = ((goal / 100).round() * 100);
    return rounded.clamp(2500, 15000);
  }

  // ---- calories --------------------------------------------------------

  /// MET for level walking by speed (km/h). Conservative band.
  static double metFromWalkingSpeedKmh(double speedKmh) {
    if (speedKmh < 2.0) return 2.0;
    if (speedKmh < 3.2) return 2.5;
    if (speedKmh < 4.0) return 3.0;
    if (speedKmh < 5.0) return 3.5;
    if (speedKmh < 6.0) return 4.3;
    return 5.0;
  }

  /// Energy for [steps] using body metrics.
  ///
  /// Prefers **distance × weight** (stable). MET path only applies when
  /// active minutes look consistent with steps (not inflated idle time).
  static double caloriesForSteps(int steps, {int? activeMinutes}) {
    if (steps <= 0) return 0.0;

    final w = weightKg;
    final stride = strideLengthMeters();
    final distKm = (steps * stride) / 1000.0;

    // Primary: distance-based (~0.5 kcal per kg per km — slightly conservative)
    final distanceKcal = distKm * w * 0.50;

    final minutes = activeMinutes;
    if (minutes != null && minutes >= 2 && distKm > 0) {
      // Reject impossible "long time / few steps" (timer noise).
      final maxReasonableMin = estimatedActiveMinutesFromSteps(steps);
      final usableMin = math.min(minutes, math.max(maxReasonableMin, 1));

      final hours = usableMin / 60.0;
      if (hours > 0) {
        final speed = distKm / hours;
        // Only trust MET when cadence is in a walking band.
        final stepsPerMin = steps / usableMin;
        if (stepsPerMin >= 60 && stepsPerMin <= 140 && speed >= 2.0 && speed <= 7.5) {
          final met = metFromWalkingSpeedKmh(speed);
          final metKcal = met * w * hours;
          // Blend toward distance estimate so time noise cannot explode kcal.
          return ((metKcal * 0.45) + (distanceKcal * 0.55)).clamp(0.0, 2000.0);
        }
      }
    }

    return distanceKcal.clamp(0.0, 2000.0);
  }

  static double kcalPerStep() => caloriesForSteps(1);

  static double caloriesGoal() {
    try {
      final o = SettingsStore.caloriesGoalOverride;
      if (o != null) return o;
    } catch (_) {}
    final steps = stepsGoal();
    final mins = activeMinutesGoal();
    final fromProfile = caloriesForSteps(steps, activeMinutes: mins);
    return fromProfile.clamp(150.0, 800.0);
  }

  // ---- active minutes --------------------------------------------------

  /// Implied walking minutes from step count (cadence ≈ 110–120 steps/min).
  static int estimatedActiveMinutesFromSteps(int steps) {
    if (steps <= 0) return 0;
    var cadence = 112.0;
    if (_age < 18) {
      cadence = 118.0;
    } else if (_age >= 65) {
      cadence = 100.0;
    }
    cadence += (_activityIndex - 2) * 2.5;
    cadence = cadence.clamp(100.0, 125.0);
    return (steps / cadence).floor().clamp(0, 24 * 60);
  }

  /// Sensor time capped by step-implied duration — never inflate above movement.
  static int reconcileActiveMinutes({
    required int sensorMinutes,
    required int steps,
  }) {
    final fromSteps = estimatedActiveMinutesFromSteps(steps);
    final s = sensorMinutes < 0 ? 0 : sensorMinutes;
    if (steps <= 0) return 0;
    if (s <= 0) {
      // No reliable sensor session: use a *reduced* step estimate only.
      return (fromSteps * 0.85).round().clamp(0, fromSteps);
    }
    // Cap sensor by step ceiling (cannot walk 30 min on 200 steps).
    final ceiling = math.max(fromSteps, (steps / 90).floor());
    return math.min(s, ceiling).clamp(0, 24 * 60);
  }

  static int activeMinutesGoal() {
    try {
      final o = SettingsStore.activeMinutesGoalOverride;
      if (o != null) return o;
    } catch (_) {}
    if (!isProfileComplete) return standardActiveMinutesGoal;

    const dailyWalkingMinutes = [15, 20, 30, 40, 45];
    final value = dailyWalkingMinutes[_activityIndex];

    if (_age >= 65) return (value * 0.85).round().clamp(15, 45);
    if (_age < 18) return (value * 1.05).round().clamp(15, 50);
    return value;
  }
}
