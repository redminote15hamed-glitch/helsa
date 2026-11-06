// lib/home/home_screen_widget/home_widget_bridge.dart
// Live metric + surface colors for Android home widgets.
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
  bool _pushInProgress = false;
  bool _pushQueued = false;
  bool _queuedForce = false;
  Timer? _retryTimer;

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
  int _lastMutedColor = -1;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('helsa_widget');
    } catch (e, st) {
      debugPrint('HomeWidgetBridge.setAppGroupId: $e\n$st');
    }
    attach();
    await push(force: true);
  }

  void attach() {
    if (_listening) return;
    _listening = true;
    StepTracker.instance.addListener(_onTracker);
    ThemeStore.revision.addListener(_onTheme);
  }

  void detach() {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!_listening) return;
    _listening = false;
    StepTracker.instance.removeListener(_onTracker);
    ThemeStore.revision.removeListener(_onTheme);
  }

  void _onTracker() => unawaited(push());
  void _onTheme() => unawaited(push(force: true));

  static int _argb(Color c) {
    return ((c.a * 255.0).round() & 0xff) << 24 |
        ((c.r * 255.0).round() & 0xff) << 16 |
        ((c.g * 255.0).round() & 0xff) << 8 |
        ((c.b * 255.0).round() & 0xff);
  }

  Future<void> push({bool force = false}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_pushInProgress) {
      _pushQueued = true;
      _queuedForce = _queuedForce || force;
      return;
    }

    _pushInProgress = true;
    try {
      final tracker = StepTracker.instance;
      final steps = tracker.steps;
      final cal = tracker.calories.round();
      final mins = tracker.activeMinutes;
      final stepsGoal = tracker.stepsGoal;
      final calGoal = tracker.caloriesGoal.round();
      final minsGoal = tracker.activeMinutesGoal;

      final metrics = MetricColors.current;
      final palette = ThemeStore.palette;
      final scheme = palette.scheme(ThemeStore.night.value);

      final stepsColor = _argb(metrics.steps);
      final calColor = _argb(metrics.calories);
      final timeColor = _argb(metrics.active);
      final bgColor =
          _argb(scheme.surfaceContainerHighest.withValues(alpha: 0.92));
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
          bgColor == _lastBgColor &&
          mutedColor == _lastMutedColor;

      final now = DateTime.now();
      if (!force && unchanged) return;
      final elapsedMs = now.difference(_lastPush).inMilliseconds;
      if (!force && elapsedMs < 600) {
        _retryTimer?.cancel();
        _retryTimer = Timer(
          Duration(milliseconds: 600 - elapsedMs),
          () => unawaited(push()),
        );
        return;
      }

      final lang = _lang();
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.saveWidgetData<int>('cal', cal);
      await HomeWidget.saveWidgetData<int>('mins', mins);
      await HomeWidget.saveWidgetData<int>('steps_goal', stepsGoal);
      await HomeWidget.saveWidgetData<int>('cal_goal', calGoal);
      await HomeWidget.saveWidgetData<int>('mins_goal', minsGoal);
      await HomeWidget.saveWidgetData<String>(
        'steps_label',
        HomeText.getString(lang, 'steps'),
      );
      await HomeWidget.saveWidgetData<String>(
        'cal_label',
        HomeText.getString(lang, 'kcal'),
      );
      await HomeWidget.saveWidgetData<String>(
        'time_label',
        HomeText.getString(lang, 'minutes'),
      );
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
      _lastMutedColor = mutedColor;
      _lastPush = now;
    } catch (e, st) {
      debugPrint('HomeWidgetBridge.push: $e\n$st');
    } finally {
      _pushInProgress = false;
      if (_pushQueued) {
        final queuedForce = _queuedForce;
        _pushQueued = false;
        _queuedForce = false;
        unawaited(push(force: queuedForce));
      }
    }
  }

  static String _lang() {
    try {
      final language = MetaStore.language;
      if (language == 'fa' || language == 'en' || language == 'fr') {
        return language;
      }
    } catch (_) {}
    return 'en';
  }
}
