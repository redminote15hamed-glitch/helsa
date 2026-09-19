// فایل: lib/startup/language/device/d_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/kit/textfielder.dart';

class SetupDesktopHorizontal extends StatelessWidget {
  const SetupDesktopHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: Center(
        child: TextFielder(
          text: 'دسکتاپ افقی',
          template: TextTemplate.title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
