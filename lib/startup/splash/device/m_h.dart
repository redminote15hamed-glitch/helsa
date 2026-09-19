import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/startup/splash/widget/splash_object.dart';

class SplashMobileHorizontal extends StatelessWidget {
  final Function(ThemeData)? onThemeChanged;

  const SplashMobileHorizontal({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: SplashObject(),
    );
  }
}
