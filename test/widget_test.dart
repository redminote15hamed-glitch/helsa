import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/home/services/goal_calculator.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/setting/storage/streak_store.dart';

void main() {
  late Directory testDirectory;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('helsa_tests_');
    Hive.init(testDirectory.path);
    await AgeStore.open();
    await ActivityStore.open();
    await StepsStore.open();
    await StreakStore.open();
  });

  tearDownAll(() async {
    await Hive.close();
    await testDirectory.delete(recursive: true);
  });

  setUp(() async {
    await AgeStore.save(14);
    await ActivityStore.save(2);
    await StepsStore.clearPause();
    await StreakStore.clear();
  });

  test('teen step goals depend on activity band, not body measurements', () async {
    const expected = [5000, 6000, 7000, 8000, 9000];

    for (var activity = 0; activity < expected.length; activity++) {
      await ActivityStore.save(activity);
      expect(GoalCalculator.stepsGoal(), expected[activity]);
    }
  });

  test('movement calorie estimate and target stay independent of body weight', () async {
    await AgeStore.save(14);
    await ActivityStore.save(4);

    expect(GoalCalculator.kcalPerStep(), 0.04);
    expect(GoalCalculator.caloriesGoal(), 300.0);
  });

  test('missing profile inputs use neutral defaults', () async {
    await AgeStore.save(null);
    await ActivityStore.save(null);

    expect(GoalCalculator.stepsGoal(), GoalCalculator.standardStepsGoal);
    expect(
      GoalCalculator.activeMinutesGoal(),
      GoalCalculator.standardActiveMinutesGoal,
    );
  });

  test('daily rollover archives yesterday before resetting counters', () async {
    final box = Hive.box(StepsStore.boxName);
    await box.put('day', '2026-11-05');
    await box.put('steps', 4321);
    await box.put('activeMs', 120000);
    await box.put('goal_steps', 7000);

    expect(StepsStore.steps, 0);
    expect(StepsStore.lastDayKey, '2026-11-05');
    expect(StepsStore.lastDaySteps, 4321);
    expect(StepsStore.activeMs, 0);
  });

  test('negative sensor offset is retained after a device reboot', () async {
    await StepsStore.saveBaseDeviceSteps(-1800);
    expect(StepsStore.baseDeviceSteps, -1800);
  });

  test('streak storage opens and records a completed goal', () async {
    await StreakStore.evaluate(
      steps: 7000,
      stepsGoal: 7000,
      calories: 0,
      caloriesGoal: 300,
      activeMinutes: 0,
      activeMinutesGoal: 30,
    );

    expect(StreakStore.todayDone, isTrue);
    expect(StreakStore.currentStreak, greaterThanOrEqualTo(1));
  });
}
