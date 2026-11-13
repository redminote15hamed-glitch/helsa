// lib/home/menu/menu_backup_page.dart
// Backup & restore — local encrypted + optional Google Drive.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/appearance_chrome.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/setting/backup/backup_auto_sync.dart';
import 'package:helsa/setting/backup/backup_service.dart';
import 'package:helsa/setting/backup/google_drive_backup.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/settings_store.dart';

class MenuBackupPage extends StatefulWidget {
  const MenuBackupPage({super.key, this.language});

  final String? language;

  @override
  State<MenuBackupPage> createState() => _MenuBackupPageState();
}

class _MenuBackupPageState extends State<MenuBackupPage> {
  String? _googleEmail;
  String? _lastBackupAt;
  bool _backupBusy = false;
  bool _autoSync = false;
  final TextEditingController _emailCtrl = TextEditingController();

  String get _uiLang {
    try {
      return MetaStore.language;
    } catch (_) {
      return widget.language ?? 'en';
    }
  }

  bool get _isRtl => _uiLang == 'fa';

  String _t(String key) => HomeText.getString(_uiLang, key);

  TextStyle get _titleStyle => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: context.m * 0.92,
        height: 1.2,
      );

  TextStyle get _subStyle {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: context.s * 0.85,
      height: 1.25,
      color: cs.onSurface.withValues(alpha: 0.52),
    );
  }

  @override
  void initState() {
    super.initState();
    try {
      SettingsStore.open();
    } catch (_) {}
    try {
      _googleEmail = SettingsStore.googleBackupEmail;
      _lastBackupAt = SettingsStore.lastBackupAt;
      _autoSync = SettingsStore.autoSyncEnabled;
      final pref = SettingsStore.preferredGoogleEmail;
      if (pref != null) {
        _emailCtrl.text = pref;
      } else if (_googleEmail != null) {
        _emailCtrl.text = _googleEmail!;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _close() => MenuExpandScope.close(context);

  /// Password dialog must sit above MenuExpandHost overlay.
  Future<String?> _promptPassword({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<bool>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return Material(
          color: Colors.black.withValues(alpha: 0.45),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!completer.isCompleted) completer.complete(false);
            },
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Material(
                    color: cs.surface,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: context.m,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: ctrl,
                            obscureText: true,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: hint,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  if (!completer.isCompleted) {
                                    completer.complete(false);
                                  }
                                },
                                child: Text(_t('settings_cancel')),
                              ),
                              FilledButton(
                                onPressed: () {
                                  if (!completer.isCompleted) {
                                    completer.complete(true);
                                  }
                                },
                                child: Text(_t('settings_ok')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    final ok = await completer.future;
    entry.remove();
    final text = ctrl.text;
    ctrl.dispose();
    if (ok == true && text.trim().length >= 6) return text.trim();
    if (ok == true && mounted) {
      SnackBarer.show(
        context,
        message: _t('backup_weak_password'),
        template: SnackbarTemplate.caution,
      );
    }
    return null;
  }

  void _toast(String key, {bool error = false}) {
    if (!mounted) return;
    SnackBarer.show(
      context,
      message: _t(key),
      template: error ? SnackbarTemplate.caution : SnackbarTemplate.neutral,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _backupLocal() async {
    if (_backupBusy) return;
    final pass = await _promptPassword(
      title: _t('backup_password_title'),
      hint: _t('backup_password_hint'),
    );
    if (pass == null) return;
    setState(() => _backupBusy = true);
    try {
      final path = await BackupService.instance.saveLocalEncrypted(pass);
      try {
        _lastBackupAt = SettingsStore.lastBackupAt;
      } catch (_) {}
      if (mounted) setState(() {});
      _toast('backup_local_ok');
      debugPrint('Local backup: $path');
    } catch (e) {
      debugPrint('local backup: $e');
      _toast('backup_failed', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreLocal() async {
    if (_backupBusy) return;
    final files = await BackupService.instance.listLocalBackups();
    if (files.isEmpty) {
      _toast('backup_missing', error: true);
      return;
    }
    final pass = await _promptPassword(
      title: _t('backup_restore_password_title'),
      hint: _t('backup_password_hint'),
    );
    if (pass == null) return;
    setState(() => _backupBusy = true);
    try {
      await BackupService.instance.restoreLocalFile(files.first.path, pass);
      _toast('backup_restore_ok');
    } catch (e) {
      debugPrint('restore local: $e');
      final key = e.toString().contains('bad_password')
          ? 'backup_bad_password'
          : 'backup_failed';
      _toast(key, error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final ok = await GoogleDriveBackup.instance.signInWithGoogle();
      if (!ok) {
        _toast('backup_sign_in_cancelled', error: true);
        return;
      }
      setState(() {
        _googleEmail = GoogleDriveBackup.instance.email ??
            SettingsStore.googleBackupEmail;
        if (_googleEmail != null) _emailCtrl.text = _googleEmail!;
      });
      _toast('backup_sign_in_ok');
    } catch (e) {
      debugPrint('google sign-in: $e');
      _toast('backup_sign_in_failed', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final ok =
          await GoogleDriveBackup.instance.signInWithEmail(_emailCtrl.text);
      if (!ok) {
        _toast('backup_sign_in_cancelled', error: true);
        return;
      }
      setState(() {
        _googleEmail = GoogleDriveBackup.instance.email ??
            SettingsStore.googleBackupEmail;
        if (_googleEmail != null) _emailCtrl.text = _googleEmail!;
      });
      _toast('backup_sign_in_ok');
    } catch (e) {
      debugPrint('email sign-in: $e');
      final key = e.toString().contains('bad_email')
          ? 'backup_bad_email'
          : 'backup_sign_in_failed';
      _toast(key, error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _logOut() async {
    await GoogleDriveBackup.instance.logOut();
    try {
      await SettingsStore.setAutoSyncEnabled(false);
      await BackupAutoSync.instance.clearPassword();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _googleEmail = null;
        _autoSync = false;
      });
    }
    _toast('backup_sign_out_ok');
  }

  Future<void> _setAutoSync(bool on) async {
    if (on) {
      final pass = await _promptPassword(
        title: _t('backup_password_title'),
        hint: _t('backup_password_hint'),
      );
      if (pass == null) return;
      await BackupAutoSync.instance.savePassword(pass);
      await SettingsStore.setAutoSyncEnabled(true);
      if (mounted) setState(() => _autoSync = true);
      _toast('backup_auto_on_ok');
    } else {
      await SettingsStore.setAutoSyncEnabled(false);
      if (mounted) setState(() => _autoSync = false);
      _toast('backup_auto_off_ok');
    }
  }

  Future<void> _syncNow() async {
    if (_backupBusy) return;
    if (_googleEmail == null && !GoogleDriveBackup.instance.isSignedIn) {
      _toast('backup_need_sign_in', error: true);
      return;
    }
    final pass = await _promptPassword(
      title: _t('backup_password_title'),
      hint: _t('backup_password_hint'),
    );
    if (pass == null) return;
    setState(() => _backupBusy = true);
    try {
      await BackupAutoSync.instance.syncNow(pass);
      try {
        _lastBackupAt = SettingsStore.lastBackupAt;
      } catch (_) {}
      if (mounted) setState(() {});
      _toast('backup_drive_ok');
    } catch (e) {
      debugPrint('sync now: $e');
      _toast('backup_failed', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreDrive() async {
    if (_backupBusy) return;
    if (_googleEmail == null && !GoogleDriveBackup.instance.isSignedIn) {
      _toast('backup_need_sign_in', error: true);
      return;
    }
    final pass = await _promptPassword(
      title: _t('backup_restore_password_title'),
      hint: _t('backup_password_hint'),
    );
    if (pass == null) return;
    setState(() => _backupBusy = true);
    try {
      await GoogleDriveBackup.instance.restoreLatest(pass);
      _toast('backup_restore_ok');
    } catch (e) {
      debugPrint('drive restore: $e');
      final s = e.toString();
      final key = s.contains('bad_password')
          ? 'backup_bad_password'
          : (s.contains('backup_missing') ? 'backup_missing' : 'backup_failed');
      _toast(key, error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Widget _card({required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: cs.surface,
        child: SafeArea(
          child: Column(
            children: [
              AppearanceTopBar(
                lang: _uiLang,
                titleKey: 'menu_backup',
                dirty: false,
                isRtl: _isRtl,
                onBack: _close,
                onSave: null,
              ),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    listTileTheme: ListTileThemeData(
                      dense: true,
                      visualDensity:
                          const VisualDensity(horizontal: 0, vertical: -2),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.hM,
                        vertical: 0,
                      ),
                      minVerticalPadding: 6,
                      titleTextStyle: _titleStyle.copyWith(color: cs.onSurface),
                      subtitleTextStyle: _subStyle,
                    ),
                    dividerColor: Colors.transparent,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      context.hM,
                      context.vX2s,
                      context.hM,
                      context.vM,
                    ),
                    children: [
                      if (_backupBusy)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        ),

                      // Status
                      _card(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.info_outline_rounded,
                              color: cs.primary,
                            ),
                            title: Text(_t('backup_status'), style: _titleStyle),
                            subtitle: Text(
                              _googleEmail != null
                                  ? _googleEmail!
                                  : _t('backup_status_local_only'),
                              style: _subStyle,
                            ),
                          ),
                          if (_lastBackupAt != null)
                            ListTile(
                              leading: Icon(
                                Icons.schedule_rounded,
                                color: cs.primary,
                              ),
                              title: Text(_t('backup_last'), style: _titleStyle),
                              subtitle: Text(_lastBackupAt!, style: _subStyle),
                            ),
                        ],
                      ),
                      SizedBox(height: context.vS),

                      // Account
                      _card(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.hM,
                              context.vS,
                              context.hM,
                              context.vX2s,
                            ),
                            child: Text(
                              _t('backup_sign_in_email'),
                              style: _titleStyle.copyWith(color: cs.primary),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.hM,
                              0,
                              context.hM,
                              context.vX2s,
                            ),
                            child: TextField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_backupBusy,
                              decoration: InputDecoration(
                                hintText: _t('backup_email_hint'),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(Icons.email_outlined, color: cs.primary),
                            title: Text(
                              _t('backup_login_email'),
                              style: _titleStyle,
                            ),
                            subtitle: Text(
                              _t('backup_login_email_hint'),
                              style: _subStyle,
                            ),
                            onTap: _signInWithEmail,
                          ),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(
                              Icons.g_mobiledata_rounded,
                              color: cs.primary,
                            ),
                            title: Text(
                              _t('backup_login_google'),
                              style: _titleStyle,
                            ),
                            subtitle: Text(
                              _t('backup_login_google_hint'),
                              style: _subStyle,
                            ),
                            onTap: _signInWithGoogle,
                          ),
                          if (_googleEmail != null)
                            ListTile(
                              enabled: !_backupBusy,
                              leading: Icon(
                                Icons.logout_rounded,
                                color: cs.error,
                              ),
                              title: Text(_t('backup_logout'), style: _titleStyle),
                              onTap: _logOut,
                            ),
                        ],
                      ),
                      SizedBox(height: context.vS),

                      // Sync
                      _card(
                        children: [
                          SwitchListTile.adaptive(
                            value: _autoSync,
                            onChanged: _backupBusy ? null : _setAutoSync,
                            title: Text(
                              _t('backup_auto_sync'),
                              style: _titleStyle,
                            ),
                            subtitle: Text(
                              _t('backup_auto_sync_hint'),
                              style: _subStyle,
                            ),
                          ),
                          if (!_autoSync)
                            ListTile(
                              enabled: !_backupBusy,
                              leading: Icon(Icons.sync_rounded, color: cs.primary),
                              title: Text(
                                _t('backup_sync_now'),
                                style: _titleStyle,
                              ),
                              subtitle: Text(
                                _t('backup_sync_now_hint'),
                                style: _subStyle,
                              ),
                              onTap: _syncNow,
                            ),
                        ],
                      ),
                      SizedBox(height: context.vS),

                      // Local + restore
                      _card(
                        children: [
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(
                              Icons.save_alt_rounded,
                              color: cs.primary,
                            ),
                            title: Text(
                              _t('backup_local_now'),
                              style: _titleStyle,
                            ),
                            subtitle: Text(
                              _t('backup_local_hint'),
                              style: _subStyle,
                            ),
                            onTap: _backupLocal,
                          ),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(
                              Icons.restore_rounded,
                              color: cs.primary,
                            ),
                            title: Text(
                              _t('backup_restore_local'),
                              style: _titleStyle,
                            ),
                            onTap: _restoreLocal,
                          ),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(
                              Icons.cloud_download_rounded,
                              color: cs.primary,
                            ),
                            title: Text(
                              _t('backup_restore_drive'),
                              style: _titleStyle,
                            ),
                            onTap: _restoreDrive,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
