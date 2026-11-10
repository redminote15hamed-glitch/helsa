// lib/setting/backup/backup_service.dart
// Local encrypted backup create / restore (+ helpers for Drive layer).
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:helsa/setting/backup/backup_crypto.dart';
import 'package:helsa/setting/backup/backup_payload.dart';
import 'package:helsa/setting/storage/settings_store.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String filePrefix = 'helsa-backup';
  static const String fileExt = 'helsa';

  /// Build encrypted bytes for a full backup protected by [password].
  Future<Uint8List> buildEncryptedBackup(String password) async {
    if (password.trim().length < 6) {
      throw StateError('backup_weak_password');
    }
    final map = await BackupPayload.exportMap();
    final plain = BackupPayload.encodePlainBytes(map);
    return BackupCrypto.encrypt(plain, password);
  }

  /// Decrypt and restore from [bytes].
  Future<void> restoreFromEncrypted(Uint8List bytes, String password) async {
    if (password.trim().isEmpty) {
      throw StateError('backup_bad_password');
    }
    final plain = BackupCrypto.decrypt(bytes, password);
    final map = BackupPayload.decodePlainBytes(plain);
    await BackupPayload.importMap(map);
  }

  /// Write encrypted backup to app documents; returns absolute path.
  Future<String> saveLocalEncrypted(String password) async {
    final bytes = await buildEncryptedBackup(password);
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}${Platform.pathSeparator}backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .substring(0, 15);
    final path =
        '${backupDir.path}${Platform.pathSeparator}$filePrefix-$stamp.$fileExt';
    await File(path).writeAsBytes(bytes, flush: true);
    await _markLocalBackupTime();
    return path;
  }

  /// Restore from a local file path.
  Future<void> restoreLocalFile(String path, String password) async {
    final f = File(path);
    if (!await f.exists()) throw StateError('backup_missing');
    final bytes = await f.readAsBytes();
    await restoreFromEncrypted(Uint8List.fromList(bytes), password);
  }

  /// List local backup files (newest first).
  Future<List<File>> listLocalBackups() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}${Platform.pathSeparator}backups');
      if (!await backupDir.exists()) return [];
      final files = await backupDir
          .list()
          .where((e) => e is File && e.path.endsWith('.$fileExt'))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (e, st) {
      debugPrint('listLocalBackups: $e\n$st');
      return [];
    }
  }

  Future<void> _markLocalBackupTime() async {
    try {
      await SettingsStore.open();
      await SettingsStore.setLastBackupAt(DateTime.now().toUtc().toIso8601String());
    } catch (_) {}
  }

  Future<void> markDriveBackupTime() => _markLocalBackupTime();
}
