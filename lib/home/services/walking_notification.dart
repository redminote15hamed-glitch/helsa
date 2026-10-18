// lib/home/services/walking_notification.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

@pragma('vm:entry-point')
void walkingNotificationBackground(NotificationResponse response) {
  // در isolate بک‌گراند: فقط فلگ Hive را بنویس
  _handleNotWalkingAction();
}

Future<void> _handleNotWalkingAction() async {
  try {
    await StepsStore.open();
    await StepsStore.setPauseForOneHour();
  } catch (_) {}
  try {
    StepTracker.instance.pauseWalkingDetection();
  } catch (_) {}
}

class WalkingNotification {
  WalkingNotification._();
  static final WalkingNotification instance = WalkingNotification._();

  static const int _notifId = 4201;
  static const String _channelId = 'helsa_walking';
  static const String _actionNotWalking = 'NOT_WALKING';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _userCleared = false;

  bool get isSuppressed => StepsStore.isCountingPaused;

  String get _lang {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }

  String _t(String key) {
    const m = {
      'fa': {
        'title_suffix': 'قدم',
        'body': 'قدم زدن برای سلامتی عالیه، حتی کم',
        'body_paused': 'شمارش ۱ ساعت متوقف شد — قدم جدید لحاظ نمی‌شود',
        'not_walking': 'پیاده‌روی نمی‌کنی؟',
        'channel': 'پیاده‌روی',
        'channel_desc': 'شمارش زنده قدم',
      },
      'en': {
        'title_suffix': 'steps',
        'body': 'A few steps each day keeps the doctor away',
        'body_paused': 'Counting paused 1 hour — new steps ignored',
        'not_walking': 'Not walking?',
        'channel': 'Walking',
        'channel_desc': 'Live step count',
      },
      'fr': {
        'title_suffix': 'pas',
        'body': 'Quelques pas chaque jour éloignent le médecin',
        'body_paused': 'Comptage en pause 1 h — nouveaux pas ignorés',
        'not_walking': 'Pas en train de marcher ?',
        'channel': 'Marche',
        'channel_desc': 'Compteur de pas en direct',
      },
    };
    return m[_lang]?[key] ?? m['en']![key]!;
  }

  Future<void> init() async {
    if (kIsWeb) return;

    try {
      await StepsStore.open();
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        handleAction(response);
      },
      onDidReceiveBackgroundNotificationResponse:
          walkingNotificationBackground,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Walking',
        description: 'Live step count',
        importance: Importance.high,
      ),
    );

    await Permission.notification.request();
    _ready = true;

    // اگر از قبل pause بود، همان وضعیت را نشان بده
    if (StepsStore.isCountingPaused) {
      StepTracker.instance.pauseWalkingDetection();
      final t = StepTracker.instance;
      await _update(t.steps, t.stepsGoal, paused: true);
    }

    StepTracker.instance.addListener(_onTracker);
  }

  void _onTracker() {
    if (!_ready) return;
    final t = StepTracker.instance;
    final paused = StepsStore.isCountingPaused || t.isPaused;
    if (paused) {
      _update(t.steps, t.stepsGoal, paused: true);
      return;
    }
    if (t.isWalking || t.steps > 0) {
      if (_userCleared && !t.isWalking) return;
      if (_userCleared && t.isWalking) _userCleared = false;
      _update(t.steps, t.stepsGoal, paused: false);
    }
  }

  Future<void> _update(int steps, int goal, {required bool paused}) async {
    if (!_ready) return;

    final android = AndroidNotificationDetails(
      _channelId,
      _t('channel'),
      channelDescription: _t('channel_desc'),
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      category: AndroidNotificationCategory.workout,
      actions: paused
          ? <AndroidNotificationAction>[]
          : <AndroidNotificationAction>[
              AndroidNotificationAction(
                _actionNotWalking,
                _t('not_walking'),
                showsUserInterface: true,
                cancelNotification: false,
              ),
            ],
    );

    await _plugin.show(
      _notifId,
      '$steps / $goal ${_t('title_suffix')}',
      paused ? _t('body_paused') : _t('body'),
      NotificationDetails(android: android),
    );
  }

  void handleAction(NotificationResponse response) {
    final id = response.actionId;
    // بعضی گوشی‌ها actionId خالی می‌فرستند اگر روی بدنه بزنند
    if (id == _actionNotWalking ||
        (id == null &&
            response.notificationResponseType ==
                NotificationResponseType.selectedNotificationAction)) {
      _applyPause();
      return;
    }
    if (id == _actionNotWalking) {
      _applyPause();
    }
  }

  Future<void> _applyPause() async {
    await StepsStore.open();
    await StepsStore.setPauseForOneHour();
    StepTracker.instance.pauseWalkingDetection();
    final t = StepTracker.instance;
    await _update(t.steps, t.stepsGoal, paused: true);
  }

  void onUserCleared() {
    _userCleared = true;
  }

  void onAppResumed() {
    // با برگشت به اپ قبل از ۱ ساعت: شمارش دوباره فعال
    if (StepsStore.isCountingPaused) {
      StepsStore.clearPause();
      StepTracker.instance.resumeWalkingDetection();
    }
    final t = StepTracker.instance;
    if (t.steps > 0 || t.isWalking) {
      _userCleared = false;
      _update(t.steps, t.stepsGoal, paused: false);
    }
  }

  Future<void> cancel() async {
    await _plugin.cancel(_notifId);
    _userCleared = true;
  }
}
