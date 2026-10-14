import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/setting/motion/transitioner.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/startup/setup/setup.dart';
import 'package:helsa/home/home_screen.dart';

import 'device/m_v.dart';
import 'device/m_h.dart';
import 'device/t_v.dart';
import 'device/t_h.dart';
import 'device/d_v.dart';
import 'device/d_h.dart';

class SplashScreen extends StatefulWidget {
  final Function(ThemeData) onThemeChanged;

  const SplashScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Key _renderKey = UniqueKey();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startSplashCycle();
  }

  void _startSplashCycle() async {
    if (_isNavigating) return;

    await Future.delayed(const Duration(milliseconds: 2700));

    if (!mounted) return;

    setState(() {
      _isNavigating = true;
    });

    // اگر setup قبلاً در Hive تمام شده → خانه؛ وگرنه → setup
    final Widget nextPage = ProfileStore.isSetupDone
        ? const HomeScreen()
        : const SetupScreen();

    await Navigator.of(context).pushReplacement(
      Transitioner.createRoute(
        page: nextPage,
        template: TransitionTemplate.zoomFade,
      ),
    );

    if (mounted) {
      setState(() {
        _isNavigating = false;
        _renderKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _renderKey,
      body: const DeviceModifier(
        defaultVertical: SplashMobileVertical(),
        defaultHorizontal: SplashMobileHorizontal(),
        mobileVertical: SplashMobileVertical(),
        mobileHorizontal: SplashMobileHorizontal(),
        tabletVertical: SplashTabletVertical(),
        tabletHorizontal: SplashTabletHorizontal(),
        desktopVertical: SplashDesktopVertical(),
        desktopHorizontal: SplashDesktopHorizontal(),
      ),
    );
  }
}
