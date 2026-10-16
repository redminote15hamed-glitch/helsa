// lib/home/services/step_tracker.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';

/// Real step / calorie / active-time tracker.
class StepTracker extends ChangeNotifier {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _steps = 0;
  int _baseSteps = 0; // device counter at start of day / session
  bool _hasBase = false;
  bool _isWalking = false;
  bool _permissionGranted = false;
  bool _paused = false;

  DateTime? _walkStartedAt;
  Duration _activeAccumulated = Duration.zero;
  Timer? _tick;

  int get steps => _steps;
  bool get isWalking => _isWalking && !_paused;
  bool get permissionGranted => _permissionGranted;
  bool get isPaused => _paused;

  int get stepsGoal {
    // simple goal from activity level
    final level = ActivityStore.activityLevel ?? 1;
    const goals = [5000, 6500, 8000, 10000, 12000];
    return goals[level.clamp(0, goals.length - 1)];
  }

  double get calories {
    // rough: 0.04 kcal per step adjusted by weight
    final w = BodyStore.weight ?? 70.0;
    return _steps * 0.04 * (w / 70.0);
  }

  double get caloriesGoal {
    final level = ActivityStore.activityLevel ?? 1;
    const goals = [150.0, 220.0, 300.0, 400.0, 500.0];
    return goals[level.clamp(0, goals.length - 1)];
  }

  int get activeMinutes => _activeAccumulated.inMinutes +
      (_walkStartedAt != null && !_paused
          ? DateTime.now().difference(_walkStartedAt!).inMinutes
          : 0);

  int get activeMinutesGoal {
    final level = ActivityStore.activityLevel ?? 1;
    const goals = [20, 25, 30, 45, 60];
    return goals[level.clamp(0, goals.length - 1)];
  }

  String get activeTimeLabel {
    final m = activeMinutes;
    return '$m';
  }

  Future<void> init() async {
    if (kIsWeb) return;

    final ar = await Permission.activityRecognition.request();
    final sensors = await Permission.sensors.request();
    _permissionGranted = ar.isGranted || sensors.isGranted;
    if (!_permissionGranted) {
      notifyListeners();
      return;
    }

    await _stepSub?.cancel();
    await _statusSub?.cancel();

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (_) {},
        cancelOnError: false,
      );
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        _onStatus,
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {
      _permissionGranted = false;
    }
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    if (_paused) return;
    if (!_hasBase) {
      _baseSteps = event.steps;
      _hasBase = true;
    }
    final today = event.steps - _baseSteps;
    _steps = today < 0 ? event.steps : today;
    notifyListeners();
  }

  void _onStatus(PedestrianStatus event) {
    if (_paused) return;
    final walking = event.status == 'walking';
    if (walking && !_isWalking) {
      _isWalking = true;
      _walkStartedAt = DateTime.now();
      _tick ??= Timer.periodic(const Duration(seconds: 15), (_) {
        if (!_paused) notifyListeners();
      });
    } else if (!walking && _isWalking) {
      if (_walkStartedAt != null) {
        _activeAccumulated += DateTime.now().difference(_walkStartedAt!);
        _walkStartedAt = null;
      }
      _isWalking = false;
    }
    notifyListeners();
  }

  /// Notification "Not walking?" → pause for 1 hour (caller sets timer).
  void pauseWalkingDetection() {
    if (_walkStartedAt != null) {
      _activeAccumulated += DateTime.now().difference(_walkStartedAt!);
      _walkStartedAt = null;
    }
    _isWalking = false;
    _paused = true;
    notifyListeners();
  }

  /// App opened or suppress window ended.
  void resumeWalkingDetection() {
    _paused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _tick?.cancel();
    super.dispose();
  }
}
