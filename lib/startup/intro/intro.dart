import 'package:flutter/material.dart';
import 'package:helsa/setting/motion/transitioner.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/startup/setup/setup.dart';
import 'device/m_v.dart';
import 'device/m_h.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // این کلید باعث ریست شدن کامل انیمیشن‌ها می‌شود
  Key _introKey = UniqueKey();

  void _goToSetup(BuildContext context) async {
    await Navigator.of(context).push(
      Transitioner.createRoute(
        page: const SetupScreen(),
        template: TransitionTemplate.fade,
      ),
    );
    // وقتی کاربر از Setup برگشت، کلید را تغییر می‌دهیم تا همه چیز بازسازی شود
    setState(() {
      _introKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _introKey, // اعمال کلید جدید برای بازسازی صفحه
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: DeviceModifier(
        defaultVertical: IntroMobileVertical(
          onContinue: () => _goToSetup(context),
        ),
        defaultHorizontal: IntroMobileHorizontal(
          onContinue: () => _goToSetup(context),
        ),
        mobileVertical: IntroMobileVertical(
          onContinue: () => _goToSetup(context),
        ),
        mobileHorizontal: IntroMobileHorizontal(
          onContinue: () => _goToSetup(context),
        ),
      ),
    );
  }
}
