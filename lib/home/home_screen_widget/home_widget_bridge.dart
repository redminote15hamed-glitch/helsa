// lib/home/home_screen_widget/home_widget_bridge.dart
// Force live widget updates (MIUI-safe).
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/storage/meta_store.dart';

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
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _heartbeat;

  Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId('helsa_widget');
    } catch (_) {}
    attach();
    await push(force: true);
    // MIUI sometimes drops one-shot updates — heartbeat while app alive
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      push(force: true);
    });
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
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _onTracker() {
    push();
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

    final unchanged = steps == _lastSteps &&
        cal == _lastCal &&
        mins == _lastMins &&
        stepsGoal == _lastStepsGoal &&
        calGoal == _lastCalGoal &&
        minsGoal == _lastMinsGoal;

    final now = DateTime.now();
    if (!force && unchanged) return;
    // throttle spam (sensor can fire very often)
    if (!force && now.difference(_lastPush).inMilliseconds < 800) return;

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

      // Call both name styles — some launchers only honor qualified name
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
      _lastPush = now;
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
