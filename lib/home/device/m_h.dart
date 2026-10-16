// lib/home/device/m_h.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class HomeMobileHorizontal extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeMobileHorizontal({
    super.key,
    required this.header,
    required this.activityCard,
    this.permissionBanner,
  });

  @override
  Widget build(BuildContext context) {
    final double padH = context.hM;
    final double padV = context.vS;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
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
