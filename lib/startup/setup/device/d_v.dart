// فایل: lib/startup/language/device/d_v.dart
import 'package:material_ui/material_ui.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/kit/textfielder.dart';

class SetupDesktopVertical extends StatelessWidget {
  const SetupDesktopVertical({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: Center(
        child: TextFielder(
          text: 'دسکتاپ عمودی (Pivot)',
          template: TextTemplate.title,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
