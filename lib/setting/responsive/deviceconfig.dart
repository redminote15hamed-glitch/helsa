import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

enum DeviceOrientation { vertical, horizontal }

class DeviceConfig {
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 950.0;

  static const double mobileFixedScale = 0.9;
  static const double mobileHorizontalScale = 1.0;
  static const double mobileVerticalScale = 0.85;

  static const double tabletFixedScale = 1.1;
  static const double tabletHorizontalScale = 1.3;
  static const double tabletVerticalScale = 1.3;

  static const double desktopFixedScale = 1.2;
  static const double desktopHorizontalScale = 0.9;
  static const double desktopVerticalScale = 0.9;

  static DeviceType getDeviceType(BuildContext context) {
    double shortestSide = MediaQuery.sizeOf(context).shortestSide;

    if (shortestSide >= desktopBreakpoint) return DeviceType.desktop;
    if (shortestSide >= tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  static DeviceOrientation getOrientation(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    return orientation == Orientation.landscape
        ? DeviceOrientation.horizontal
        : DeviceOrientation.vertical;
  }
}
