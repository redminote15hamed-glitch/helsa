// lib/setting/backup/google_drive_backup.dart
// Optional Google Sign-In + encrypted backup in Drive App Data folder.
// Migrated for google_sign_in 7.x + extension_google_sign_in_as_googleapis_auth 3.x


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

  final GoogleSignIn _signIn = GoogleSignIn.instance;
  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  String? get email => _currentUser?.email;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _signIn.initialize();
    _signIn.authenticationEvents.listen((event) {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn(:final user):
          _currentUser = user;
        case GoogleSignInAuthenticationEventSignOut():
          _currentUser = null;
      }
    });
    _initialized = true;
  }

  /// Standard Google account picker (Sign in with Google).
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) return false;
    try {
      await _ensureInitialized();

      final lightweight = _signIn.attemptLightweightAuthentication();
      if (lightweight != null) {
        final existing = await lightweight;
        if (existing != null) {
          _currentUser = existing;
          await _persistEmail(existing.email);
          return true;
        }
      }

      if (!_signIn.supportsAuthenticate()) {
        return false;
      }

      final account = await _signIn.authenticate(scopeHint: _scopes);
      _currentUser = account;
      await _persistEmail(account.email);
      return true;
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      debugPrint('GoogleDriveBackup.signInWithGoogle: $e\n$st');
      rethrow;
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
      return await signInWithGoogle();
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
      await _ensureInitialized();
      await _signIn.disconnect();
    } catch (_) {
      try {
        await _signIn.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    try {
      await SettingsStore.open();
      await SettingsStore.setGoogleBackupEmail(null);
    } catch (_) {}
  }

  Future<drive.DriveApi> _api() async {
    await _ensureInitialized();

    var account = _currentUser;
    if (account == null) {
      final lightweight = _signIn.attemptLightweightAuthentication();
      if (lightweight != null) {
        account = await lightweight;
        _currentUser = account;
      }
    }
    if (account == null) {
      throw StateError('backup_not_signed_in');
    }

    var authorization =
        await account.authorizationClient.authorizationForScopes(_scopes);
    authorization ??=
        await account.authorizationClient.authorizeScopes(_scopes);

    final httpClient = authorization.authClient(scopes: _scopes);
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
    await _persistEmail(_currentUser?.email);
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

    final account = _currentUser;
    if (account == null) throw StateError('backup_not_signed_in');

    var authorization =
        await account.authorizationClient.authorizationForScopes(_scopes);
    authorization ??=
        await account.authorizationClient.authorizeScopes(_scopes);
    final client = authorization.authClient(scopes: _scopes);

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
