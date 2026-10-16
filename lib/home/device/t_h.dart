// lib/home/device/t_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';

class HomeTabletHorizontal extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeTabletHorizontal({
    super.key,
    required this.header,
    required this.activityCard,
    this.permissionBanner,
  });

  @override
  Widget build(BuildContext context) {
    return WorkspaceArea(
      isScrollable: false,
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: activityCard),
                  if (permissionBanner != null) ...[
                    SizedBox(width: context.hS),
                    Expanded(flex: 2, child: permissionBanner!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
