// lib/home/services/step_foreground.dart
// Owns the Android foreground sensor stream and bridges raw sensor counts
// back to the UI isolate. The UI isolate remains the source of persisted app data.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';
import 'package:helsa/home/home_screen_widget/home_widget_bridge.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';

const String _stepTaskStateKey = 'helsa_step_state';

@pragma('vm:entry-point')
void stepForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(StepTaskHandler());
}

class StepForeground {
  StepForeground._();
  static final StepForeground instance = StepForeground._();

  static const int _serviceId = 4202;
  static const String _iconMeta =
      'com.example.helsa.service.NOTIFICATION_ICON';

  static const NotificationIcon _notifIcon = NotificationIcon(
    metaDataName: _iconMeta,
    backgroundColor: Colors.transparent,
  );

  bool _listening = false;
  bool _taskDataAttached = false;
  bool _initialized = false;
  int _lastSteps = -1;
  int _lastGoal = -1;

  void init() {
    if (kIsWeb || !Platform.isAndroid) return;

    if (!_initialized) {
      _initialized = true;
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'helsa_step_service_v3',
          channelName: 'Helsa Steps',
          channelDescription: 'Live step counting',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(3000),
          autoRunOnBoot: true,
          autoRunOnMyPackageReplaced: true,
          allowWakeLock: true,
          allowWifiLock: false,
        ),
      );
    }

    if (!_taskDataAttached) {
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
      _taskDataAttached = true;
    }
  }

  void attachTracker() {
    if (_listening) return;
    _listening = true;
    StepTracker.instance.addListener(_onTrackerChanged);
  }

  void detachTracker() {
    if (!_listening) return;
    _listening = false;
    StepTracker.instance.removeListener(_onTrackerChanged);
  }

  bool _hasMeaningfulTrackerChange(StepTracker tracker) {
    final goalChanged = tracker.stepsGoal != _lastGoal;
    final stepsChanged = _lastSteps < 0 ||
        tracker.steps < _lastSteps ||
        tracker.steps - _lastSteps >= 10;
    return goalChanged || stepsChanged;
  }

  void _onTrackerChanged() {
    final tracker = StepTracker.instance;
    if (!_hasMeaningfulTrackerChange(tracker)) return;
    _lastSteps = tracker.steps;
    _lastGoal = tracker.stepsGoal;
    unawaited(_sendTrackerState());
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    final tracker = StepTracker.instance;
    final rawSteps = data['deviceSteps'];
    if (rawSteps is num) {
      tracker.ingestExternalDeviceSteps(rawSteps.toInt());
    }
    if (data['backgroundActivity'] == true) {
      final activeMs = data['activeMs'];
      final isWalking = data['isWalking'];
      if (activeMs is num && isWalking is bool) {
        tracker.ingestBackgroundActivity(
          activeMs: activeMs.toInt(),
          isWalking: isWalking,
        );
      }
    }
  }

  Future<void> _sendTrackerState({bool syncActivity = false}) async {
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      final tracker = StepTracker.instance;
      FlutterForegroundTask.sendDataToTask({
        'baseDeviceSteps': tracker.baseDeviceSteps,
        'dailySteps': tracker.steps,
        'stepsGoal': tracker.stepsGoal,
        'dayKey': tracker.currentDayKey,
        if (syncActivity) 'activeMs': tracker.activeMillisecondsForSync,
        if (syncActivity) 'isWalking': tracker.isWalking,
        'stepsLabel': HomeText.getString(_lang(), 'steps'),
        'notificationBody': _body(),
      });
    } catch (error, stackTrace) {
      debugPrint('StepForeground.sendState: $error\n$stackTrace');
    }
  }

  Future<bool> start() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    init();
    await StepsStore.open();
    attachTracker();

    if (await FlutterForegroundTask.isRunningService) {
      StepTracker.instance.setBackgroundActivityAuthority(true);
      await _sendTrackerState();
      await refresh(force: true);
      return true;
    }

    final tracker = StepTracker.instance;
    tracker.setBackgroundActivityAuthority(false);
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: _title(tracker.steps, tracker.stepsGoal),
      notificationText: _body(),
      notificationIcon: _notifIcon,
      callback: stepForegroundCallback,
    );

    final started = result is ServiceRequestSuccess;
    if (started) {
      tracker.setBackgroundActivityAuthority(true);
      _lastSteps = tracker.steps;
      _lastGoal = tracker.stepsGoal;
      await _sendTrackerState(syncActivity: true);
      await HomeWidgetBridge.instance.push(force: true);
    } else {
      debugPrint('StepForeground.start failed: $result');
    }
    return started;
  }

  Future<void> ensureRunning() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        StepTracker.instance.setBackgroundActivityAuthority(false);
        await start();
      } else {
        StepTracker.instance.setBackgroundActivityAuthority(true);
        await _sendTrackerState();
        await refresh(force: true);
      }
    } catch (error, stackTrace) {
      debugPrint('StepForeground.ensureRunning: $error\n$stackTrace');
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final tracker = StepTracker.instance;
    if (!force && !_hasMeaningfulTrackerChange(tracker)) return;

    _lastSteps = tracker.steps;
    _lastGoal = tracker.stepsGoal;

    try {
      if (!await FlutterForegroundTask.isRunningService) {
        tracker.setBackgroundActivityAuthority(false);
        await start();
        return;
      }
      await FlutterForegroundTask.updateService(
        notificationTitle: _title(tracker.steps, tracker.stepsGoal),
        notificationText: _body(),
        notificationIcon: _notifIcon,
      );
      await _sendTrackerState();
    } catch (error, stackTrace) {
      debugPrint('StepForeground.refresh: $error\n$stackTrace');
    }
  }

  /// Stops the live task and overwrites its persisted snapshot so old
  /// counters cannot be restored after a full profile reset.
  Future<bool> resetForProfileClear() async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return false;

    final wasRunning = await FlutterForegroundTask.isRunningService;
    await stop();
    final now = DateTime.now();
    final dayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await FlutterForegroundTask.saveData(
      key: _stepTaskStateKey,
      value: jsonEncode({
        'dayKey': dayKey,
        'baseDeviceSteps': null,
        'dailySteps': 0,
        'stepsGoal': 7500,
        'stepsLabel': HomeText.getString(_lang(), 'steps'),
        'notificationBody': _body(),
        'activeMs': 0,
      }),
    );
    _lastSteps = 0;
    _lastGoal = -1;
    return wasRunning;
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    detachTracker();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    StepTracker.instance.setBackgroundActivityAuthority(false);
    if (_taskDataAttached) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
      _taskDataAttached = false;
    }
  }

  static String _lang() {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }

  static String _title(int steps, int goal) {
    final label = HomeText.getString(_lang(), 'steps');
    return '$steps / $goal $label';
  }

  static String _body() => HomeText.getString(_lang(), 'notif_body');
}

class StepTaskHandler extends TaskHandler {
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _statusSubscription;

  int? _baseDeviceSteps;
  int _dailySteps = 0;
  int _stepsGoal = 7500;
  int _lastNotifiedSteps = -1;
  int _lastPersistedSteps = -1;
  int _activeMs = 0;
  bool _isWalking = false;
  DateTime? _walkStartedAt;
  DateTime? _lastStepAt;
  DateTime _lastPersistAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _dayKey = '';
  String _stepsLabel = 'steps';
  String _notificationBody = 'Helsa is tracking activity';


  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _dayKey = _todayKey();

    try {
      final saved = await FlutterForegroundTask.getData(key: _stepTaskStateKey);
      if (saved is String) {
        final decoded = jsonDecode(saved);
        if (decoded is Map) {
          final savedDay = decoded['dayKey']?.toString();
          if (savedDay == _dayKey) {
            final base = decoded['baseDeviceSteps'];
            final steps = decoded['dailySteps'];
            final goal = decoded['stepsGoal'];
            _baseDeviceSteps = base is num ? base.toInt() : null;
            _dailySteps = steps is num ? steps.toInt() : 0;
            _stepsGoal = goal is num ? goal.toInt() : _stepsGoal;
            final activeMs = decoded['activeMs'];
            _activeMs = activeMs is num ? activeMs.toInt() : 0;
            _stepsLabel = decoded['stepsLabel']?.toString() ?? _stepsLabel;
            _notificationBody =
                decoded['notificationBody']?.toString() ?? _notificationBody;
          }
        }
      }
    } catch (_) {
      // A missing or outdated task-state record is a normal first-run case.
    }

    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: (error, stackTrace) {
        debugPrint('StepTaskHandler sensor stream: $error');
      },
      cancelOnError: false,
    );
    _statusSubscription = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: (error, stackTrace) {
        debugPrint('StepTaskHandler status stream: $error');
      },
      cancelOnError: false,
    );
  }

  void _onStepCount(StepCount event) {
    final today = _todayKey();
    if (_dayKey != today) {
      _dayKey = today;
      _baseDeviceSteps = event.steps;
      _dailySteps = 0;
      _activeMs = 0;
      _walkStartedAt = null;
      _lastStepAt = null;
      _isWalking = false;
      _lastPersistedSteps = -1;
    }

    _lastStepAt = DateTime.now();
    if (!_isWalking) {
      _isWalking = true;
      _walkStartedAt = DateTime.now();
    }

    if (_baseDeviceSteps == null) {
      _baseDeviceSteps = event.steps - _dailySteps;
    }

    if (event.steps < _baseDeviceSteps!) {
      // Preserve today's accumulated steps when the hardware counter restarts.
      _baseDeviceSteps = event.steps - _dailySteps;
    }

    final calculated = event.steps - _baseDeviceSteps!;
    final nextSteps = calculated < 0 ? 0 : calculated;
    if (nextSteps > _dailySteps) _dailySteps = nextSteps;

    FlutterForegroundTask.sendDataToMain({
      'deviceSteps': event.steps,
      'dayKey': _dayKey,
    });
    if (_lastPersistedSteps < 0 ||
        _dailySteps - _lastPersistedSteps >= 10) {
      _lastPersistedSteps = _dailySteps;
      unawaited(_persistState());
    }

    _sendActivityState();

    if (_lastNotifiedSteps < 0 ||
        _dailySteps - _lastNotifiedSteps >= 10 ||
        (_stepsGoal > 0 && _dailySteps >= _stepsGoal &&
            _lastNotifiedSteps < _stepsGoal)) {
      _lastNotifiedSteps = _dailySteps;
      FlutterForegroundTask.updateService(
        notificationTitle: '$_dailySteps / $_stepsGoal $_stepsLabel',
        notificationText: _notificationBody,
      );
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    final now = DateTime.now();
    final walking = event.status.toLowerCase() == 'walking';

    if (walking) {
      _lastStepAt = now;
      if (!_isWalking) {
        _isWalking = true;
        _walkStartedAt = now;
      }
    } else if (_isWalking) {
      final lastStep = _lastStepAt;
      if (lastStep == null || now.difference(lastStep).inSeconds > 15) {
        _finishWalkingSession(now);
      }
    }
    _sendActivityState();
  }

  void _finishWalkingSession(DateTime now) {
    final startedAt = _walkStartedAt;
    if (startedAt != null) {
      _activeMs += now.difference(startedAt).inMilliseconds;
    }
    _walkStartedAt = null;
    _isWalking = false;
    _lastStepAt = null;
    unawaited(_persistState());
    _sendActivityState();
  }

  int _liveActiveMs() {
    final startedAt = _walkStartedAt;
    if (_isWalking && startedAt != null) {
      return _activeMs + DateTime.now().difference(startedAt).inMilliseconds;
    }
    return _activeMs;
  }

  void _sendActivityState() {
    FlutterForegroundTask.sendDataToMain({
      'backgroundActivity': true,
      'activeMs': _liveActiveMs(),
      'isWalking': _isWalking,
    });
  }

  Future<void> _persistState() async {
    await FlutterForegroundTask.saveData(
      key: _stepTaskStateKey,
      value: jsonEncode({
        'dayKey': _dayKey,
        'baseDeviceSteps': _baseDeviceSteps,
        'dailySteps': _dailySteps,
        'stepsGoal': _stepsGoal,
        'stepsLabel': _stepsLabel,
        'notificationBody': _notificationBody,
        'activeMs': _activeMs,
      }),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    final incomingDay = data['dayKey']?.toString();
    if (incomingDay != _todayKey()) return;
    if (_dayKey != incomingDay) {
      _dayKey = incomingDay!;
      _baseDeviceSteps = null;
      _dailySteps = 0;
      _activeMs = 0;
      _isWalking = false;
      _walkStartedAt = null;
      _lastStepAt = null;
      _lastNotifiedSteps = -1;
      _lastPersistedSteps = -1;
    }

    final base = data['baseDeviceSteps'];
    final steps = data['dailySteps'];
    final goal = data['stepsGoal'];

    _dayKey = incomingDay!;
    _baseDeviceSteps = base is num ? base.toInt() : null;
    _dailySteps = steps is num ? steps.toInt() : 0;
    _lastPersistedSteps = _dailySteps;
    _stepsGoal = goal is num ? goal.toInt() : _stepsGoal;
    final activeMs = data['activeMs'];
    final incomingWalking = data['isWalking'];
    if (activeMs is num && incomingWalking is bool) {
      if (activeMs.toInt() >= _activeMs) _activeMs = activeMs.toInt();
      _isWalking = incomingWalking;
      _walkStartedAt = _isWalking ? DateTime.now() : null;
      _lastStepAt = _isWalking ? DateTime.now() : null;
    }
    _stepsLabel = data['stepsLabel']?.toString() ?? _stepsLabel;
    _notificationBody =
        data['notificationBody']?.toString() ?? _notificationBody;
    unawaited(_persistState());
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isWalking && _lastStepAt != null &&
        timestamp.difference(_lastStepAt!).inSeconds > 12) {
      _finishWalkingSession(timestamp);
    }
    _sendActivityState();
    if (timestamp.difference(_lastPersistAt).inSeconds >= 30) {
      _lastPersistAt = timestamp;
      unawaited(_persistState());
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _finishWalkingSession(timestamp);
    await _stepSubscription?.cancel();
    await _statusSubscription?.cancel();
    _stepSubscription = null;
    _statusSubscription = null;
    await _persistState();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
