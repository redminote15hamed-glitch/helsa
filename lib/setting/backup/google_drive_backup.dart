// lib/setting/backup/google_drive_backup.dart
// Optional Google Sign-In + encrypted backup in Drive App Data folder.

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:helsa/setting/backup/backup_service.dart';
import 'package:helsa/setting/storage/settings_store.dart';

class GoogleDriveBackup {
  GoogleDriveBackup._();
  static final GoogleDriveBackup instance = GoogleDriveBackup._();

  static const _scopes = <String>[
    drive.DriveApi.driveAppdataScope,
  ];

  GoogleSignIn _signIn = GoogleSignIn(scopes: _scopes);

  GoogleSignInAccount? get currentUser => _signIn.currentUser;

  bool get isSignedIn => _signIn.currentUser != null;

  String? get email => _signIn.currentUser?.email;

  void _rebuildSignIn({String? emailHint}) {
    _signIn = GoogleSignIn(scopes: _scopes);
    // Note: google_sign_in uses hostedDomain / login hint via signInSilently
    // on some platforms; we still pass preferred email into Settings.
    if (emailHint != null && emailHint.isNotEmpty) {
      // no-op constructor-wise on all platforms; email is stored for UX
    }
  }

  /// Standard Google account picker (Sign in with Google).
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) return false;
    try {
      _rebuildSignIn();
      final existing = await _signIn.signInSilently();
      if (existing != null) {
        await _persistEmail(existing.email);
        return true;
      }
      final account = await _signIn.signIn();
      if (account == null) return false;
      await _persistEmail(account.email);
      return true;
    } catch (e, st) {
      debugPrint('GoogleDriveBackup.signInWithGoogle: $e\n$st');
      rethrow;
    }
  }

  /// User typed a Gmail → store as preferred, then open Google sign-in.
  /// Google still owns the real authentication (no password to Helsa).
  Future<bool> signInWithEmail(String email) async {
    if (kIsWeb) return false;
    final cleaned = email.trim().toLowerCase();
    if (!_looksLikeEmail(cleaned)) {
      throw StateError('backup_bad_email');
    }
    try {
      await SettingsStore.open();
      await SettingsStore.setPreferredGoogleEmail(cleaned);
      _rebuildSignIn(emailHint: cleaned);

      // Try silent first (already signed-in same account).
      final silent = await _signIn.signInSilently();
      if (silent != null) {
        await _persistEmail(silent.email);
        return true;
      }

      final account = await _signIn.signIn();
      if (account == null) return false;
      await _persistEmail(account.email);
      return true;
    } catch (e, st) {
      debugPrint('GoogleDriveBackup.signInWithEmail: $e\n$st');
      rethrow;
    }
  }

  bool _looksLikeEmail(String e) {
    return e.contains('@') && e.contains('.') && e.length >= 5;
  }

  Future<void> _persistEmail(String? email) async {
    try {
      await SettingsStore.open();
      await SettingsStore.setGoogleBackupEmail(email);
      if (email != null && email.isNotEmpty) {
        await SettingsStore.setPreferredGoogleEmail(email);
      }
    } catch (_) {}
  }

  /// Log out / disconnect Google from this app.
  Future<void> logOut() async {
    try {
      await _signIn.disconnect();
    } catch (_) {
      try {
        await _signIn.signOut();
      } catch (_) {}
    }
    try {
      await SettingsStore.open();
      await SettingsStore.setGoogleBackupEmail(null);
    } catch (_) {}
  }

  Future<drive.DriveApi> _api() async {
    var account = _signIn.currentUser;
    account ??= await _signIn.signInSilently();
    if (account == null) {
      throw StateError('backup_not_signed_in');
    }
    final httpClient = await _signIn.authenticatedClient();
    if (httpClient == null) {
      throw StateError('backup_not_signed_in');
    }
    return drive.DriveApi(httpClient);
  }

  Future<void> uploadEncrypted(String password) async {
    final bytes = await BackupService.instance.buildEncryptedBackup(password);
    final api = await _api();

    try {
      final listed = await api.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'helsa-backup' and trashed = false",
        $fields: 'files(id, name)',
      );
      for (final f in listed.files ?? const <drive.File>[]) {
        final id = f.id;
        if (id != null) {
          try {
            await api.files.delete(id);
          } catch (_) {}
        }
      }
    } catch (e, st) {
      debugPrint('Drive list/delete old: $e\n$st');
    }

    final stamp = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final meta = drive.File()
      ..name = 'helsa-backup-$stamp.helsa'
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream<List<int>>.fromIterable([bytes]),
      bytes.length,
      contentType: 'application/octet-stream',
    );

    await api.files.create(meta, uploadMedia: media);
    await BackupService.instance.markDriveBackupTime();
    await _persistEmail(_signIn.currentUser?.email);
  }

  Future<Uint8List?> downloadLatest() async {
    final api = await _api();
    final listed = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains 'helsa-backup' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
      orderBy: 'modifiedTime desc',
      pageSize: 5,
    );
    final files = listed.files ?? const <drive.File>[];
    if (files.isEmpty) return null;
    final id = files.first.id;
    if (id == null) return null;

    final client = await _signIn.authenticatedClient();
    if (client == null) throw StateError('backup_not_signed_in');

    final url = 'https://www.googleapis.com/drive/v3/files/$id?alt=media';
    final res = await client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw StateError('backup_download_failed');
    }
    return Uint8List.fromList(res.bodyBytes);
  }

  Future<void> restoreLatest(String password) async {
    final bytes = await downloadLatest();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('backup_missing');
    }
    await BackupService.instance.restoreFromEncrypted(bytes, password);
  }
}
