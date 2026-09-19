import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

enum DeviceOrientation { vertical, horizontal }

class DeviceConfig {
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 950.0;

  static DeviceType getDeviceType(BuildContext context) {
    double shortestSide = MediaQuery.of(context).size.shortestSide;

    if (shortestSide >= desktopBreakpoint) return DeviceType.desktop;
    if (shortestSide >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static DeviceOrientation getOrientation(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape
        ? DeviceOrientation.horizontal
        : DeviceOrientation.vertical;
  }
}
