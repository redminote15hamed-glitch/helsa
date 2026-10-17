// lib/home/services/health_permissions.dart
// هر ۴ لایه دسترسی سلامت Helsa
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthPermissions {
  HealthPermissions._();

  /// Activity + Notification + (اختیاری) باتری
  static Future<HealthPermissionResult> requestAll() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const HealthPermissionResult(
        activity: true,
        notification: true,
        battery: true,
      );
    }

    final activity = await Permission.activityRecognition.request();
    final sensors = await Permission.sensors.request();
    final activityOk = activity.isGranted || sensors.isGranted;

    final notif = await Permission.notification.request();
    final notifOk = notif.isGranted || notif.isLimited;

    // ۴) معافیت بهینه‌سازی باتری — دیالوگ سیستم
    var batteryOk = true;
    final bat = await Permission.ignoreBatteryOptimizations.status;
    if (!bat.isGranted) {
      final r = await Permission.ignoreBatteryOptimizations.request();
      batteryOk = r.isGranted;
    }

    return HealthPermissionResult(
      activity: activityOk,
      notification: notifOk,
      battery: batteryOk,
    );
  }

  static Future<bool> ensureActivity() async {
    if (kIsWeb) return true;
    var s = await Permission.activityRecognition.status;
    if (s.isGranted) return true;
    s = await Permission.activityRecognition.request();
    if (s.isGranted) return true;
    final sensors = await Permission.sensors.request();
    return sensors.isGranted;
  }

  static Future<bool> ensureNotification() async {
    if (kIsWeb) return true;
    final s = await Permission.notification.request();
    return s.isGranted || s.isLimited;
  }
}

class HealthPermissionResult {
  final bool activity;
  final bool notification;
  final bool battery;

  const HealthPermissionResult({
    required this.activity,
    required this.notification,
    required this.battery,
  });

  bool get readyForSteps => activity;
  bool get readyForBackgroundNotify => activity && notification;
}
