import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/setting/motion/transitioner.dart';

// وارد کردن SetupScreen به جای IntroScreen
import 'package:helsa/startup/setup/setup.dart';

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

    // تغییر اینجا: هدایت مستقیم به SetupScreen
    await Navigator.of(context).pushReplacement(
      // استفاده از pushReplacement برای جلوگیری از بازگشت به اسپلش
      Transitioner.createRoute(
        page: const SetupScreen(),
        template: TransitionTemplate.zoomFade,
      ),
    );

    // اگر می‌خواهید پس از بازگشت از Setup (در صورت پاپ شدن)، دوباره اسپلش اجرا شود:
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _renderKey = UniqueKey();
      });
      // معمولاً اسپلش نباید دوباره تکرار شود، اما طبق منطق خودتان اضافه شد
      // _startSplashCycle();
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
