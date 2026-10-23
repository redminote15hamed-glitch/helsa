// lib/home/home_screen_widget/home_widget_bridge.dart
// Home screen widget — live update from app + system (min 30 min)
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/storage/meta_store.dart';

class HomeWidgetBridge {
  HomeWidgetBridge._();
  static final HomeWidgetBridge instance = HomeWidgetBridge._();

  /// Android provider class name. The plugin resolves this relative to the app package.
  static const String _androidName = 'HelsaWidgetProvider';
  bool _listening = false;
  int _lastSteps = -1;
  int _lastCal = -1;
  int _lastMins = -1;

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
    if (steps == _lastSteps && cal == _lastCal && mins == _lastMins) return;
    final lang = _lang();
    final stepsLabel = lang == 'fa' ? 'قدم' : lang == 'fr' ? 'pas' : 'steps';
    final calLabel = lang == 'fa' ? 'کالری' : 'kcal';
    final timeLabel = lang == 'fa' ? 'دقیقه' : lang == 'fr' ? 'min' : 'min';

    try {
      await HomeWidget.saveWidgetData<int>('steps', steps);
      await HomeWidget.saveWidgetData<int>('cal', cal);
      await HomeWidget.saveWidgetData<int>('mins', mins);
      await HomeWidget.saveWidgetData<String>('steps_label', stepsLabel);
      await HomeWidget.saveWidgetData<String>('cal_label', calLabel);
      await HomeWidget.saveWidgetData<String>('time_label', timeLabel);
      await HomeWidget.updateWidget(
        name: _androidName,
        androidName: _androidName,
      );
      // Cache only after a successful update so failures can be retried.
      _lastSteps = steps;
      _lastCal = cal;
      _lastMins = mins;
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
