// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/appearance_chrome.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/home/services/goal_calculator.dart';
import 'package:helsa/home/services/step_foreground.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/settings_store.dart';
import 'package:helsa/setting/backup/backup_service.dart';
import 'package:helsa/setting/backup/google_drive_backup.dart';
import 'package:helsa/setting/backup/backup_auto_sync.dart';

/// Settings — categorized expandable groups (standard settings layout).
class MenuSettingsPage extends StatefulWidget {
  const MenuSettingsPage({super.key, this.language});

  final String? language;

  static const String appVersion = '1.0.0+3';

  @override
  State<MenuSettingsPage> createState() => _MenuSettingsPageState();
}

class _MenuSettingsPageState extends State<MenuSettingsPage> {
  late String _previewLang;
  late String _savedLang;

  late int _stepsGoal;
  late int _savedStepsGoal;
  late int _calGoal;
  late int _savedCalGoal;
  late int _activeGoal;
  late int _savedActiveGoal;
  late bool _useAutoGoals;
  late bool _savedUseAutoGoals;

  late bool _liveNotif;
  late bool _savedLiveNotif;
  late bool _quietHours;
  late bool _savedQuietHours;
  late int _quietStart;
  late int _savedQuietStart;
  late int _quietEnd;
  late int _savedQuietEnd;

  late int _dayReset;
  late int _savedDayReset;

  late bool _haptics;
  late bool _savedHaptics;

  late String _animSpeed;
  late String _savedAnimSpeed;
  late bool _simpleMotion;
  late bool _savedSimpleMotion;

  late String _units;
  late String _savedUnits;

  String? _googleEmail;
  String? _lastBackupAt;
  bool _backupBusy = false;
  bool _autoSync = false;
  final TextEditingController _emailCtrl = TextEditingController();

  // Which sections start expanded
  final Set<String> _open = {
    'general',
    'activity',
    'notification',
  };

  static const _options = <_LangOpt>[
    _LangOpt('fa', 'فارسی', 'Persian'),
    _LangOpt('en', 'English', 'English'),
    _LangOpt('fr', 'Français', 'French'),
  ];

  @override
  void initState() {
    super.initState();
    try {
      _savedLang = MetaStore.language;
    } catch (_) {
      _savedLang = widget.language ?? 'en';
    }
    _previewLang = _savedLang;

    try {
      SettingsStore.open();
    } catch (_) {}

    final autoSteps = GoalCalculator.stepsGoal();
    final autoCal = GoalCalculator.caloriesGoal().round();
    final autoAct = GoalCalculator.activeMinutesGoal();

    int? oSteps;
    double? oCal;
    int? oAct;
    try {
      oSteps = SettingsStore.stepsGoalOverride;
      oCal = SettingsStore.caloriesGoalOverride;
      oAct = SettingsStore.activeMinutesGoalOverride;
      _savedLiveNotif = SettingsStore.liveStepNotification;
      _savedQuietHours = SettingsStore.quietHoursEnabled;
      _savedQuietStart = SettingsStore.quietHoursStart;
      _savedQuietEnd = SettingsStore.quietHoursEnd;
      _savedDayReset = SettingsStore.dayResetHour;
      _savedHaptics = SettingsStore.hapticsEnabled;
      _savedAnimSpeed = SettingsStore.animationSpeedKey;
      _savedSimpleMotion = SettingsStore.simpleMotion;
      _savedUnits = SettingsStore.unitsKey;
    } catch (_) {
      _savedLiveNotif = true;
      _savedQuietHours = false;
      _savedQuietStart = 22;
      _savedQuietEnd = 7;
      _savedDayReset = 0;
      _savedHaptics = true;
      _savedAnimSpeed = 'medium';
      _savedSimpleMotion = false;
      _savedUnits = 'metric';
    }

    _savedUseAutoGoals = oSteps == null && oCal == null && oAct == null;
    _useAutoGoals = _savedUseAutoGoals;
    _savedStepsGoal = oSteps ?? autoSteps;
    _savedCalGoal = (oCal?.round() ?? autoCal);
    _savedActiveGoal = oAct ?? autoAct;
    _stepsGoal = _savedStepsGoal;
    _calGoal = _savedCalGoal;
    _activeGoal = _savedActiveGoal;

    _liveNotif = _savedLiveNotif;
    _quietHours = _savedQuietHours;
    _quietStart = _savedQuietStart;
    _quietEnd = _savedQuietEnd;
    _dayReset = _savedDayReset;
    _haptics = _savedHaptics;
    _animSpeed = _savedAnimSpeed;
    _simpleMotion = _savedSimpleMotion;
    _units = _savedUnits;
    try {
      _googleEmail = SettingsStore.googleBackupEmail;
      _lastBackupAt = SettingsStore.lastBackupAt;
      _autoSync = SettingsStore.autoSyncEnabled;
      final pref = SettingsStore.preferredGoogleEmail;
      if (pref != null) {
        _emailCtrl.text = pref;
      } else if (_googleEmail != null) _emailCtrl.text = _googleEmail!;
    } catch (_) {}
  }

  bool get _dirty =>
      _previewLang != _savedLang ||
      _useAutoGoals != _savedUseAutoGoals ||
      (!_useAutoGoals &&
          (_stepsGoal != _savedStepsGoal ||
              _calGoal != _savedCalGoal ||
              _activeGoal != _savedActiveGoal)) ||
      _liveNotif != _savedLiveNotif ||
      _quietHours != _savedQuietHours ||
      _quietStart != _savedQuietStart ||
      _quietEnd != _savedQuietEnd ||
      _dayReset != _savedDayReset ||
      _haptics != _savedHaptics ||
      _animSpeed != _savedAnimSpeed ||
      _simpleMotion != _savedSimpleMotion ||
      _units != _savedUnits;

  bool get _isRtl => _previewLang == 'fa';
  String get _uiLang => _previewLang;
  String _t(String key) => HomeText.getString(_uiLang, key);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _close() => MenuExpandScope.close(context);

  Future<void> _maybeHaptic() async {
    if (!_haptics) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> _saveAndClose() async {
    if (!_dirty) {
      _close();
      return;
    }
    try {
      await MetaStore.open();
      await SettingsStore.open();
      if (_previewLang != _savedLang) {
        await MetaStore.setLanguage(_previewLang);
      }
      if (_useAutoGoals) {
        await SettingsStore.setStepsGoalOverride(null);
        await SettingsStore.setCaloriesGoalOverride(null);
        await SettingsStore.setActiveMinutesGoalOverride(null);
      } else {
        await SettingsStore.setStepsGoalOverride(_stepsGoal);
        await SettingsStore.setCaloriesGoalOverride(_calGoal.toDouble());
        await SettingsStore.setActiveMinutesGoalOverride(_activeGoal);
      }
      await SettingsStore.setLiveStepNotification(_liveNotif);
      await SettingsStore.setQuietHours(
        enabled: _quietHours,
        startHour: _quietStart,
        endHour: _quietEnd,
      );
      await SettingsStore.setDayResetHour(_dayReset);
      await SettingsStore.setHapticsEnabled(_haptics);
      await SettingsStore.setAnimationSpeedKey(_animSpeed);
      await SettingsStore.setSimpleMotion(_simpleMotion);
      await SettingsStore.setUnitsKey(_units);

      try {
        StepTracker.instance.profileChanged();
        await StepForeground.instance.refresh(force: true);
      } catch (_) {}
    } catch (e, st) {
      debugPrint('Settings save failed: $e\n$st');
    }
    await _maybeHaptic();
    if (!mounted) return;
    _close();
  }

  void _onBack() => _close();

  Future<void> _applyUnits(String key) async {
    if (key == _units) return;
    setState(() => _units = key);
    try {
      await SettingsStore.open();
      await SettingsStore.setUnitsKey(key);
      _savedUnits = key;
      try {
        StepTracker.instance.profileChanged();
      } catch (_) {}
    } catch (_) {}
    await _maybeHaptic();
    if (!mounted) return;
    SnackBarer.show(
      context,
      message: _t('settings_units_ok'),
      template: SnackbarTemplate.neutral,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _resetGoalsToDefault() async {
    try {
      await SettingsStore.open();
      await SettingsStore.setStepsGoalOverride(null);
      await SettingsStore.setCaloriesGoalOverride(null);
      await SettingsStore.setActiveMinutesGoalOverride(null);
      setState(() {
        _useAutoGoals = true;
        _savedUseAutoGoals = true;
        _stepsGoal = GoalCalculator.stepsGoal();
        _calGoal = GoalCalculator.caloriesGoal().round();
        _activeGoal = GoalCalculator.activeMinutesGoal();
        _savedStepsGoal = _stepsGoal;
        _savedCalGoal = _calGoal;
        _savedActiveGoal = _activeGoal;
      });
      try {
        StepTracker.instance.profileChanged();
      } catch (_) {}
    } catch (_) {}
    await _maybeHaptic();
    if (!mounted) return;
    SnackBarer.show(
      context,
      message: _t('settings_reset_goals_ok'),
      template: SnackbarTemplate.neutral,
      duration: const Duration(seconds: 2),
    );
  }


  Future<String?> _promptPassword({required String title, required String hint}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_t('settings_cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_t('settings_ok')),
            ),
          ],
        );
      },
    );
    final text = ctrl.text;
    ctrl.dispose();
    if (ok == true && text.trim().length >= 6) return text.trim();
    if (ok == true) {
      if (mounted) {
        SnackBarer.show(
          context,
          message: _t('backup_weak_password'),
          template: SnackbarTemplate.caution,
        );
      }
      return null;
    }
    return null;
  }

  void _backupToast(String key, {bool error = false}) {
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
      _backupToast('backup_local_ok');
      debugPrint('Local backup: $path');
    } catch (e) {
      debugPrint('local backup: $e');
      _backupToast('backup_failed', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreLocal() async {
    if (_backupBusy) return;
    final files = await BackupService.instance.listLocalBackups();
    if (files.isEmpty) {
      _backupToast('backup_missing', error: true);
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
      _backupToast('backup_restore_ok');
    } catch (e) {
      debugPrint('restore local: $e');
      final key = e.toString().contains('bad_password')
          ? 'backup_bad_password'
          : 'backup_failed';
      _backupToast(key, error: true);
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
        _backupToast('backup_sign_in_cancelled', error: true);
        return;
      }
      setState(() {
        _googleEmail = GoogleDriveBackup.instance.email ??
            SettingsStore.googleBackupEmail;
        if (_googleEmail != null) _emailCtrl.text = _googleEmail!;
      });
      _backupToast('backup_sign_in_ok');
    } catch (e) {
      debugPrint('google sign-in: $e');
      _backupToast('backup_sign_in_failed', error: true);
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
        _backupToast('backup_sign_in_cancelled', error: true);
        return;
      }
      setState(() {
        _googleEmail = GoogleDriveBackup.instance.email ??
            SettingsStore.googleBackupEmail;
        if (_googleEmail != null) _emailCtrl.text = _googleEmail!;
      });
      _backupToast('backup_sign_in_ok');
    } catch (e) {
      debugPrint('email sign-in: $e');
      final key = e.toString().contains('bad_email')
          ? 'backup_bad_email'
          : 'backup_sign_in_failed';
      _backupToast(key, error: true);
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
    _backupToast('backup_sign_out_ok');
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
      _backupToast('backup_auto_on_ok');
    } else {
      await SettingsStore.setAutoSyncEnabled(false);
      // Keep stored password so user can re-enable without retyping; clear on logout only.
      if (mounted) setState(() => _autoSync = false);
      _backupToast('backup_auto_off_ok');
    }
  }

  Future<void> _syncNow() async {
    if (_backupBusy) return;
    if (_googleEmail == null && !GoogleDriveBackup.instance.isSignedIn) {
      _backupToast('backup_need_sign_in', error: true);
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
      _backupToast('backup_drive_ok');
    } catch (e) {
      debugPrint('sync now: $e');
      _backupToast('backup_failed', error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }


  Future<void> _restoreDrive() async {
    if (_backupBusy) return;
    if (_googleEmail == null && !GoogleDriveBackup.instance.isSignedIn) {
      _backupToast('backup_need_sign_in', error: true);
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
      _backupToast('backup_restore_ok');
    } catch (e) {
      debugPrint('drive restore: $e');
      final s = e.toString();
      final key = s.contains('bad_password')
          ? 'backup_bad_password'
          : (s.contains('backup_missing') ? 'backup_missing' : 'backup_failed');
      _backupToast(key, error: true);
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _editInt({
    required String title,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) async {
    var draft = value;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(title),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: draft - step >= min
                        ? () => setLocal(
                              () => draft = (draft - step).clamp(min, max),
                            )
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$draft',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: draft + step <= max
                        ? () => setLocal(
                              () => draft = (draft + step).clamp(min, max),
                            )
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(_t('settings_cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(_t('settings_ok')),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      setState(() => onChanged(draft));
      await _maybeHaptic();
    }
  }

  Widget _group({
    required String id,
    required String titleKey,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final expanded = _open.contains(id);
    return Padding(
      padding: EdgeInsets.only(bottom: context.vS),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: PageStorageKey<String>('settings_$id'),
            initiallyExpanded: expanded,
            onExpansionChanged: (v) {
              setState(() {
                if (v) {
                  _open.add(id);
                } else {
                  _open.remove(id);
                }
              });
            },
            leading: Icon(icon, color: cs.primary, size: 22),
            title: Text(
              _t(titleKey),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.m,
                color: cs.onSurface,
              ),
            ),
            childrenPadding: EdgeInsets.only(bottom: context.vX2s),
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _chipRow({
    required List<String> keys,
    required String selected,
    required String labelPrefix,
    required ValueChanged<String> onSelect,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hS, 0, context.hS, context.vS),
      child: Row(
        children: [
          for (final key in keys)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  selected: selected == key,
                  label: Center(
                    child: Text(
                      _t("$labelPrefix$key"),
                      style: TextStyle(
                        fontSize: context.s * 0.92,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onSelected: (_) => onSelect(key),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _goalTile({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: context.m * 0.95,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontSize: context.m * 0.95,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  TextStyle get _subStyle {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: context.s * 0.9,
      color: cs.onSurface.withValues(alpha: 0.55),
    );
  }

  TextStyle get _titleStyle => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: context.m * 0.95,
      );

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
                titleKey: 'menu_settings',
                dirty: _dirty,
                isRtl: _isRtl,
                onBack: _onBack,
                onSave: _dirty ? _saveAndClose : null,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    context.hM,
                    context.vX2s,
                    context.hM,
                    context.vM,
                  ),
                  children: [
                    // ── General: language + units ──
                    _group(
                      id: 'general',
                      titleKey: 'settings_cat_general',
                      icon: Icons.tune_rounded,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.hM,
                            context.vX2s,
                            context.hM,
                            context.vX2s,
                          ),
                          child: Text(
                            _t('settings_section_language'),
                            style: _titleStyle.copyWith(color: cs.primary),
                          ),
                        ),
                        ..._options.map((opt) {
                          final selected = _previewLang == opt.code;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              context.hS,
                              0,
                              context.hS,
                              context.vX2s,
                            ),
                            child: _LanguageTile(
                              opt: opt,
                              selected: selected,
                              onTap: () {
                                if (selected) return;
                                setState(() => _previewLang = opt.code);
                              },
                            ),
                          );
                        }),
                        Divider(
                          height: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.hM,
                            context.vS,
                            context.hM,
                            context.vX2s,
                          ),
                          child: Text(
                            _t('settings_section_units'),
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
                          child: Text(
                            _t('settings_units_hint'),
                            style: _subStyle,
                          ),
                        ),
                        _chipRow(
                          keys: const ['metric', 'imperial'],
                          selected: _units,
                          labelPrefix: 'settings_units_',
                          onSelect: _applyUnits,
                        ),
                      ],
                    ),

                    // ── Activity ──
                    _group(
                      id: 'activity',
                      titleKey: 'settings_cat_activity',
                      icon: Icons.directions_walk_rounded,
                      children: [
                        SwitchListTile.adaptive(
                          value: _useAutoGoals,
                          onChanged: (v) {
                            setState(() {
                              _useAutoGoals = v;
                              if (v) {
                                _stepsGoal = GoalCalculator.stepsGoal();
                                _calGoal =
                                    GoalCalculator.caloriesGoal().round();
                                _activeGoal =
                                    GoalCalculator.activeMinutesGoal();
                              }
                            });
                          },
                          title: Text(
                            _t('settings_goals_auto'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_goals_auto_hint'),
                            style: _subStyle,
                          ),
                        ),
                        if (!_useAutoGoals) ...[
                          const Divider(height: 1),
                          _goalTile(
                            label: _t('settings_goal_steps'),
                            value: '$_stepsGoal',
                            onTap: () => _editInt(
                              title: _t('settings_goal_steps'),
                              value: _stepsGoal,
                              min: 1000,
                              max: 30000,
                              step: 500,
                              onChanged: (v) => _stepsGoal = v,
                            ),
                          ),
                          const Divider(height: 1),
                          _goalTile(
                            label: _t('settings_goal_calories'),
                            value: '$_calGoal',
                            onTap: () => _editInt(
                              title: _t('settings_goal_calories'),
                              value: _calGoal,
                              min: 50,
                              max: 2000,
                              step: 25,
                              onChanged: (v) => _calGoal = v,
                            ),
                          ),
                          const Divider(height: 1),
                          _goalTile(
                            label: _t('settings_goal_active'),
                            value: '$_activeGoal',
                            onTap: () => _editInt(
                              title: _t('settings_goal_active'),
                              value: _activeGoal,
                              min: 5,
                              max: 300,
                              step: 5,
                              onChanged: (v) => _activeGoal = v,
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        _goalTile(
                          label: _t('settings_day_reset'),
                          value: _dayReset == 0
                              ? _t('settings_day_reset_midnight')
                              : '${_dayReset.toString().padLeft(2, '0')}:00',
                          onTap: () => _editInt(
                            title: _t('settings_day_reset'),
                            value: _dayReset,
                            min: 0,
                            max: 23,
                            step: 1,
                            onChanged: (v) => _dayReset = v,
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          onTap: _resetGoalsToDefault,
                          leading: Icon(
                            Icons.restart_alt_rounded,
                            color: cs.primary,
                          ),
                          title: Text(
                            _t('settings_reset_goals'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_reset_goals_hint'),
                            style: _subStyle,
                          ),
                        ),
                      ],
                    ),

                    // ── Notifications ──
                    _group(
                      id: 'notification',
                      titleKey: 'settings_cat_notification',
                      icon: Icons.notifications_outlined,
                      children: [
                        SwitchListTile.adaptive(
                          value: _liveNotif,
                          onChanged: (v) => setState(() => _liveNotif = v),
                          title: Text(
                            _t('settings_notif_live'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_notif_live_hint'),
                            style: _subStyle,
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _quietHours,
                          onChanged: (v) => setState(() => _quietHours = v),
                          title: Text(
                            _t('settings_quiet_hours'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_quiet_hours_hint'),
                            style: _subStyle,
                          ),
                        ),
                        if (_quietHours) ...[
                          const Divider(height: 1),
                          _goalTile(
                            label: _t('settings_quiet_start'),
                            value:
                                '${_quietStart.toString().padLeft(2, '0')}:00',
                            onTap: () => _editInt(
                              title: _t('settings_quiet_start'),
                              value: _quietStart,
                              min: 0,
                              max: 23,
                              step: 1,
                              onChanged: (v) => _quietStart = v,
                            ),
                          ),
                          const Divider(height: 1),
                          _goalTile(
                            label: _t('settings_quiet_end'),
                            value: '${_quietEnd.toString().padLeft(2, '0')}:00',
                            onTap: () => _editInt(
                              title: _t('settings_quiet_end'),
                              value: _quietEnd,
                              min: 0,
                              max: 23,
                              step: 1,
                              onChanged: (v) => _quietEnd = v,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // ── Motion ──
                    _group(
                      id: 'motion',
                      titleKey: 'settings_cat_motion',
                      icon: Icons.animation_rounded,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.hM,
                            context.vS,
                            context.hM,
                            context.vX2s,
                          ),
                          child: Text(
                            _t('settings_anim_speed'),
                            style: _titleStyle,
                          ),
                        ),
                        _chipRow(
                          keys: const ['calm', 'medium', 'fast'],
                          selected: _animSpeed,
                          labelPrefix: 'settings_anim_',
                          onSelect: (k) => setState(() => _animSpeed = k),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _simpleMotion,
                          onChanged: (v) =>
                              setState(() => _simpleMotion = v),
                          title: Text(
                            _t('settings_simple_motion'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_simple_motion_hint'),
                            style: _subStyle,
                          ),
                        ),
                      ],
                    ),

                    // ── Feedback ──
                    _group(
                      id: 'feedback',
                      titleKey: 'settings_cat_feedback',
                      icon: Icons.vibration_rounded,
                      children: [
                        SwitchListTile.adaptive(
                          value: _haptics,
                          onChanged: (v) => setState(() => _haptics = v),
                          title: Text(
                            _t('settings_haptics'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_haptics_hint'),
                            style: _subStyle,
                          ),
                        ),
                      ],
                    ),

                    // ── Backup ──
                    _group(
                      id: 'backup',
                      titleKey: 'settings_cat_backup',
                      icon: Icons.cloud_outlined,
                      children: [
                        if (_backupBusy)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          ),
                        ListTile(
                          title: Text(_t('backup_status'), style: _titleStyle),
                          subtitle: Text(
                            _googleEmail != null
                                ? _googleEmail!
                                : _t('backup_status_local_only'),
                            style: _subStyle,
                          ),
                        ),
                        if (_lastBackupAt != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            title: Text(_t('backup_last'), style: _titleStyle),
                            subtitle: Text(_lastBackupAt!, style: _subStyle),
                          ),
                        ],
                        const Divider(height: 1),
                        // Sign in with email
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.hM, context.vS, context.hM, context.vX2s,
                          ),
                          child: Text(_t('backup_sign_in_email'), style: _titleStyle),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            context.hM, 0, context.hM, context.vX2s,
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
                          leading: Icon(Icons.email_outlined,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(_t('backup_login_email'), style: _titleStyle),
                          subtitle: Text(_t('backup_login_email_hint'), style: _subStyle),
                          onTap: _signInWithEmail,
                        ),
                        const Divider(height: 1),
                        // Sign in with Google
                        ListTile(
                          enabled: !_backupBusy,
                          leading: Icon(Icons.g_mobiledata_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(_t('backup_login_google'), style: _titleStyle),
                          subtitle: Text(_t('backup_login_google_hint'), style: _subStyle),
                          onTap: _signInWithGoogle,
                        ),
                        if (_googleEmail != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(Icons.logout_rounded,
                                color: Theme.of(context).colorScheme.error),
                            title: Text(_t('backup_logout'), style: _titleStyle),
                            onTap: _logOut,
                          ),
                        ],
                        const Divider(height: 1),
                        // Auto sync
                        SwitchListTile.adaptive(
                          value: _autoSync,
                          onChanged: _backupBusy
                              ? null
                              : (v) => _setAutoSync(v),
                          title: Text(_t('backup_auto_sync'), style: _titleStyle),
                          subtitle: Text(
                            _t('backup_auto_sync_hint'),
                            style: _subStyle,
                          ),
                        ),
                        if (!_autoSync) ...[
                          const Divider(height: 1),
                          ListTile(
                            enabled: !_backupBusy,
                            leading: Icon(Icons.sync_rounded,
                                color: Theme.of(context).colorScheme.primary),
                            title: Text(_t('backup_sync_now'), style: _titleStyle),
                            subtitle: Text(_t('backup_sync_now_hint'), style: _subStyle),
                            onTap: _syncNow,
                          ),
                        ],
                        const Divider(height: 1),
                        ListTile(
                          enabled: !_backupBusy,
                          leading: Icon(Icons.save_alt_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(_t('backup_local_now'), style: _titleStyle),
                          subtitle: Text(_t('backup_local_hint'), style: _subStyle),
                          onTap: _backupLocal,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          enabled: !_backupBusy,
                          leading: Icon(Icons.restore_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(_t('backup_restore_local'), style: _titleStyle),
                          onTap: _restoreLocal,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          enabled: !_backupBusy,
                          leading: Icon(Icons.cloud_download_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(_t('backup_restore_drive'), style: _titleStyle),
                          onTap: _restoreDrive,
                        ),
                      ],
                    ),

                    // ── About ──
                    _group(
                      id: 'about',
                      titleKey: 'settings_cat_about',
                      icon: Icons.info_outline_rounded,
                      children: [
                        ListTile(
                          title: Text(
                            _t('settings_version'),
                            style: _titleStyle,
                          ),
                          trailing: Text(
                            MenuSettingsPage.appVersion,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              fontSize: context.m * 0.95,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.vS),
                  ],
                ),
              ),
              AppearanceApplyBar(
                lang: _uiLang,
                visible: _dirty,
                onApply: _saveAndClose,
              ),
              SizedBox(height: context.vX2s),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOpt {
  const _LangOpt(this.code, this.nativeName, this.englishName);
  final String code;
  final String nativeName;
  final String englishName;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  final _LangOpt opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.14)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.hM,
            vertical: context.vS * 1.1,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.85)
                  : cs.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color:
                    selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
              ),
              SizedBox(width: context.hS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.nativeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.m,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      opt.englishName,
                      style: TextStyle(
                        fontSize: context.s * 0.95,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
