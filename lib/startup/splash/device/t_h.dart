// فایل: lib/startup/splash/device/t_h.dart
import 'package:material_ui/material_ui.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/startup/splash/widget/splash_object.dart';

class SplashTabletHorizontal extends StatelessWidget {
  const SplashTabletHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkspaceArea(
      isScrollable: false,
      child: SplashObject(),
    );
  }
}
