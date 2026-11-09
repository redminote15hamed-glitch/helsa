import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/appearance_chrome.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/home/services/goal_calculator.dart';
import 'package:helsa/home/services/step_foreground.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/settings_store.dart';

/// Settings — language, goals, one notification switch, day reset, haptics.
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
    } catch (_) {
      _savedLiveNotif = true;
      _savedQuietHours = false;
      _savedQuietStart = 22;
      _savedQuietEnd = 7;
      _savedDayReset = 0;
      _savedHaptics = true;
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
      _haptics != _savedHaptics;

  bool get _isRtl => _previewLang == 'fa';
  String get _uiLang => _previewLang;

  String _t(String key) => HomeText.getString(_uiLang, key);

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
                        ? () => setLocal(() => draft = (draft - step).clamp(min, max))
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
                        ? () => setLocal(() => draft = (draft + step).clamp(min, max))
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

  Widget _sectionTitle(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        top: context.vS,
        bottom: context.vX2s,
        left: 4,
        right: 4,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: context.s,
          color: cs.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
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
                    // ── Language ──
                    _sectionTitle(_t('settings_section_language')),
                    ..._options.map((opt) {
                      final selected = _previewLang == opt.code;
                      return Padding(
                        padding: EdgeInsets.only(bottom: context.vX2s),
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

                    // ── Activity ──
                    _sectionTitle(_t('settings_section_activity')),
                    _card(
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.m * 0.95,
                            ),
                          ),
                          subtitle: Text(
                            _t('settings_goals_auto_hint'),
                            style: TextStyle(
                              fontSize: context.s * 0.9,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        if (!_useAutoGoals) ...[
                          const Divider(height: 1),
                          _GoalTile(
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
                          _GoalTile(
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
                          _GoalTile(
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
                      ],
                    ),

                    // ── Notification (minimal) ──
                    _sectionTitle(_t('settings_section_notification')),
                    _card(
                      children: [
                        SwitchListTile.adaptive(
                          value: _liveNotif,
                          onChanged: (v) => setState(() => _liveNotif = v),
                          title: Text(
                            _t('settings_notif_live'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.m * 0.95,
                            ),
                          ),
                          subtitle: Text(
                            _t('settings_notif_live_hint'),
                            style: TextStyle(
                              fontSize: context.s * 0.9,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          value: _quietHours,
                          onChanged: (v) => setState(() => _quietHours = v),
                          title: Text(
                            _t('settings_quiet_hours'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.m * 0.95,
                            ),
                          ),
                          subtitle: Text(
                            _t('settings_quiet_hours_hint'),
                            style: TextStyle(
                              fontSize: context.s * 0.9,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        if (_quietHours) ...[
                          const Divider(height: 1),
                          _GoalTile(
                            label: _t('settings_quiet_start'),
                            value: '${_quietStart.toString().padLeft(2, '0')}:00',
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
                          _GoalTile(
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

                    // ── Day ──
                    _sectionTitle(_t('settings_section_day')),
                    _card(
                      children: [
                        _GoalTile(
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
                      ],
                    ),

                    // ── Feedback ──
                    _sectionTitle(_t('settings_section_feedback')),
                    _card(
                      children: [
                        SwitchListTile.adaptive(
                          value: _haptics,
                          onChanged: (v) => setState(() => _haptics = v),
                          title: Text(
                            _t('settings_haptics'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.m * 0.95,
                            ),
                          ),
                          subtitle: Text(
                            _t('settings_haptics_hint'),
                            style: TextStyle(
                              fontSize: context.s * 0.9,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: context.vM),
                    Center(
                      child: Text(
                        '${_t('settings_version')} ${MenuSettingsPage.appVersion}',
                        style: TextStyle(
                          fontSize: context.s * 0.9,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
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

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
