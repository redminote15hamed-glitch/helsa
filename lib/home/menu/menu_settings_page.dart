import 'dart:async';

import 'package:material_ui/material_ui.dart';
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

/// Settings — categorized expandable groups (standard settings layout).
class MenuSettingsPage extends StatefulWidget {
  const MenuSettingsPage({super.key, this.language});

  final String? language;

  static const String appVersion = '3.0.0beta';

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
    super.dispose();
  }

  void _close() => MenuExpandScope.close(context);

  Future<void> _maybeHaptic({bool force = false}) async {
    if (!force && !_haptics) return;
    try {
      // selectionClick is the most reliable on modern Android; medium as fallback.
      await HapticFeedback.selectionClick();
      await HapticFeedback.mediumImpact();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
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


  /// Settings opens inside [MenuExpandHost] Overlay — normal dialogs render
  /// *under* that layer. Insert the picker on the root overlay instead.
  Future<void> _editInt({
    required String title,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<int> onChanged,
  }) async {
    var draft = value;
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
                child: StatefulBuilder(
                  builder: (ctx, setLocal) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Material(
                        color: cs.surface,
                        elevation: 8,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: context.m,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: draft - step >= min
                                        ? () => setLocal(
                                              () => draft =
                                                  (draft - step).clamp(min, max),
                                            )
                                        : null,
                                    icon: const Icon(Icons.remove_rounded),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      step == 1 && max <= 23
                                          ? '${draft.toString().padLeft(2, '0')}:00'
                                          : '$draft',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    onPressed: draft + step <= max
                                        ? () => setLocal(
                                              () => draft =
                                                  (draft + step).clamp(min, max),
                                            )
                                        : null,
                                    icon: const Icon(Icons.add_rounded),
                                  ),
                                ],
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
                    );
                  },
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
    if (ok) {
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
            tilePadding: EdgeInsets.symmetric(
              horizontal: context.hS,
              vertical: 0,
            ),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
            leading: Icon(icon, color: cs.primary, size: 20),
            title: Text(
              _t(titleKey),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.m * 0.95,
                height: 1.15,
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
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hM, 0, context.hM, context.vS),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final key in keys)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Material(
                      color: selected == key ? cs.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelect(key),
                        child: Center(
                          child: Text(
                            _t('$labelPrefix$key'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.s * 0.88,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: selected == key
                                  ? cs.onPrimary
                                  : cs.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
      fontSize: context.s * 0.85,
      height: 1.25,
      color: cs.onSurface.withValues(alpha: 0.52),
    );
  }

  TextStyle get _titleStyle => TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: context.m * 0.92,
        height: 1.2,
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
                      titleTextStyle: _titleStyle.copyWith(
                        color: cs.onSurface,
                      ),
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
                                _maybeHaptic();
                              },
                            ),
                          );
                        }),
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
                            _maybeHaptic();
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
                          onChanged: (v) {
                            setState(() => _liveNotif = v);
                            _maybeHaptic();
                          },
                          title: Text(
                            _t('settings_notif_live'),
                            style: _titleStyle,
                          ),
                          subtitle: Text(
                            _t('settings_notif_live_hint'),
                            style: _subStyle,
                          ),
                        ),
                        SwitchListTile.adaptive(
                          value: _quietHours,
                          onChanged: (v) {
                            setState(() => _quietHours = v);
                            _maybeHaptic();
                          },
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
                          onSelect: (k) {
                            if (k == _animSpeed) return;
                            setState(() => _animSpeed = k);
                            _maybeHaptic();
                          },
                        ),
                        SwitchListTile.adaptive(
                          value: _simpleMotion,
                          onChanged: (v) {
                            setState(() => _simpleMotion = v);
                            _maybeHaptic();
                          },
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
                          onChanged: (v) async {
                            setState(() => _haptics = v);
                            // Preview even when turning on from off.
                            await _maybeHaptic(force: v);
                          },
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

                    Padding(
                      padding: EdgeInsets.only(top: context.vM, bottom: context.vS),
                      child: Center(
                        child: Text(
                          'helsa ${MenuSettingsPage.appVersion}',
                          style: TextStyle(
                            fontSize: context.s * 0.85,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                            color: cs.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
            vertical: context.vS * 0.7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.85)
                  : cs.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
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
