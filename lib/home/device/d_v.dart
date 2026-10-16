// lib/home/device/d_v.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';

class HomeDesktopVertical extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeDesktopVertical({
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
          constraints: BoxConstraints(maxWidth: context.baseScale * 28),
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
                activityCard,
                if (permissionBanner != null) ...[
                  SizedBox(height: context.vM),
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
