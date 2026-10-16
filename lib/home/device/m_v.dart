// lib/home/device/m_v.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class HomeMobileVertical extends StatelessWidget {
  final Widget header;
  final Widget activityCard;
  final Widget? permissionBanner;

  const HomeMobileVertical({
    super.key,
    required this.header,
    required this.activityCard,
    this.permissionBanner,
  });

  @override
  Widget build(BuildContext context) {
    final double padH = context.hM;
    final double padV = context.vS;
    final double gapHeaderCard = context.vS;
    final double gapCardBanner = context.vS;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            SizedBox(height: gapHeaderCard),
            activityCard,
            if (permissionBanner != null) ...[
              SizedBox(height: gapCardBanner),
              permissionBanner!,
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
