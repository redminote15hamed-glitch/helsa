// lib/home/services/step_foreground.dart
// تنها نوتیف پس‌زمینه — قدم زنده / هدف
// آیکون: drawable/ic_notification + meta-data در AndroidManifest
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/storage/meta_store.dart';

@pragma('vm:entry-point')
void stepForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(StepTaskHandler());
}

class StepForeground {
  StepForeground._();
  static final StepForeground instance = StepForeground._();

  static const int _serviceId = 4202;

  /// باید با meta-data داخل AndroidManifest یکی باشد
  static const String _iconMeta =
      'com.example.helsa.service.NOTIFICATION_ICON';

  static const NotificationIcon _notifIcon = NotificationIcon(
    metaDataName: _iconMeta,
    backgroundColor: Colors.transparent,
  );

  void init() {
    if (kIsWeb || !Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'helsa_step_service_v2',
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
        eventAction: ForegroundTaskEventAction.repeat(2000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<bool> start() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (await FlutterForegroundTask.isRunningService) {
      _pushUpdate();
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
    return result is ServiceRequestSuccess;
  }

  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  void _pushUpdate() {
    final t = StepTracker.instance;
    FlutterForegroundTask.updateService(
      notificationTitle: _title(t.steps, t.stepsGoal),
      notificationText: _body(),
      notificationIcon: _notifIcon,
    );
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
    try {
      await StepTracker.instance.init();
    } catch (_) {}
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final t = StepTracker.instance;
    FlutterForegroundTask.updateService(
      notificationTitle: StepForeground._title(t.steps, t.stepsGoal),
      notificationText: StepForeground._body(),
      notificationIcon: StepForeground._notifIcon,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
