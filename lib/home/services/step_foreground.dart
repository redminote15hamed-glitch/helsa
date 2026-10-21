// lib/home/services/step_foreground.dart
// نوتیف از isolate اصلی آپدیت می‌شود (نه isolate سرویس)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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
  }

  /// وصل به StepTracker روی isolate اصلی
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
    final t = StepTracker.instance;
    // هر تغییر قدم یا هدف → آپدیت نوتیف
    if (t.steps != _lastSteps || t.stepsGoal != _lastGoal) {
      refresh(force: true);
    }
  }

  Future<bool> start() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    // pause قدیمی (از نسخه قبل) را پاک کن تا قدم بشمرد
    try {
      await StepsStore.open();
      if (StepsStore.isCountingPaused) {
        await StepsStore.clearPause();
        await StepTracker.instance.resumeWalkingDetection(force: true);
      }
    } catch (_) {}

    attachTracker();

    if (await FlutterForegroundTask.isRunningService) {
      await refresh(force: true);
      return true;
    }

    final t = StepTracker.instance;
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: _title(t.steps, t.stepsGoal),
      notificationText: _body(),
      notificationIcon: _notifIcon,
      callback: stepForegroundCallback,
    );
    final ok = result is ServiceRequestSuccess;
    if (ok) {
      _lastSteps = t.steps;
      _lastGoal = t.stepsGoal;
    }
    return ok;
  }

  /// اگر کاربر نوتیف را بسته → دوباره روشن کن
  Future<void> ensureRunning() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await start();
      } else {
        await refresh(force: true);
      }
    } catch (_) {
      try {
        await start();
      } catch (_) {}
    }
  }

  /// از UI بعد از تغییر هدف / قدم صدا بزن
  Future<void> refresh({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final t = StepTracker.instance;
    if (!force && t.steps == _lastSteps && t.stepsGoal == _lastGoal) {
      return;
    }
    _lastSteps = t.steps;
    _lastGoal = t.stepsGoal;

    try {
      if (!await FlutterForegroundTask.isRunningService) {
        // نوتیف بسته شده بود → دوباره استارت
        await start();
        return;
      }
      await FlutterForegroundTask.updateService(
        notificationTitle: _title(t.steps, t.stepsGoal),
        notificationText: _body(),
        notificationIcon: _notifIcon,
      );
    } catch (_) {}
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    detachTracker();
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
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
    final lang = _lang();
    final suffix = lang == 'fa'
        ? 'قدم'
        : lang == 'fr'
            ? 'pas'
            : 'steps';
    return '$steps / $goal $suffix';
  }

  static String _body() {
    final lang = _lang();
    if (lang == 'fa') return 'قدم زدن برای سلامتی عالیه، حتی کم';
    if (lang == 'fr') return 'Quelques pas chaque jour éloignent le médecin';
    return 'A few steps each day keeps the doctor away';
  }
}

class StepTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // isolate جدا — فقط برای زنده ماندن سرویس
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // آپدیت اصلی از isolate UI است؛ اینجا فقط heartbeat
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
