// lib/home/device/d_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';

class HomeDesktopHorizontal extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeDesktopHorizontal({
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
          horizontal: context.hL,
          vertical: context.vM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SizedBox(height: context.vM),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: activityCard),
                  if (permissionBanner != null) ...[
                    SizedBox(width: context.hM),
                    Expanded(flex: 1, child: permissionBanner!),
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
