// lib/home/services/health_permissions.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthPermissions {
  HealthPermissions._();

  /// Requests only the runtime permissions required by step counting.
  static Future<HealthPermissionResult> requestAll() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const HealthPermissionResult(
        activity: true,
        notification: true,
      );
    }

    final activity = await Permission.activityRecognition.request();
    final notification = await Permission.notification.request();

    return HealthPermissionResult(
      activity: activity.isGranted,
      notification: notification.isGranted || notification.isLimited,
    );
  }

  static Future<bool> ensureActivity() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;
    final requested = await Permission.activityRecognition.request();
    return requested.isGranted;
  }

  static Future<bool> ensureNotification() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }
}

class HealthPermissionResult {
  final bool activity;
  final bool notification;

  const HealthPermissionResult({
    required this.activity,
    required this.notification,
  });

  bool get readyForSteps => activity;
  bool get readyForBackgroundNotify => activity && notification;
}
