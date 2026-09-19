import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/device_config.dart';

class DeviceModifier extends StatelessWidget {
  final Widget defaultVertical;
  final Widget defaultHorizontal;
  final Widget mobileVertical;
  final Widget? mobileHorizontal;
  final Widget? tabletVertical;
  final Widget? tabletHorizontal;
  final Widget? desktopVertical;
  final Widget? desktopHorizontal;

  const DeviceModifier({
    super.key,
    required this.defaultVertical,
    required this.defaultHorizontal,
    required this.mobileVertical,
    this.mobileHorizontal,
    this.tabletVertical,
    this.tabletHorizontal,
    this.desktopVertical,
    this.desktopHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    final type = DeviceConfig.getDeviceType(context);
    final orientation = DeviceConfig.getOrientation(context);

    if (orientation == DeviceOrientation.vertical) {
      switch (type) {
        case DeviceType.desktop:
          return desktopVertical ?? tabletVertical ?? mobileVertical;
        case DeviceType.tablet:
          return tabletVertical ?? mobileVertical;
        case DeviceType.mobile:
          return mobileVertical;
      }
    } else {
      switch (type) {
        case DeviceType.desktop:
          return desktopHorizontal ??
              tabletHorizontal ??
              mobileHorizontal ??
              defaultHorizontal;
        case DeviceType.tablet:
          return tabletHorizontal ?? mobileHorizontal ?? defaultHorizontal;
        case DeviceType.mobile:
          return mobileHorizontal ?? defaultHorizontal;
      }
    }
  }
}
