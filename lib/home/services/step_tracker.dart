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
  String? _trackedDayKey;
  bool _isWalking = false;
  bool _permissionGranted = false;
  bool _paused = false;

  DateTime? _walkStartedAt;
  int _activeMs = 0;
  Timer? _tick;
  DateTime? _lastStepAt;
  Timer? _saveTimer;
  bool _dirty = false;
  DateTime _lastActivePersistAt = DateTime.fromMillisecondsSinceEpoch(0);

  int get steps => _steps;
  int? get baseDeviceSteps => _baseDevice;
  String get currentDayKey => StepsStore.currentDayKey;
  bool get isWalking => _isWalking && !isPaused;
  bool get permissionGranted => _permissionGranted;

  bool get isPaused {
    try {
      if (StepsStore.isCountingPaused) return true;
    } catch (_) {}
    return _paused;
  }

  int get stepsGoal {
    final custom = StepsStore.customStepsGoal;
    if (custom != null) return custom;
    try {
      return GoalCalculator.stepsGoal();
    } catch (_) {
      return GoalCalculator.standardStepsGoal;
    }
  }

  double get calories => _steps * GoalCalculator.kcalPerStep();

  double get caloriesGoal {
    final custom = StepsStore.customCaloriesGoal;
    if (custom != null) return custom.toDouble();
    return GoalCalculator.caloriesGoal();
  }

  int get activeMinutes {
    var milliseconds = _activeMs;
    if (_walkStartedAt != null && !isPaused) {
      milliseconds += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
    }
    return (milliseconds / 60000).floor();
  }

  int get activeMinutesGoal {
    final custom = StepsStore.customActiveGoal;
    if (custom != null) return custom;
    return GoalCalculator.activeMinutesGoal();
  }

  String get activeTimeLabel => '$activeMinutes';

  Future<void> init() async {
    try {
      await StepsStore.open();
      _steps = StepsStore.steps;
      _baseDevice = StepsStore.baseDeviceSteps;
      _activeMs = StepsStore.activeMs;
      _trackedDayKey = StepsStore.currentDayKey;

      if (StepsStore.isCountingPaused) {
        await StepsStore.clearPause();
      }
      _paused = false;
    } catch (error, stackTrace) {
      debugPrint('StepTracker storage init failed: $error\n$stackTrace');
    }

    if (kIsWeb) {
      notifyListeners();
      return;
    }

    final activityPermission = await Permission.activityRecognition.request();
    final sensorPermission = await Permission.sensors.request();
    _permissionGranted =
        activityPermission.isGranted || sensorPermission.isGranted;

    if (!_permissionGranted) {
      notifyListeners();
      return;
    }

    await _stepSub?.cancel();
    await _statusSub?.cancel();

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (error, stackTrace) {
          debugPrint('StepTracker step stream: $error');
        },
        cancelOnError: false,
      );
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        _onStatus,
        onError: (error, stackTrace) {
          debugPrint('StepTracker status stream: $error');
        },
        cancelOnError: false,
      );
    } catch (error, stackTrace) {
      _permissionGranted = false;
      debugPrint('StepTracker stream init failed: $error\n$stackTrace');
    }

    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    notifyListeners();
  }

  /// Accepts sensor counts from either the UI isolate or the foreground-task
  /// isolate. Duplicate events are harmless because the raw counter is monotonic.
  void ingestExternalDeviceSteps(int rawDeviceSteps) {
    if (rawDeviceSteps < 0) return;

    final dayKey = StepsStore.currentDayKey;
    if (_trackedDayKey != dayKey) {
      // StepsStore has already archived yesterday and reset today's values.
      _trackedDayKey = dayKey;
      _steps = StepsStore.steps;
      _activeMs = StepsStore.activeMs;
      _baseDevice = rawDeviceSteps;
      _isWalking = false;
      _walkStartedAt = null;
      _lastStepAt = null;
      unawaited(StepsStore.saveBaseDeviceSteps(rawDeviceSteps));
      notifyListeners();
      return;
    }

    if (_baseDevice == null) {
      _baseDevice = rawDeviceSteps - _steps;
      if (_baseDevice! < 0) _baseDevice = rawDeviceSteps;
      unawaited(StepsStore.saveBaseDeviceSteps(_baseDevice!));
    }

    // The hardware counter resets after a device reboot.
    if (rawDeviceSteps < _baseDevice!) {
      _baseDevice = rawDeviceSteps - _steps;
      if (_baseDevice! < 0) {
        _baseDevice = rawDeviceSteps;
        _steps = 0;
      }
      unawaited(StepsStore.saveBaseDeviceSteps(_baseDevice!));
    }

    final calculatedSteps = rawDeviceSteps - _baseDevice!;
    final nextSteps = calculatedSteps < 0 ? 0 : calculatedSteps;

    if (nextSteps == _steps) return;

    if (nextSteps > _steps) {
      _lastStepAt = DateTime.now();
      if (!_isWalking) {
        _isWalking = true;
        _walkStartedAt = DateTime.now();
      }
    }

    _steps = nextSteps;
    _scheduleSave();
    notifyListeners();
  }

  void _onStepCount(StepCount event) {
    ingestExternalDeviceSteps(event.steps);
  }

  void _onTick() {
    if (_paused && !StepsStore.isCountingPaused) {
      _paused = false;
      notifyListeners();
      return;
    }
    if (isPaused) return;

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
      _finishWalkingSession(now);
    }

    if (_isWalking && _walkStartedAt != null &&
        now.difference(_lastActivePersistAt).inSeconds >= 30) {
      final liveActiveMs =
          _activeMs + now.difference(_walkStartedAt!).inMilliseconds;
      _lastActivePersistAt = now;
      unawaited(StepsStore.saveActiveMs(liveActiveMs));
    }

    notifyListeners();
  }

  void _finishWalkingSession(DateTime now) {
    final startedAt = _walkStartedAt;
    if (startedAt != null) {
      _activeMs += now.difference(startedAt).inMilliseconds;
      unawaited(StepsStore.saveActiveMs(_activeMs));
      _lastActivePersistAt = now;
      _walkStartedAt = null;
    }
    _isWalking = false;
  }

  void _onStatus(PedestrianStatus event) {
    if (isPaused) {
      _isWalking = false;
      return;
    }

    final walking = event.status.toLowerCase() == 'walking';
    final now = DateTime.now();

    if (walking && !_isWalking) {
      _isWalking = true;
      _walkStartedAt = now;
      _lastStepAt = now;
    } else if (!walking && _isWalking) {
      final lastStep = _lastStepAt;
      if (lastStep == null || now.difference(lastStep).inSeconds > 15) {
        _finishWalkingSession(now);
      }
    }

    notifyListeners();
  }

  /// Call after profile body/activity/age changes so listeners recalculate goals.
  void profileChanged() => notifyListeners();

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

  Future<void> pauseWalkingDetection() async {
    if (_walkStartedAt != null) {
      _activeMs += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
      _walkStartedAt = null;
      await StepsStore.saveActiveMs(_activeMs);
    }
    _isWalking = false;
    _lastStepAt = null;
    _paused = true;
    await StepsStore.setPauseForOneHour();
    notifyListeners();
  }

  Future<void> resumeWalkingDetection({bool force = false}) async {
    if (!force && StepsStore.isCountingPaused) {
      _paused = true;
      notifyListeners();
      return;
    }
    await StepsStore.clearPause();
    _paused = false;
    notifyListeners();
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_dirty) return;
      _dirty = false;
      unawaited(StepsStore.saveSteps(_steps));
      final base = _baseDevice;
      if (base != null) {
        unawaited(StepsStore.saveBaseDeviceSteps(base));
      }
    });
  }

  void _flushSave() {
    _saveTimer?.cancel();
    if (!_dirty) return;
    _dirty = false;
    unawaited(StepsStore.saveSteps(_steps));
    final base = _baseDevice;
    if (base != null) {
      unawaited(StepsStore.saveBaseDeviceSteps(base));
    }
  }

  @override
  void dispose() {
    _flushSave();
    _stepSub?.cancel();
    _statusSub?.cancel();
    _tick?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
