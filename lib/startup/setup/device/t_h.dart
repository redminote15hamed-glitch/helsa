// فایل: lib/startup/language/device/t_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/kit/textfielder.dart';

class SetupTabletHorizontal extends StatelessWidget {
  const SetupTabletHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: Center(
        child: TextFielder(
          text: 'تبلت افقی',
          template: TextTemplate.title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
