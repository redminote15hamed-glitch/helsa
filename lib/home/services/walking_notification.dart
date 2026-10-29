// lib/home/services/walking_notification.dart
// Ù†ÙˆØªÛŒÙ Ø¯ÙˆÙ… Ø­Ø°Ù Ø´Ø¯ â€” ÙÙ‚Ø· StepForeground ÛŒÚ© Ù†ÙˆØªÛŒÙ Ø¯Ø§Ø±Ø¯.
// Ø§ÛŒÙ† Ú©Ù„Ø§Ø³ Ø¨Ø±Ø§ÛŒ Ø³Ø§Ø²Ú¯Ø§Ø±ÛŒ Ø¨Ø§ home_screen Ø¨Ø§Ù‚ÛŒ Ø§Ø³Øª.
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WalkingNotification {
  WalkingNotification._();
  static final WalkingNotification instance = WalkingNotification._();

  static const int _oldNotifId = 4201;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false; // kept for future gate

  Future<void> init() async {
    if (kIsWeb) {
      _ready = true; // ignore: unused_field
      return;
    }
    // ÙÙ‚Ø· Ú©Ø§Ù†Ø³Ù„ Ú©Ø±Ø¯Ù† Ù†ÙˆØªÛŒÙ Ù‚Ø¯ÛŒÙ…ÛŒ Â«Ù…ØªÙˆÙ‚ÙÂ» / dual
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: androidInit),
      );
      await _plugin.cancel(_oldNotifId);
      // Ù‡Ø± id Ù‚Ø¯ÛŒÙ…ÛŒ Ø¯ÛŒÚ¯Ø±
      await _plugin.cancel(4201);
    } catch (_) {}
    _ready = true; // ignore: unused_field
  }

  void handleAction(NotificationResponse response) {}

  void onUserCleared() {}

  void onAppResumed() {
    // Ù†ÙˆØªÛŒÙ Ø²Ù†Ø¯Ù‡ Ø¨Ø§ StepForeground Ø§Ø³Øª
  }

  Future<void> cancel() async {
    try {
      await _plugin.cancel(_oldNotifId);
    } catch (_) {}
  }
}

