// فایل: lib/startup/language/device/m_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/kit/textfielder.dart';

class SetupMobileHorizontal extends StatelessWidget {
  const SetupMobileHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: Center(
        child: TextFielder(
          text: 'موبایل افقی',
          template: TextTemplate.title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
