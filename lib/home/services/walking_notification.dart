// lib/home/services/walking_notification.dart
// Single ongoing notification — updates in place (same id), app language, one action.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

class WalkingNotification {
  WalkingNotification._();
  static final WalkingNotification instance = WalkingNotification._();

  static const int _notifId = 4201;
  static const String _channelId = 'helsa_walking';
  static const String _actionNotWalking = 'NOT_WALKING';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  /// User dismissed the notification (swipe/clear). Do not show until walking again.
  bool _userCleared = false;
  /// Pause counting until this time (after "not walking?").
  DateTime? _suppressedUntil;

  bool get isSuppressed {
    if (_suppressedUntil == null) return false;
    if (DateTime.now().isAfter(_suppressedUntil!)) {
      _suppressedUntil = null;
      return false;
    }
    return true;
  }

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
        'not_walking': 'پیاده‌روی نمی‌کنی؟',
        'channel': 'پیاده‌روی',
        'channel_desc': 'شمارش زنده قدم',
      },
      'en': {
        'title_suffix': 'steps',
        'body': 'A few steps each day keeps the doctor away',
        'not_walking': 'Not walking?',
        'channel': 'Walking',
        'channel_desc': 'Live step count',
      },
      'fr': {
        'title_suffix': 'pas',
        'body': 'Quelques pas chaque jour éloignent le médecin',
        'not_walking': 'Pas en train de marcher ?',
        'channel': 'Marche',
        'channel_desc': 'Compteur de pas en direct',
      },
    };
    final lang = _lang;
    return m[lang]?[key] ?? m['en']![key]!;
  }

  Future<void> init() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onAction,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _t('channel'),
        description: _t('channel_desc'),
        importance: Importance.low, // silent refresh, no pop spam
      ),
    );

    await Permission.notification.request();
    _ready = true;

    StepTracker.instance.addListener(_onTracker);
  }

  void _onTracker() {
    if (!_ready || isSuppressed) return;

    final t = StepTracker.instance;
    // فقط وقتی قدم/وضعیت عوض می‌شود همان نوتیف را آپدیت کن
    if (t.isWalking || t.steps > 0) {
      if (_userCleared && !t.isWalking) return;
      if (_userCleared && t.isWalking) {
        _userCleared = false; // دوباره راه رفت → دوباره نشان بده
      }
      _update(t.steps, t.stepsGoal);
    }
    // وقتی ایستاد: نوتیف را حذف نکن — همان آخرین عدد می‌ماند تا کاربر clear کند
  }

  /// Refresh same notification id (no new banner spam).
  Future<void> _update(int steps, int goal) async {
    if (!_ready) return;

    final android = AndroidNotificationDetails(
      _channelId,
      _t('channel'),
      channelDescription: _t('channel_desc'),
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true, // فقط بار اول صدا/ویبره
      showWhen: false,
      category: AndroidNotificationCategory.progress,
      // آیکون کوچک نوتیف = launcher
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _actionNotWalking,
          _t('not_walking'),
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
    );

    final title = '$steps / $goal ${_t('title_suffix')}';
    final body = _t('body');

    // همان id → فقط محتوا رفرش می‌شود
    await _plugin.show(
      _notifId,
      title,
      body,
      NotificationDetails(android: android),
    );
  }

  void _onAction(NotificationResponse response) {
    // کاربر نوتیف را clear کرده (dismiss)
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      // tap on body — optional: open app (system default)
      return;
    }

    if (response.actionId == _actionNotWalking) {
      _suppressedUntil = DateTime.now().add(const Duration(hours: 1));
      StepTracker.instance.pauseWalkingDetection();
      // نوتیف را نگه می‌داریم با آخرین عدد؛ شمارش متوقف
      return;
    }
  }

  /// Call when system reports notification was dismissed (if wired).
  void onUserCleared() {
    _userCleared = true;
  }

  /// User opened the app during suppress window → resume counting.
  void onAppResumed() {
    if (_suppressedUntil != null) {
      _suppressedUntil = null;
      StepTracker.instance.resumeWalkingDetection();
    }
    final t = StepTracker.instance;
    if (t.steps > 0 || t.isWalking) {
      _userCleared = false;
      _update(t.steps, t.stepsGoal);
    }
  }

  Future<void> cancel() async {
    await _plugin.cancel(_notifId);
    _userCleared = true;
  }
}
