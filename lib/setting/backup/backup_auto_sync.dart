// lib/setting/backup/backup_auto_sync.dart
// When auto-sync is on, upload once per local day after day key changes.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:helsa/setting/backup/google_drive_backup.dart';
import 'package:helsa/setting/storage/settings_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';

class BackupAutoSync {
  BackupAutoSync._();
  static final BackupAutoSync instance = BackupAutoSync._();

  static const _pwKey = 'helsa_backup_password';
  final _secure = const FlutterSecureStorage();

  bool _running = false;

  Future<void> savePassword(String password) async {
    await _secure.write(key: _pwKey, value: password);
  }

  Future<void> clearPassword() async {
    await _secure.delete(key: _pwKey);
  }

  Future<String?> readPassword() => _secure.read(key: _pwKey);

  /// Call on app resume / after steps day rollover.
  Future<void> maybeRunEndOfDay() async {
    if (_running) return;
    try {
      await SettingsStore.open();
      if (!SettingsStore.autoSyncEnabled) return;
      if (!GoogleDriveBackup.instance.isSignedIn) {
        // Try silent restore of session
        try {
          await GoogleDriveBackup.instance.signInWithGoogle();
        } catch (_) {}
        if (!GoogleDriveBackup.instance.isSignedIn) return;
      }

      await StepsStore.open();
      final today = StepsStore.currentDayKey;
      final last = SettingsStore.lastAutoSyncDayKey;
      // Sync for the day that just ended: when we are on a new day vs last sync.
      if (last == today) return;

      final password = await readPassword();
      if (password == null || password.length < 6) {
        debugPrint('BackupAutoSync: no stored password');
        return;
      }

      _running = true;
      await GoogleDriveBackup.instance.uploadEncrypted(password);
      await SettingsStore.setLastAutoSyncDayKey(today);
      debugPrint('BackupAutoSync: uploaded for day $today');
    } catch (e, st) {
      debugPrint('BackupAutoSync.maybeRunEndOfDay: $e\n$st');
    } finally {
      _running = false;
    }
  }

  /// Manual "Sync now" (same upload path).
  Future<void> syncNow(String password) async {
    await savePassword(password);
    await GoogleDriveBackup.instance.uploadEncrypted(password);
    try {
      await StepsStore.open();
      await SettingsStore.setLastAutoSyncDayKey(StepsStore.currentDayKey);
    } catch (_) {}
  }
}
