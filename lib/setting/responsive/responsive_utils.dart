import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/deviceconfig.dart'; // مطمئن شوید این مسیر درست وارد شده باشد

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;

  bool get isVertical => screenHeight >= screenWidth;

  double get _baseSize {
    if (shortestSide < 600) return 16.0;
    if (shortestSide < 950) return 18.0;
    return 26.0;
  }

  double get baseScale {
    if (screenWidth < 340 || screenHeight < 340) {
      return (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.045;
    }

    return _baseSize;
  }

  // ==========================================
  // گترهای کمکی برای یافتن ضریب داینامیک بر اساس نوع دستگاه
  // ==========================================

  double get _fixedMultiplier {
    final type = DeviceConfig.getDeviceType(this);
    switch (type) {
      case DeviceType.desktop:
        return DeviceConfig.desktopFixedScale;
      case DeviceType.tablet:
        return DeviceConfig.tabletFixedScale;
      case DeviceType.mobile:
        return DeviceConfig.mobileFixedScale;
    }
  }

  double get _horizontalMultiplier {
    final type = DeviceConfig.getDeviceType(this);
    switch (type) {
      case DeviceType.desktop:
        return DeviceConfig.desktopHorizontalScale;
      case DeviceType.tablet:
        return DeviceConfig.tabletHorizontalScale;
      case DeviceType.mobile:
        return DeviceConfig.mobileHorizontalScale;
    }
  }

  double get _verticalMultiplier {
    final type = DeviceConfig.getDeviceType(this);
    switch (type) {
      case DeviceType.desktop:
        return DeviceConfig.desktopVerticalScale;
      case DeviceType.tablet:
        return DeviceConfig.tabletVerticalScale;
      case DeviceType.mobile:
        return DeviceConfig.mobileVerticalScale;
    }
  }

  // ==========================================
  // متغیرهای ثابت (معمولی) + اعمال ضریب Fixed
  // ==========================================

  double get x4s => baseScale * 0.3 * _fixedMultiplier;
  double get x3s => baseScale * 0.4 * _fixedMultiplier;
  double get x2s => baseScale * 0.5 * _fixedMultiplier;
  double get xs => baseScale * 0.65 * _fixedMultiplier;

  double get s => baseScale * 0.85 * _fixedMultiplier;
  double get m => baseScale * 1.0 * _fixedMultiplier;
  double get l => baseScale * 1.3 * _fixedMultiplier;

  double get xl => baseScale * 1.7 * _fixedMultiplier;
  double get x2l => baseScale * 2.3 * _fixedMultiplier;
  double get x3l => baseScale * 3.2 * _fixedMultiplier;
  double get x4l => baseScale * 4.5 * _fixedMultiplier;
  double get x5l => baseScale * 6.0 * _fixedMultiplier;
  double get x6l => baseScale * 15.0 * _fixedMultiplier;

  // ==========================================
  // متغیرهای افقی + اعمال ضریب Horizontal
  // ==========================================

  double get hX4s => baseScale * 0.15 * _horizontalMultiplier;
  double get hX3s => baseScale * 0.25 * _horizontalMultiplier;
  double get hX2s => baseScale * 0.4 * _horizontalMultiplier;
  double get hXs => baseScale * 0.6 * _horizontalMultiplier;

  double get hS => baseScale * 0.9 * _horizontalMultiplier;
  double get hSPlus => baseScale * 1.15 * _horizontalMultiplier;

  double get hM => baseScale * 1.6 * _horizontalMultiplier;
  double get hMPlus => baseScale * 2.0 * _horizontalMultiplier;

  double get hL => baseScale * 2.5 * _horizontalMultiplier;
  double get hLPlus => baseScale * 3.2 * _horizontalMultiplier;

  double get hXl => baseScale * 4.0 * _horizontalMultiplier;
  double get hX2l => baseScale * 5.2 * _horizontalMultiplier;
  double get hX3l => baseScale * 6.8 * _horizontalMultiplier;
  double get hX4l => baseScale * 8.5 * _horizontalMultiplier;
  double get hX5l => baseScale * 10 * _horizontalMultiplier;
  double get hX6l => baseScale * 12 * _horizontalMultiplier;

  // ==========================================
  // متغیرهای عمودی + اعمال ضریب Vertical
  // ==========================================
  double get vX7s => baseScale * 0.05 * _verticalMultiplier;
  double get vX6s => baseScale * 0.08 * _verticalMultiplier;
  double get vX5s => baseScale * 0.12 * _verticalMultiplier;
  double get vX4s => baseScale * 0.18 * _verticalMultiplier;
  double get vX3s => baseScale * 0.3 * _verticalMultiplier;
  double get vX2s => baseScale * 0.5 * _verticalMultiplier;
  double get vXs => baseScale * 0.75 * _verticalMultiplier;

  double get vS => baseScale * 1.2 * _verticalMultiplier;
  double get vSPlus => baseScale * 1.6 * _verticalMultiplier;

  double get vM => baseScale * 2.9 * _verticalMultiplier;
  double get vMPlus => baseScale * 3.0 * _verticalMultiplier;

  double get vL => baseScale * 3.8 * _verticalMultiplier;
  double get vLPlus => baseScale * 5.0 * _verticalMultiplier;

  double get vXl => baseScale * 6.5 * _verticalMultiplier;
  double get vX2l => baseScale * 8.5 * _verticalMultiplier;
  double get vX3l => baseScale * 12.0 * _verticalMultiplier;
  double get vX4l => baseScale * 16.0 * _verticalMultiplier;
  double get vX5l => baseScale * 22.0 * _verticalMultiplier;
  double get vX6l => baseScale * 34.0 * _verticalMultiplier;
}
