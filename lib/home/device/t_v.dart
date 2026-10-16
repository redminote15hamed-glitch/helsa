// lib/home/device/t_v.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';

class HomeTabletVertical extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeTabletVertical({
    super.key,
    required this.header,
    required this.activityCard,
    this.permissionBanner,
  });

  @override
  Widget build(BuildContext context) {
    return WorkspaceArea(
      isScrollable: true,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.baseScale * 22),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.hM,
              vertical: context.vS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                SizedBox(height: context.vS),
                activityCard,
                if (permissionBanner != null) ...[
                  SizedBox(height: context.vS),
                  permissionBanner!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
