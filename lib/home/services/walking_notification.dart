// lib/home/services/walking_notification.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

/// باید top-level باشد تا اکشن نوتیف در بک‌گراند هم کار کند
@pragma('vm:entry-point')
void walkingNotificationBackground(NotificationResponse response) {
  WalkingNotification.instance.handleAction(response);
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
        'body_paused': 'شمارش ۱ ساعت متوقف شد',
        'not_walking': 'پیاده‌روی نمی‌کنی؟',
        'channel': 'پیاده‌روی',
        'channel_desc': 'شمارش زنده قدم',
      },
      'en': {
        'title_suffix': 'steps',
        'body': 'A few steps each day keeps the doctor away',
        'body_paused': 'Counting paused for 1 hour',
        'not_walking': 'Not walking?',
        'channel': 'Walking',
        'channel_desc': 'Live step count',
      },
      'fr': {
        'title_suffix': 'pas',
        'body': 'Quelques pas chaque jour éloignent le médecin',
        'body_paused': 'Comptage en pause 1 heure',
        'not_walking': 'Pas en train de marcher ?',
        'channel': 'Marche',
        'channel_desc': 'Compteur de pas en direct',
      },
    };
    return m[_lang]?[key] ?? m['en']![key]!;
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
      onDidReceiveNotificationResponse: handleAction,
      onDidReceiveBackgroundNotificationResponse:
          walkingNotificationBackground,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _t('channel'),
        description: _t('channel_desc'),
        importance: Importance.low,
      ),
    );

    await Permission.notification.request();
    _ready = true;
    StepTracker.instance.addListener(_onTracker);
  }

  void _onTracker() {
    if (!_ready || isSuppressed) return;
    final t = StepTracker.instance;
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
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      category: AndroidNotificationCategory.progress,
      actions: paused
          ? <AndroidNotificationAction>[]
          : <AndroidNotificationAction>[
              AndroidNotificationAction(
                _actionNotWalking,
                _t('not_walking'),
                showsUserInterface: false,
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

  /// هم از foreground و هم background صدا زده می‌شود
  void handleAction(NotificationResponse response) {
    final id = response.actionId;
    if (id == _actionNotWalking) {
      _suppressedUntil = DateTime.now().add(const Duration(hours: 1));
      StepTracker.instance.pauseWalkingDetection();
      final t = StepTracker.instance;
      // بلافاصله متن نوتیف را عوض کن تا کاربر بفهمد کار کرده
      _update(t.steps, t.stepsGoal, paused: true);
      return;
    }
  }

  void onUserCleared() {
    _userCleared = true;
  }

  void onAppResumed() {
    if (_suppressedUntil != null) {
      _suppressedUntil = null;
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
