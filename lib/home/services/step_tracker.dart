// lib/home/services/step_tracker.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/home/services/goal_calculator.dart';

class StepTracker extends ChangeNotifier {
  StepTracker._();
  static final StepTracker instance = StepTracker._();

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _steps = 0;
  int? _baseDevice;
  bool _isWalking = false;
  bool _permissionGranted = false;
  bool _paused = false;

  DateTime? _walkStartedAt;
  int _activeMs = 0;
  Timer? _tick;
  DateTime? _lastStepAt;

  int get steps => _steps;
  bool get isWalking => _isWalking && !_paused;
  bool get permissionGranted => _permissionGranted;
  bool get isPaused => _paused;

  /// هدف سفارشی کاربر اولویت دارد؛ وگرنه از پروفایل (GoalCalculator)
  int get stepsGoal {
    final custom = StepsStore.customStepsGoal;
    if (custom != null) return custom;
    try {
      return GoalCalculator.stepsGoal();
    } catch (_) {
      return 8000;
    }
  }

  double get calories {
    try {
      final w = BodyStore.weight ?? 70.0;
      return _steps * 0.04 * (w / 70.0);
    } catch (_) {
      return _steps * 0.04;
    }
  }

  double get caloriesGoal {
    final custom = StepsStore.customCaloriesGoal;
    if (custom != null) return custom.toDouble();
    try {
      return GoalCalculator.caloriesGoal();
    } catch (_) {
      return 300.0;
    }
  }

  int get activeMinutes {
    var ms = _activeMs;
    if (_walkStartedAt != null && !_paused) {
      ms += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
    }
    return (ms / 60000).floor();
  }

  int get activeMinutesGoal {
    final custom = StepsStore.customActiveGoal;
    if (custom != null) return custom;
    try {
      return GoalCalculator.activeMinutesGoal();
    } catch (_) {
      return 30;
    }
  }

  String get activeTimeLabel => '$activeMinutes';

  Future<void> init() async {
    try {
      await StepsStore.open();
      _steps = StepsStore.steps;
      _baseDevice = StepsStore.baseDeviceSteps;
      _activeMs = StepsStore.activeMs;
    } catch (_) {}

    if (kIsWeb) {
      notifyListeners();
      return;
    }

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

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    if (_paused || StepsStore.isCountingPaused) return;
    final now = DateTime.now();

    if (_lastStepAt != null &&
        now.difference(_lastStepAt!).inSeconds <= 8 &&
        !_isWalking) {
      _isWalking = true;
      _walkStartedAt ??= now;
    }

    if (_isWalking &&
        _lastStepAt != null &&
        now.difference(_lastStepAt!).inSeconds > 12) {
      if (_walkStartedAt != null) {
        _activeMs += now.difference(_walkStartedAt!).inMilliseconds;
        _walkStartedAt = null;
        StepsStore.saveActiveMs(_activeMs);
      }
      _isWalking = false;
    }

    if (_isWalking && _walkStartedAt != null) {
      StepsStore.saveActiveMs(
        _activeMs + now.difference(_walkStartedAt!).inMilliseconds,
      );
    }
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    if (_paused || StepsStore.isCountingPaused) return;

    // پایه: شمارنده سخت‌افزار در لحظه شروع امروز
    if (_baseDevice == null) {
      // اگر از Hive قدم ذخیره داشتیم، پایه را طوری بگذار که همان مقدار بماند
      _baseDevice = event.steps - _steps;
      if (_baseDevice! < 0) _baseDevice = event.steps;
      StepsStore.saveBaseDeviceSteps(_baseDevice!);
    }

    // اگر ریبوت گوشی شمارنده را صفر کرده باشد
    if (event.steps < _baseDevice!) {
      _baseDevice = event.steps - _steps;
      if (_baseDevice! < 0) {
        _baseDevice = event.steps;
        _steps = 0;
      }
      StepsStore.saveBaseDeviceSteps(_baseDevice!);
    }

    final today = event.steps - _baseDevice!;
    final next = today < 0 ? 0 : today;

    // فقط افزایش واقعی را اعمال کن (از دست دادن رویداد کم شود)
    if (next > _steps) {
      _lastStepAt = DateTime.now();
      if (!_isWalking) {
        _isWalking = true;
        _walkStartedAt = DateTime.now();
      }
      _steps = next;
      StepsStore.saveSteps(_steps);
      notifyListeners();
    } else if (next != _steps) {
      // همگام‌سازی بدون پسرفت نادرست
      _steps = next;
      StepsStore.saveSteps(_steps);
      notifyListeners();
    }
  }

  void _onStatus(PedestrianStatus event) {
    if (_paused || StepsStore.isCountingPaused) return;
    final walking = event.status.toLowerCase() == 'walking';
    if (walking && !_isWalking) {
      _isWalking = true;
      _walkStartedAt = DateTime.now();
      _lastStepAt = DateTime.now();
    } else if (!walking && _isWalking) {
      final last = _lastStepAt;
      if (last == null || DateTime.now().difference(last).inSeconds > 15) {
        if (_walkStartedAt != null) {
          _activeMs +=
              DateTime.now().difference(_walkStartedAt!).inMilliseconds;
          _walkStartedAt = null;
          StepsStore.saveActiveMs(_activeMs);
        }
        _isWalking = false;
      }
    }
    notifyListeners();
  }

  Future<void> setStepsGoal(int value) async {
    await StepsStore.saveStepsGoal(value);
    notifyListeners();
  }

  Future<void> setCaloriesGoal(int value) async {
    await StepsStore.saveCaloriesGoal(value);
    notifyListeners();
  }

  Future<void> setActiveGoal(int value) async {
    await StepsStore.saveActiveGoal(value);
    notifyListeners();
  }

  void pauseWalkingDetection() {
    if (_walkStartedAt != null) {
      _activeMs += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
      _walkStartedAt = null;
      StepsStore.saveActiveMs(_activeMs);
    }
    _isWalking = false;
    _paused = true;
    notifyListeners();
  }

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
