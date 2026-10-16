// lib/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:helsa/home/widgets/hex_activity_card.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/services/walking_notification.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tracker.addListener(_onUpdate);
    _tracker.init();
    WalkingNotification.instance.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ورود مجدد به اپ → رفع suppress یک‌ساعته و رفرش نوتیف
      WalkingNotification.instance.onAppResumed();
    }
  }

  void _onUpdate() {
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
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      await _tracker.init();
      if (mounted) setState(() {});
      return;
    }
    status = await Permission.sensors.request();
    if (status.isGranted) {
      await _tracker.init();
      if (mounted) setState(() {});
      return;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Widget _header(String name) {
    return TextFielder(
      text: name.isEmpty ? 'Helsa' : name,
      template: TextTemplate.title,
    );
  }

  Widget _card(String lang) {
    final double cal = (_tracker.calories as num).toDouble();
    final double calGoal = (_tracker.caloriesGoal as num).toDouble();

    return HexActivityCard(
      language: lang,
      steps: _tracker.steps,
      stepsGoal: _tracker.stepsGoal,
      calories: cal,
      caloriesGoal: calGoal,
      activeMinutes: _tracker.activeMinutes,
      activeMinutesGoal: _tracker.activeMinutesGoal,
      activeTimeText:
          '${_tracker.activeTimeLabel} / ${_tracker.activeMinutesGoal} ${HomeText.getString(lang, 'minutes')}',
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: DeviceModifier(
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
    );
  }
}
