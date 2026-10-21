// lib/home/widgets/ghost_progress.dart
// سایهٔ دیروز روی سیب قدم — رقابت با خودِ دیروز
import 'package:helsa/setting/storage/steps_store.dart';

class GhostProgress {
  GhostProgress._();

  /// 0..1 از هدف قدم آخرین روز آرشیو شده
  static double yesterdayStepsProgress({int? fallbackGoal}) {
    try {
      final steps = StepsStore.lastDaySteps;
      if (steps <= 0) return 0;
      final goal = StepsStore.lastDayGoalSteps ?? fallbackGoal ?? 8000;
      if (goal <= 0) return 0;
      return (steps / goal).clamp(0.0, 1.0);
    } catch (_) {
      return 0;
    }
  }
}
