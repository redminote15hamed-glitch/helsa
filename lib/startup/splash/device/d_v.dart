// فایل: lib/startup/splash/device/d_v.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/startup/splash/widget/splash_object.dart';

class SplashDesktopVertical extends StatelessWidget {
  const SplashDesktopVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: SplashObject(),
    );
  }
}
