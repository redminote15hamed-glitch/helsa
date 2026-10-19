// lib/home/services/walking_notification.dart
// نوتیف دوم حذف شد — فقط StepForeground یک نوتیف دارد.
// این کلاس برای سازگاری با home_screen باقی است.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WalkingNotification {
  WalkingNotification._();
  static final WalkingNotification instance = WalkingNotification._();

  static const int _oldNotifId = 4201;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) {
      _ready = true;
      return;
    }
    // فقط کانسل کردن نوتیف قدیمی «متوقف» / dual
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidInit),
      );
      await _plugin.cancel(_oldNotifId);
      // هر id قدیمی دیگر
      await _plugin.cancel(4201);
    } catch (_) {}
    _ready = true;
  }

  void handleAction(NotificationResponse response) {}

  void onUserCleared() {}

  void onAppResumed() {
    // نوتیف زنده با StepForeground است
  }

  Future<void> cancel() async {
    try {
      await _plugin.cancel(_oldNotifId);
    } catch (_) {}
  }
}
