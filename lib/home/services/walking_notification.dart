// lib/home/services/walking_notification.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

@pragma('vm:entry-point')
void walkingNotificationBackground(NotificationResponse response) {
  if (response.actionId == WalkingNotification.actionNotWalking) {
    _handleNotWalkingAction();
  }
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
  /// کانال جدید تا تنظیمات قدیمی کش‌شده خراب نکند
  static const String _channelId = 'helsa_walking_v3';
  static const String actionNotWalking = 'NOT_WALKING';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _userCleared = false;
  bool _lastPaused = false;
  int _lastShownSteps = -1;

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
        'body_paused': 'شمارش ۱ ساعت متوقف شد',
        // متن دکمه کوتاه تا مثل دکمه دیده شود نه جمله
        'not_walking': 'متوقف',
        'channel': 'پیاده‌روی Helsa',
        'channel_desc': 'شمارش زنده قدم و دکمه توقف',
      },
      'en': {
        'title_suffix': 'steps',
        'body': 'A few steps each day keeps the doctor away',
        'body_paused': 'Counting paused for 1 hour',
        'not_walking': 'Pause',
        'channel': 'Helsa Walking',
        'channel_desc': 'Live steps and pause action',
      },
      'fr': {
        'title_suffix': 'pas',
        'body': 'Quelques pas chaque jour éloignent le médecin',
        'body_paused': 'Comptage en pause 1 heure',
        'not_walking': 'Pause',
        'channel': 'Marche Helsa',
        'channel_desc': 'Pas en direct et bouton pause',
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
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse:
          walkingNotificationBackground,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // کانال جدا با اهمیت بالا — دکمه‌ها بهتر دیده می‌شوند
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _t('channel'),
        description: _t('channel_desc'),
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    );

    await Permission.notification.request();
    _ready = true;

    if (StepsStore.isCountingPaused) {
      StepTracker.instance.pauseWalkingDetection();
      final t = StepTracker.instance;
      await _update(t.steps, t.stepsGoal, paused: true, force: true);
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

  Future<void> _update(
    int steps,
    int goal, {
    required bool paused,
    bool force = false,
  }) async {
    if (!_ready) return;

    // از آپدیت هر ثانیه بی‌خود جلوگیری کن مگر قدم/وضعیت عوض شده
    if (!force &&
        steps == _lastShownSteps &&
        paused == _lastPaused) {
      return;
    }
    _lastShownSteps = steps;
    _lastPaused = paused;

    // دکمه اکشن واقعی (نه متن body)
    final actions = paused
        ? <AndroidNotificationAction>[]
        : <AndroidNotificationAction>[
            AndroidNotificationAction(
              actionNotWalking,
              _t('not_walking'),
              // false = اکشن در پس‌زمینه هندل شود، مثل دکمه سیستم
              showsUserInterface: false,
              cancelNotification: false,
              // روی اندروید ۱۳+ بهتر به‌عنوان دکمه دیده می‌شود
            ),
          ];

    final android = AndroidNotificationDetails(
      _channelId,
      _t('channel'),
      channelDescription: _t('channel_desc'),
      importance: Importance.high,
      priority: Priority.high,
      // ongoing روی بعضی MIUI دکمه را قورت می‌دهد → فقط وقتی pause نیست
      // از ongoing سبک استفاده می‌کنیم ولی autoCancel false
      ongoing: !paused,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      // body جدا از دکمه
      styleInformation: BigTextStyleInformation(
        paused ? _t('body_paused') : _t('body'),
        contentTitle: '$steps / $goal ${_t('title_suffix')}',
        summaryText: paused ? null : _t('not_walking'),
      ),
      actions: actions,
    );

    await _plugin.show(
      _notifId,
      '$steps / $goal ${_t('title_suffix')}',
      paused ? _t('body_paused') : _t('body'),
      NotificationDetails(android: android),
      // payload کمکی اگر actionId نرسید
      payload: paused ? 'paused' : 'active',
    );
  }

  void handleAction(NotificationResponse response) {
    final id = response.actionId;
    final type = response.notificationResponseType;

    // فقط اکشن دکمه — نه لمس خود نوتیف
    final isAction = type == NotificationResponseType.selectedNotificationAction ||
        (id != null && id.isNotEmpty && id == actionNotWalking);

    if (id == actionNotWalking || isAction && id == actionNotWalking) {
      _applyPause();
      return;
    }

    // بعضی OEM فقط actionId می‌فرستند
    if (id == actionNotWalking) {
      _applyPause();
    }
  }

  Future<void> _applyPause() async {
    try {
      await StepsStore.open();
      await StepsStore.setPauseForOneHour();
    } catch (_) {}
    try {
      StepTracker.instance.pauseWalkingDetection();
    } catch (_) {}
    final t = StepTracker.instance;
    await _update(t.steps, t.stepsGoal, paused: true, force: true);
  }

  void onUserCleared() {
    _userCleared = true;
  }

  void onAppResumed() {
    // توقف ۱ ساعته واقعی است — با باز کردن اپ لغو نمی‌شود
    final paused = StepsStore.isCountingPaused;
    if (paused) {
      StepTracker.instance.pauseWalkingDetection();
      final t = StepTracker.instance;
      _update(t.steps, t.stepsGoal, paused: true, force: true);
      return;
    }
    // اگر ساعت تمام شده بود، resume
    StepTracker.instance.resumeWalkingDetection(force: true);
    final t = StepTracker.instance;
    if (t.steps > 0 || t.isWalking) {
      _userCleared = false;
      _update(t.steps, t.stepsGoal, paused: false, force: true);
    }
  }

  Future<void> cancel() async {
    await _plugin.cancel(_notifId);
    _userCleared = true;
  }
}
