// lib/home/services/walking_notification.dart
// سازگار با flutter_local_notifications 19.x (آرگومان positional)
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

class WalkingNotification {
  WalkingNotification._();
  static final WalkingNotification instance = WalkingNotification._();

  static const int _notifId = 4201;
  static const String _channelId = 'helsa_walking';
  static const String _actionYes = 'WALK_YES';
  static const String _actionNo = 'WALK_NO';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  bool _confirmed = false;
  DateTime? _suppressedUntil;

  String get _lang {
    final raw =
        (ProfileStore.profile?['language']?.toString() ?? 'en').toLowerCase();
    if (raw.startsWith('fa')) return 'fa';
    if (raw.startsWith('fr')) return 'fr';
    return 'en';
  }

  String _t(String key) {
    const m = {
      'fa': {
        'ask': 'شما در حال پیاده‌روی هستید؟',
        'yes': 'بله',
        'no': 'خیر',
        'walking': 'در حال پیاده‌روی',
        'steps': 'قدم',
      },
      'en': {
        'ask': 'Are you walking?',
        'yes': 'Yes',
        'no': 'No',
        'walking': 'Walking',
        'steps': 'steps',
      },
      'fr': {
        'ask': 'Êtes-vous en train de marcher ?',
        'yes': 'Oui',
        'no': 'Non',
        'walking': 'Marche',
        'steps': 'pas',
      },
    };
    return m[_lang]?[key] ?? m['en']![key]!;
  }

  Future<void> init() async {
    if (kIsWeb) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 19.x: اولین آرگومان positional است
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onAction,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Walking',
        description: 'Live walking detection',
        importance: Importance.high,
      ),
    );

    await Permission.notification.request();

    _ready = true;
    StepTracker.instance.addListener(_onTracker);
  }

  void _onTracker() {
    final t = StepTracker.instance;
    if (!_ready) return;

    if (_suppressedUntil != null &&
        DateTime.now().isBefore(_suppressedUntil!)) {
      return;
    }
    if (_suppressedUntil != null &&
        DateTime.now().isAfter(_suppressedUntil!)) {
      _suppressedUntil = null;
      _confirmed = false;
    }

    if (t.isWalking) {
      _showOrUpdate(t.steps);
    } else if (!_confirmed) {
      cancel();
    } else {
      _showConfirmed(t.steps);
    }
  }

  Future<void> _showOrUpdate(int steps) async {
    if (_confirmed) {
      await _showConfirmed(steps);
      return;
    }

    final android = AndroidNotificationDetails(
      _channelId,
      'Walking',
      channelDescription: 'Walking detection',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          _actionYes,
          _t('yes'),
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          _actionNo,
          _t('no'),
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    // 19.x: show(id, title, body, details)
    await _plugin.show(
      _notifId,
      '$steps ${_t('steps')}',
      _t('ask'),
      NotificationDetails(android: android),
    );
  }

  Future<void> _showConfirmed(int steps) async {
    final android = AndroidNotificationDetails(
      _channelId,
      'Walking',
      channelDescription: 'Walking detection',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    await _plugin.show(
      _notifId,
      '$steps ${_t('steps')}',
      _t('walking'),
      NotificationDetails(android: android),
    );
  }

  void _onAction(NotificationResponse response) {
    final action = response.actionId;
    if (action == _actionYes) {
      _confirmed = true;
      _showConfirmed(StepTracker.instance.steps);
    } else if (action == _actionNo) {
      _confirmed = false;
      _suppressedUntil = DateTime.now().add(const Duration(hours: 1));
      StepTracker.instance.pauseWalkingDetection();
      cancel();
    }
  }

  Future<void> cancel() async {
    // 19.x: cancel(id) positional
    await _plugin.cancel(_notifId);
  }
}
