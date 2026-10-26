// lib/home/home_screen_widget/home_widget_bridge.dart
// Live update for main (3-metric) + steps-only widgets
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/storage/meta_store.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();
  static final HomeWidgetBridge instance = HomeWidgetBridge._();

  static const String _mainWidget = 'com.example.helsa.HelsaWidgetProvider';
  static const String _stepsWidget = 'com.example.helsa.HelsaStepsWidgetProvider';

  bool _listening = false;
  int _lastSteps = -1;
  int _lastCal = -1;
  int _lastMins = -1;
  int _lastStepsGoal = -1;
  int _lastCalGoal = -1;
  int _lastMinsGoal = -1;

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('helsa_widget');
    } catch (_) {}
    attach();
    await push();
  }

  void attach() {
    if (_listening) return;
    _listening = true;
    StepTracker.instance.addListener(_onTracker);
  }

  void detach() {
    if (!_listening) return;
    _listening = false;
    StepTracker.instance.removeListener(_onTracker);
  }

  void _onTracker() {
    push();
  }

  Future<void> push() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final t = StepTracker.instance;
    final steps = t.steps;
    final cal = t.calories.round();
    final mins = t.activeMinutes;
    final stepsGoal = t.stepsGoal;
    final calGoal = t.caloriesGoal.round();
    final minsGoal = t.activeMinutesGoal;

    if (steps == _lastSteps &&
        cal == _lastCal &&
        mins == _lastMins &&
        stepsGoal == _lastStepsGoal &&
        calGoal == _lastCalGoal &&
        minsGoal == _lastMinsGoal) {
      return;
    }

    final lang = _lang();
    final stepsLabel = lang == 'fa' ? 'قدم' : lang == 'fr' ? 'pas' : 'steps';
    final calLabel = lang == 'fa' ? 'کالری' : 'kcal';
    final timeLabel = lang == 'fa' ? 'دقیقه' : lang == 'fr' ? 'min' : 'min';

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

      await HomeWidget.updateWidget(
        name: _mainWidget,
        androidName: _mainWidget,
      );
      await HomeWidget.updateWidget(
        name: _stepsWidget,
        androidName: _stepsWidget,
      );

      _lastSteps = steps;
      _lastCal = cal;
      _lastMins = mins;
      _lastStepsGoal = stepsGoal;
      _lastCalGoal = calGoal;
      _lastMinsGoal = minsGoal;
    } catch (error, stackTrace) {
      debugPrint('HelSa widget update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String _lang() {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }
}
