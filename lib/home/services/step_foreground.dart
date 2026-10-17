// lib/home/services/step_foreground.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  void init() {
    if (kIsWeb || !Platform.isAndroid) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'helsa_step_service',
        channelName: 'Helsa Steps',
        channelDescription: 'Background step counting',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(15000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<bool> start() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (await FlutterForegroundTask.isRunningService) return true;

    final lang = _lang();
    final title = lang == 'fa'
        ? 'شمارش قدم Helsa'
        : lang == 'fr'
            ? 'Compteur de pas Helsa'
            : 'Helsa step counting';
    final text = lang == 'fa'
        ? 'در حال ردیابی فعالیت…'
        : lang == 'fr'
            ? 'Suivi de l’activité…'
            : 'Tracking activity…';

    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: title,
      notificationText: text,
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

  static String _lang() {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }
}

class StepTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await StepTracker.instance.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    final t = StepTracker.instance;
    final lang = StepForeground._lang();
    final suffix = lang == 'fa'
        ? 'قدم'
        : lang == 'fr'
            ? 'pas'
            : 'steps';
    final body = t.isPaused
        ? (lang == 'fa'
            ? 'شمارش موقتاً متوقف است'
            : lang == 'fr'
                ? 'Comptage en pause'
                : 'Counting paused')
        : (lang == 'fa'
            ? 'قدم زدن برای سلامتی عالیه، حتی کم'
            : lang == 'fr'
                ? 'Quelques pas chaque jour éloignent le médecin'
                : 'A few steps each day keeps the doctor away');

    FlutterForegroundTask.updateService(
      notificationTitle: '${t.steps} / ${t.stepsGoal} $suffix',
      notificationText: body,
    );
  }

  // API جدید پکیج: دو آرگومان
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
