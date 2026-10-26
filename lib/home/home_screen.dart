// lib/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:helsa/home/widgets/apple_activity_card.dart';
import 'package:helsa/home/widgets/home_menu_button.dart';
import 'package:helsa/home/home_screen_widget/widget_promo_banner.dart';
import 'package:helsa/home/widgets/streak_badge.dart';
import 'package:helsa/setting/storage/streak_store.dart';
import 'package:helsa/home/services/sleep_mode.dart';
import 'package:helsa/home/widgets/ambient_background.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/services/walking_notification.dart';
import 'package:helsa/home/services/health_permissions.dart';
import 'package:helsa/home/services/step_foreground.dart';
import 'package:helsa/home/home_screen_widget/home_widget_bridge.dart';
import 'package:helsa/home/services/daily_recap.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/device/m_v.dart';
import 'package:helsa/home/device/m_h.dart';
import 'package:helsa/home/device/t_v.dart';
import 'package:helsa/home/device/t_h.dart';
import 'package:helsa/home/device/d_v.dart';
import 'package:helsa/home/device/d_h.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final StepTracker _tracker = StepTracker.instance;
  int _lastNotifSteps = -1;
  int _lastNotifGoal = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tracker.addListener(_onUpdate);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    StepForeground.instance.init();
    HomeWidgetBridge.instance.init();
    final perms = await HealthPermissions.requestAll();
    await _tracker.init();
    await WalkingNotification.instance.init();
    if (perms.readyForBackgroundNotify) {
      await StepForeground.instance.start();
      await StepForeground.instance.refresh(force: true);
    }
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowRecap());
  }

  Future<void> _maybeShowRecap() async {
    if (!mounted) return;
    await DailyRecap.maybeShow(context, _lang);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WalkingNotification.instance.onAppResumed();
      StepForeground.instance.ensureRunning();
    }
  }

  void _onUpdate() {
    _evalStreak();
    final s = _tracker.steps;
    final g = _tracker.stepsGoal;
    if (s != _lastNotifSteps || g != _lastNotifGoal) {
      _lastNotifSteps = s;
      _lastNotifGoal = g;
      StepForeground.instance.refresh(force: true);
    }
    HomeWidgetBridge.instance.push();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tracker.removeListener(_onUpdate);
    super.dispose();
  }

  String get _lang {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }

  Future<void> _requestActivityPermission() async {
    final ok = await HealthPermissions.ensureActivity();
    if (ok) {
      await _tracker.init();
      await StepForeground.instance.start();
      if (mounted) setState(() {});
      return;
    }
    final status = await Permission.activityRecognition.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Widget _header(String name) {
    // Menu sits on the *start* side: right in fa (RTL), left in en/fr (LTR)
    return Row(
      children: [
        const HomeMenuButton(),
        Expanded(
          child: TextFielder(
            text: name.isEmpty ? 'Helsa' : name,
            template: TextTemplate.title,
          ),
        ),
      ],
    );
  }

  Future<void> _evalStreak() async {
    try {
      final t = StepTracker.instance;
      await StreakStore.evaluate(
        steps: t.steps,
        stepsGoal: t.stepsGoal,
        calories: t.calories,
        caloriesGoal: t.caloriesGoal,
        activeMinutes: t.activeMinutes,
        activeMinutesGoal: t.activeMinutesGoal,
      );
    } catch (_) {}
  }

  Widget _card(String lang) {
    final double cal = (_tracker.calories as num).toDouble();
    final double calGoal = (_tracker.caloriesGoal as num).toDouble();
    int streak = 0;
    try {
      streak = StreakStore.currentStreak;
    } catch (_) {}

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Promo banner ABOVE metrics — when dismissed, steps move up
        WidgetPromoBanner(language: lang),
        StreakBadge(language: lang, streak: streak, isNight: SleepMode.isNightNow),
        AppleActivityCard(
          language: lang,
          steps: _tracker.steps,
          stepsGoal: _tracker.stepsGoal,
          calories: cal,
          caloriesGoal: calGoal,
          activeMinutes: _tracker.activeMinutes,
          activeMinutesGoal: _tracker.activeMinutesGoal,
          isWalking: _tracker.isWalking,
          isNight: SleepMode.isNightNow,
        ),
      ],
    );
  }

  Widget? _permissionBanner(String lang) {
    if (_tracker.permissionGranted) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFielder(
          text: HomeText.getString(lang, 'perm_activity'),
          template: TextTemplate.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.vX2s),
        Center(
          child: FilledButton(
            onPressed: _requestActivityPermission,
            child: Text(HomeText.getString(lang, 'perm_grant')),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = '';
    try {
      name = IdentityStore.fullName;
    } catch (_) {}
    final lang = _lang;

    final header = _header(name);
    final card = _card(lang);
    final banner = _permissionBanner(lang);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: DeviceModifier(
        defaultVertical: HomeMobileVertical(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        defaultHorizontal: HomeMobileHorizontal(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        mobileVertical: HomeMobileVertical(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        mobileHorizontal: HomeMobileHorizontal(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        tabletVertical: HomeTabletVertical(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        tabletHorizontal: HomeTabletHorizontal(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        desktopVertical: HomeDesktopVertical(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
        desktopHorizontal: HomeDesktopHorizontal(
          header: header,
          activityCard: card,
          permissionBanner: banner,
        ),
      ),
      ),
    );
  }
}
