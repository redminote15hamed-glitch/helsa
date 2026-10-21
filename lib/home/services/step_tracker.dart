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
  Timer? _saveTimer;
  bool _dirty = false;

  int get steps => _steps;
  bool get isWalking => _isWalking && !isPaused;
  bool get permissionGranted => _permissionGranted;

  /// pause واقعی: حافظه + فلگ داخل حافظه تا ۱ ساعت
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
    if (_walkStartedAt != null && !isPaused) {
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
      // پاک کردن pause مانده از نسخه‌های قبلی تا شمارش دوباره کار کند
      if (StepsStore.isCountingPaused) {
        await StepsStore.clearPause();
      }
      _paused = false;
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
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) => _onTick());
    notifyListeners();
  }

  void _onTick() {
    // پایان خودکار ۱ ساعت
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
    // ─── حالت pause واقعی ───
    // قدم‌های این بازه نباید بعداً یک‌جا اضافه شوند:
    // پایه سخت‌افزار را جلو می‌کشیم تا _steps ثابت بماند.
    if (isPaused) {
      _baseDevice = event.steps - _steps;
      if (_baseDevice! < 0) _baseDevice = event.steps;
      StepsStore.saveBaseDeviceSteps(_baseDevice!);
      _isWalking = false;
      _walkStartedAt = null;
      _lastStepAt = null;
      return;
    }

    if (_baseDevice == null) {
      _baseDevice = event.steps - _steps;
      if (_baseDevice! < 0) _baseDevice = event.steps;
      StepsStore.saveBaseDeviceSteps(_baseDevice!);
    }

    // ریبوت / ریست شمارنده دستگاه
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

    if (next > _steps) {
      _lastStepAt = DateTime.now();
      if (!_isWalking) {
        _isWalking = true;
        _walkStartedAt = DateTime.now();
      }
      _steps = next;
      // UI فوری؛ Hive با تأخیر کوتاه تا لگ ندهد
      _scheduleSave();
      notifyListeners();
    } else if (next != _steps) {
      _steps = next;
      _scheduleSave();
      notifyListeners();
    }
  }

  void _onStatus(PedestrianStatus event) {
    if (isPaused) {
      _isWalking = false;
      return;
    }
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

  /// توقف واقعی ۱ ساعته — Hive + حافظه
  Future<void> pauseWalkingDetection() async {
    if (_walkStartedAt != null) {
      _activeMs += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
      _walkStartedAt = null;
      await StepsStore.saveActiveMs(_activeMs);
    }
    _isWalking = false;
    _lastStepAt = null;
    _paused = true;
    try {
      await StepsStore.setPauseForOneHour();
    } catch (_) {}
    notifyListeners();
  }

  /// فقط وقتی ۱ ساعت تمام شد یا کاربر صریحاً خواست
  Future<void> resumeWalkingDetection({bool force = false}) async {
    if (!force && StepsStore.isCountingPaused) {
      // هنوز داخل پنجره ۱ ساعته هستیم — resume نکن
      _paused = true;
      notifyListeners();
      return;
    }
    try {
      await StepsStore.clearPause();
    } catch (_) {}
    _paused = false;
    notifyListeners();
  }

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_dirty) return;
      _dirty = false;
      StepsStore.saveSteps(_steps);
      if (_baseDevice != null) {
        StepsStore.saveBaseDeviceSteps(_baseDevice!);
      }
    });
  }

  void _flushSave() {
    _saveTimer?.cancel();
    if (_dirty) {
      _dirty = false;
      StepsStore.saveSteps(_steps);
      if (_baseDevice != null) {
        StepsStore.saveBaseDeviceSteps(_baseDevice!);
      }
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
