// lib/home/home_screen_widget/home_widget_bridge.dart
// Live metric + surface colors for home widgets (theme-aware).
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/metric_colors.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();
  static final HomeWidgetBridge instance = HomeWidgetBridge._();

  static const String _mainQualified = 'com.example.helsa.HelsaWidgetProvider';
  static const String _stepsQualified = 'com.example.helsa.HelsaStepsWidgetProvider';
  static const String _mainName = 'HelsaWidgetProvider';
  static const String _stepsName = 'HelsaStepsWidgetProvider';

  bool _listening = false;
  int _lastSteps = -1;
  int _lastCal = -1;
  int _lastMins = -1;
  int _lastStepsGoal = -1;
  int _lastCalGoal = -1;
  int _lastMinsGoal = -1;
  int _lastStepsColor = -1;
  int _lastCalColor = -1;
  int _lastTimeColor = -1;
  int _lastBgColor = -1;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _heartbeat;

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('helsa_widget');
    } catch (_) {}
    attach();
    await push(force: true);
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 12), (_) {
      push(force: true);
    });
  }

  void attach() {
    if (_listening) return;
    _listening = true;
    StepTracker.instance.addListener(_onTracker);
    ThemeStore.revision.addListener(_onTheme);
  }

  void detach() {
    if (!_listening) return;
    _listening = false;
    StepTracker.instance.removeListener(_onTracker);
    ThemeStore.revision.removeListener(_onTheme);
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _onTracker() => push();
  void _onTheme() => push(force: true);

  static int _argb(Color c) {
    return ((c.a * 255.0).round() & 0xff) << 24 |
        ((c.r * 255.0).round() & 0xff) << 16 |
        ((c.g * 255.0).round() & 0xff) << 8 |
        ((c.b * 255.0).round() & 0xff);
  }

  Future<void> push({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final t = StepTracker.instance;
    final steps = t.steps;
    final cal = t.calories.round();
    final mins = t.activeMinutes;
    final stepsGoal = t.stepsGoal;
    final calGoal = t.caloriesGoal.round();
    final minsGoal = t.activeMinutesGoal;

    final metrics = MetricColors.current;
    final palette = ThemeStore.palette;
    final night = ThemeStore.night;
    final scheme = palette.scheme(night as bool);

    final stepsColor = _argb(metrics.steps);
    final calColor = _argb(metrics.calories);
    final timeColor = _argb(metrics.active);
    // Surface for widget card — readable contrast
    final bgColor = _argb(scheme.surfaceContainerHighest.withValues(alpha: 0.92));
    final mutedColor = _argb(scheme.onSurface.withValues(alpha: 0.55));

    final unchanged = steps == _lastSteps &&
        cal == _lastCal &&
        mins == _lastMins &&
        stepsGoal == _lastStepsGoal &&
        calGoal == _lastCalGoal &&
        minsGoal == _lastMinsGoal &&
        stepsColor == _lastStepsColor &&
        calColor == _lastCalColor &&
        timeColor == _lastTimeColor &&
        bgColor == _lastBgColor;

    final now = DateTime.now();
    if (!force && unchanged) return;
    if (!force && now.difference(_lastPush).inMilliseconds < 600) return;

    final lang = _lang();
    final stepsLabel = HomeText.getString(lang, 'steps');
    final calLabel = HomeText.getString(lang, 'kcal');
    // Short time unit on widget
    final timeLabel = HomeText.getString(lang, 'minutes');

    try {
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.saveWidgetData<int>('cal', cal);
      await HomeWidget.saveWidgetData<int>('mins', mins);
      await HomeWidget.saveWidgetData<int>('steps_goal', stepsGoal);
      await HomeWidget.saveWidgetData<int>('cal_goal', calGoal);
      await HomeWidget.saveWidgetData<int>('mins_goal', minsGoal);
      await HomeWidget.saveWidgetData<String>('steps_label', stepsLabel);
      await HomeWidget.saveWidgetData<String>('cal_label', calLabel);
      await HomeWidget.saveWidgetData<String>('time_label', timeLabel);

      await HomeWidget.saveWidgetData<int>('steps_color', stepsColor);
      await HomeWidget.saveWidgetData<int>('cal_color', calColor);
      await HomeWidget.saveWidgetData<int>('time_color', timeColor);
      await HomeWidget.saveWidgetData<int>('widget_bg', bgColor);
      await HomeWidget.saveWidgetData<int>('muted_color', mutedColor);

      await HomeWidget.updateWidget(
        name: _mainName,
        androidName: _mainName,
        qualifiedAndroidName: _mainQualified,
      );
      await HomeWidget.updateWidget(
        name: _stepsName,
        androidName: _stepsName,
        qualifiedAndroidName: _stepsQualified,
      );

      _lastSteps = steps;
      _lastCal = cal;
      _lastMins = mins;
      _lastStepsGoal = stepsGoal;
      _lastCalGoal = calGoal;
      _lastMinsGoal = minsGoal;
      _lastStepsColor = stepsColor;
      _lastCalColor = calColor;
      _lastTimeColor = timeColor;
      _lastBgColor = bgColor;
      _lastPush = now;
    } catch (e, st) {
      debugPrint('HomeWidgetBridge.push: $e\n$st');
    }
  }

  static String _lang() {
    try {
      final l = MetaStore.language;
      if (l == 'fa' || l == 'en' || l == 'fr') return l;
    } catch (_) {}
    return 'en';
  }
}
