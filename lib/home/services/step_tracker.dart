// lib/home/services/step_tracker.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool _backgroundActivityAuthority = false;

  DateTime? _walkStartedAt;
  int _activeMs = 0;
  Timer? _tick;
  DateTime? _lastStepAt;
  Timer? _saveTimer;
  bool _dirty = false;
  DateTime _lastActivePersistAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastNotifiedActiveMinute = -1;
  bool? _lastNotifiedWalking;

  /// Stricter session gates — reduce phantom active time.
  static const int _gapSeconds = 10;
  static const int _minStepsToStart = 4;
  static const int _startWindowSeconds = 8;
  static const int _minSessionSteps = 8;
  static const int _minSessionSeconds = 20;

  /// Recent step bursts used to confirm real walking before starting the timer.
  final List<DateTime> _recentStepEvents = <DateTime>[];
  int _stepsAtSessionStart = 0;
  bool _statusSaysWalking = false;

  int get steps => _steps;
  int? get baseDeviceSteps => _baseDevice;
  String get currentDayKey {
    _syncCalendarDay();
    return _trackedDayKey ?? StepsStore.currentDayKey;
  }

  bool get isWalking => _isWalking;
  bool get permissionGranted => _permissionGranted;

  int get stepsGoal {
    final custom = StepsStore.customStepsGoal;
    if (custom != null) return custom;
    try {
      return GoalCalculator.stepsGoal();
    } catch (_) {
      return GoalCalculator.standardStepsGoal;
    }
  }

  double get calories {
    // Prefer reconciled minutes so phantom sensor time does not inflate kcal.
    return GoalCalculator.caloriesForSteps(
      _steps,
      activeMinutes: activeMinutes,
    );
  }

  double get caloriesGoal {
    final custom = StepsStore.customCaloriesGoal;
    if (custom != null) return custom.toDouble();
    return GoalCalculator.caloriesGoal();
  }

  int get activeMillisecondsForSync {
    var milliseconds = _activeMs;
    if (_walkStartedAt != null) {
      milliseconds += DateTime.now().difference(_walkStartedAt!).inMilliseconds;
    }
    return milliseconds;
  }

  int get _sensorActiveMinutes =>
      (activeMillisecondsForSync / 60000).floor();

  int get activeMinutes {
    return GoalCalculator.reconcileActiveMinutes(
      sensorMinutes: _sensorActiveMinutes,
      steps: _steps,
    );
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
    } catch (error, stackTrace) {
      debugPrint('StepTracker storage init failed: $error\n$stackTrace');
    }

    if (kIsWeb) {
      notifyListeners();
      return;
    }

    final activityPermission = await Permission.activityRecognition.status;
    _permissionGranted = activityPermission.isGranted;

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

  void ingestBackgroundActivity({
    required int activeMs,
    required bool isWalking,
  }) {
    _backgroundActivityAuthority = true;
    final previousMinute = activeMinutes;
    final previousWalking = _isWalking;
    final now = DateTime.now();
    final activeChanged = activeMs > _activeMs;
    if (activeChanged) _activeMs = activeMs;
    _walkStartedAt = isWalking ? now : null;
    _isWalking = isWalking;
    _lastStepAt = isWalking ? now : null;
    if (activeChanged &&
        (!isWalking || now.difference(_lastActivePersistAt).inSeconds >= 30)) {
      _lastActivePersistAt = now;
      unawaited(StepsStore.saveActiveMs(_activeMs));
    }
    _notifyIfDisplayChanged(
      previousMinute: previousMinute,
      previousWalking: previousWalking,
    );
  }

  void setBackgroundActivityAuthority(bool enabled) {
    final changed =
        _backgroundActivityAuthority != enabled || (!enabled && _isWalking);
    _backgroundActivityAuthority = enabled;
    if (!enabled) {
      _walkStartedAt = null;
      _lastStepAt = null;
      _isWalking = false;
      _recentStepEvents.clear();
    }
    if (changed) notifyListeners();
  }

  void _notifyIfDisplayChanged({
    int? previousMinute,
    bool? previousWalking,
  }) {
    final minute = activeMinutes;
    final walking = isWalking;
    if (previousMinute == null ||
        previousWalking == null ||
        minute != previousMinute ||
        walking != previousWalking ||
        minute != _lastNotifiedActiveMinute ||
        walking != _lastNotifiedWalking) {
      _lastNotifiedActiveMinute = minute;
      _lastNotifiedWalking = walking;
      notifyListeners();
    }
  }

  String _localDayKey() {
    // Same rule as StepsStore (respects SettingsStore.dayResetHour).
    return StepsStore.currentDayKey;
  }

  void _syncCalendarDay() {
    final today = _localDayKey();
    if (_trackedDayKey == null) {
      _trackedDayKey = StepsStore.currentDayKey;
      return;
    }
    if (_trackedDayKey == today) return;

    _saveTimer?.cancel();
    _dirty = false;
    StepsStore.rolloverWithCurrentValues(
      steps: _steps,
      activeMs: activeMillisecondsForSync,
    );
    _trackedDayKey = today;
    _steps = StepsStore.steps;
    _baseDevice = StepsStore.baseDeviceSteps;
    _activeMs = StepsStore.activeMs;
    _isWalking = false;
    _walkStartedAt = null;
    _lastStepAt = null;
    _recentStepEvents.clear();
    _stepsAtSessionStart = 0;
    _lastActivePersistAt = DateTime.now();
    notifyListeners();
  }

  void ingestExternalDeviceSteps(int rawDeviceSteps) {
    if (rawDeviceSteps < 0) return;

    _syncCalendarDay();

    if (_baseDevice == null) {
      _baseDevice = rawDeviceSteps - _steps;
      unawaited(StepsStore.saveBaseDeviceSteps(_baseDevice!));
    }

    if (rawDeviceSteps < _baseDevice!) {
      _baseDevice = rawDeviceSteps - _steps;
      unawaited(StepsStore.saveBaseDeviceSteps(_baseDevice!));
    }

    final calculatedSteps = rawDeviceSteps - _baseDevice!;
    final nextSteps = calculatedSteps < 0 ? 0 : calculatedSteps;

    if (nextSteps == _steps) return;

    if (nextSteps > _steps) {
      final now = DateTime.now();
      final gained = nextSteps - _steps;
      _lastStepAt = now;
      for (var i = 0; i < gained && i < 20; i++) {
        _recentStepEvents.add(now);
      }
      _pruneRecentSteps(now);
      if (!_backgroundActivityAuthority) {
        _tryStartWalkingSession(now);
      }
    }

    _steps = nextSteps;
    _scheduleSave();
    notifyListeners();
  }

  void _pruneRecentSteps(DateTime now) {
    _recentStepEvents.removeWhere(
      (t) => now.difference(t).inSeconds > _startWindowSeconds,
    );
  }

  bool _hasStepBurst(DateTime now) {
    _pruneRecentSteps(now);
    return _recentStepEvents.length >= _minStepsToStart;
  }

  void _tryStartWalkingSession(DateTime now) {
    if (_isWalking || _backgroundActivityAuthority) return;
    // Need a real burst of steps — not a single jiggle.
    if (!_hasStepBurst(now)) return;
    _isWalking = true;
    _walkStartedAt = now;
    _stepsAtSessionStart = _steps;
  }

  void _onStepCount(StepCount event) {
    ingestExternalDeviceSteps(event.steps);
  }

  void _onTick() {
    _syncCalendarDay();
    final previousMinute = activeMinutes;
    final previousWalking = isWalking;
    if (_backgroundActivityAuthority) {
      _notifyIfDisplayChanged(
        previousMinute: previousMinute,
        previousWalking: previousWalking,
      );
      return;
    }

    final now = DateTime.now();
    _pruneRecentSteps(now);

    // Do NOT auto-start from tick alone — only from step burst / confirmed status.

    if (_isWalking &&
        _lastStepAt != null &&
        now.difference(_lastStepAt!).inSeconds > _gapSeconds) {
      _finishWalkingSession(now);
    }

    // If status still says walking but no steps for gap — stop.
    if (_isWalking &&
        _lastStepAt != null &&
        !_statusSaysWalking &&
        now.difference(_lastStepAt!).inSeconds > (_gapSeconds ~/ 2)) {
      _finishWalkingSession(now);
    }

    if (_isWalking &&
        _walkStartedAt != null &&
        now.difference(_lastActivePersistAt).inSeconds >= 30) {
      final liveActiveMs =
          _activeMs + now.difference(_walkStartedAt!).inMilliseconds;
      _lastActivePersistAt = now;
      unawaited(StepsStore.saveActiveMs(liveActiveMs));
    }

    _notifyIfDisplayChanged(
      previousMinute: previousMinute,
      previousWalking: previousWalking,
    );
  }

  void _finishWalkingSession(DateTime now) {
    final startedAt = _walkStartedAt;
    if (startedAt != null) {
      final elapsed = now.difference(startedAt).inMilliseconds;
      final sessionSteps = _steps - _stepsAtSessionStart;
      final elapsedSec = elapsed / 1000.0;

      // Credit time only if the session looked like real walking.
      final credible = sessionSteps >= _minSessionSteps &&
          elapsedSec >= _minSessionSeconds &&
          sessionSteps / (elapsedSec / 60.0).clamp(0.2, 999) >= 50;

      if (credible && elapsed > 0) {
        // Cap credited ms by step cadence (~max 1 min per 90 steps in session).
        final maxMsBySteps = (sessionSteps / 90.0 * 60000).round();
        final credited = elapsed.clamp(0, maxMsBySteps);
        _activeMs += credited;
        unawaited(StepsStore.saveActiveMs(_activeMs));
        _lastActivePersistAt = now;
      }
      _walkStartedAt = null;
    }
    _isWalking = false;
    _recentStepEvents.clear();
  }

  void _onStatus(PedestrianStatus event) {
    if (_backgroundActivityAuthority) return;
    final previousMinute = activeMinutes;
    final previousWalking = isWalking;
    final walking = event.status.toLowerCase() == 'walking';
    final now = DateTime.now();
    _statusSaysWalking = walking;

    if (walking && !_isWalking) {
      // Status alone is not enough — still need a step burst.
      if (_hasStepBurst(now)) {
        _tryStartWalkingSession(now);
      }
    } else if (!walking && _isWalking) {
      final lastStep = _lastStepAt;
      if (lastStep == null ||
          now.difference(lastStep).inSeconds > _gapSeconds) {
        _finishWalkingSession(now);
      }
    }

    _notifyIfDisplayChanged(
      previousMinute: previousMinute,
      previousWalking: previousWalking,
    );
  }

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

  void _scheduleSave() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      if (!_dirty) return;
      _dirty = false;
      final base = _baseDevice;
      if (base != null) {
        unawaited(StepsStore.saveTrackerState(
          steps: _steps,
          baseDeviceSteps: base,
        ));
      } else {
        unawaited(StepsStore.saveSteps(_steps));
      }
    });
  }

  void _flushSave() {
    _saveTimer?.cancel();
    if (!_dirty) return;
    _dirty = false;
    final base = _baseDevice;
    if (base != null) {
      unawaited(StepsStore.saveTrackerState(
        steps: _steps,
        baseDeviceSteps: base,
      ));
    } else {
      unawaited(StepsStore.saveSteps(_steps));
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
