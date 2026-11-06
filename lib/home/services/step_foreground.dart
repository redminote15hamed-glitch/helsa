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
  int _lastSteps = -1;
  int _lastGoal = -1;

  void init() {
    if (kIsWeb || !Platform.isAndroid) return;

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

  void _onTrackerChanged() {
    final tracker = StepTracker.instance;
    if (tracker.steps != _lastSteps || tracker.stepsGoal != _lastGoal) {
      _lastSteps = tracker.steps;
      _lastGoal = tracker.stepsGoal;
      unawaited(refresh(force: true));
    }
    unawaited(_sendTrackerState());
  }

  void _onTaskData(Object data) {
    if (data is! Map) return;
    final rawSteps = data['deviceSteps'];
    if (rawSteps is num) {
      StepTracker.instance.ingestExternalDeviceSteps(rawSteps.toInt());
    }
  }

  Future<void> _sendTrackerState() async {
    try {
      if (!await FlutterForegroundTask.isRunningService) return;
      final tracker = StepTracker.instance;
      FlutterForegroundTask.sendDataToTask({
        'baseDeviceSteps': tracker.baseDeviceSteps,
        'dailySteps': tracker.steps,
        'stepsGoal': tracker.stepsGoal,
        'dayKey': tracker.currentDayKey,
        'stepsLabel': HomeText.getString(_lang(), 'steps'),
        'notificationBody': _body(),
      });
    } catch (error, stackTrace) {
      debugPrint('StepForeground.sendState: $error\n$stackTrace');
    }
  }

  Future<bool> start() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    await StepsStore.open();
    if (StepsStore.isCountingPaused) {
      await StepsStore.clearPause();
      await StepTracker.instance.resumeWalkingDetection(force: true);
    }

    attachTracker();

    if (await FlutterForegroundTask.isRunningService) {
      await _sendTrackerState();
      await refresh(force: true);
      return true;
    }

    final tracker = StepTracker.instance;
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: _title(tracker.steps, tracker.stepsGoal),
      notificationText: _body(),
      notificationIcon: _notifIcon,
      callback: stepForegroundCallback,
    );

    final started = result is ServiceRequestSuccess;
    if (started) {
      _lastSteps = tracker.steps;
      _lastGoal = tracker.stepsGoal;
      await _sendTrackerState();
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
        await start();
      } else {
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
    if (!force && tracker.steps == _lastSteps &&
        tracker.stepsGoal == _lastGoal) {
      return;
    }

    _lastSteps = tracker.steps;
    _lastGoal = tracker.stepsGoal;

    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await start();
        return;
      }
      await FlutterForegroundTask.updateService(
        notificationTitle: _title(tracker.steps, tracker.stepsGoal),
        notificationText: _body(),
        notificationIcon: _notifIcon,
      );
      await _sendTrackerState();
      await HomeWidgetBridge.instance.push();
    } catch (error, stackTrace) {
      debugPrint('StepForeground.refresh: $error\n$stackTrace');
    }
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    detachTracker();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
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

  int? _baseDeviceSteps;
  int _dailySteps = 0;
  int _stepsGoal = GoalCalculatorFallback.steps;
  int _lastNotifiedSteps = -1;
  String _dayKey = '';
  String _stepsLabel = 'steps';
  String _notificationBody = 'Helsa is tracking activity';

  static const String _stateKey = 'helsa_step_state';

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
      final saved = await FlutterForegroundTask.getData(key: _stateKey);
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
  }

  void _onStepCount(StepCount event) {
    final today = _todayKey();
    if (_dayKey != today) {
      _dayKey = today;
      _baseDeviceSteps = event.steps;
      _dailySteps = 0;
    }

    if (_baseDeviceSteps == null) {
      _baseDeviceSteps = event.steps - _dailySteps;
      if (_baseDeviceSteps! < 0) _baseDeviceSteps = event.steps;
    }

    if (event.steps < _baseDeviceSteps!) {
      // Hardware counter reset (usually after a device reboot).
      _baseDeviceSteps = event.steps - _dailySteps;
      if (_baseDeviceSteps! < 0) {
        _baseDeviceSteps = event.steps;
        _dailySteps = 0;
      }
    }

    final calculated = event.steps - _baseDeviceSteps!;
    final nextSteps = calculated < 0 ? 0 : calculated;
    if (nextSteps > _dailySteps) _dailySteps = nextSteps;

    FlutterForegroundTask.sendDataToMain({
      'deviceSteps': event.steps,
      'dayKey': _dayKey,
    });
    unawaited(_persistState());

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

  Future<void> _persistState() async {
    await FlutterForegroundTask.saveData(
      key: _stateKey,
      value: jsonEncode({
        'dayKey': _dayKey,
        'baseDeviceSteps': _baseDeviceSteps,
        'dailySteps': _dailySteps,
        'stepsGoal': _stepsGoal,
        'stepsLabel': _stepsLabel,
        'notificationBody': _notificationBody,
      }),
    );
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;

    final incomingDay = data['dayKey']?.toString();
    if (incomingDay != _todayKey()) return;

    final base = data['baseDeviceSteps'];
    final steps = data['dailySteps'];
    final goal = data['stepsGoal'];

    _dayKey = incomingDay!;
    _baseDeviceSteps = base is num ? base.toInt() : null;
    _dailySteps = steps is num ? steps.toInt() : 0;
    _stepsGoal = goal is num ? goal.toInt() : _stepsGoal;
    _stepsLabel = data['stepsLabel']?.toString() ?? _stepsLabel;
    _notificationBody =
        data['notificationBody']?.toString() ?? _notificationBody;
    unawaited(_persistState());
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Sensor events, not a polling timer, drive step updates.
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    await _persistState();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}

class GoalCalculatorFallback {
  static const int steps = 7500;
}
