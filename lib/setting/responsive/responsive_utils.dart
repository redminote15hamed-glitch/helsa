// lib/setting/responsive/responsive_utils.dart
import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // استفاده از اندازه مستقل از جهت برای بررسی تبلت/موبایل
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

  // فواصل ثابت (بدون تغییر با چرخش صفحه)
  double get x4s => baseScale * 0.3;
  double get x3s => baseScale * 0.4;
  double get x2s => baseScale * 0.5;
  double get xs => baseScale * 0.65;
  double get s => baseScale * 0.85;
  double get m => baseScale * 1.0;
  double get l => baseScale * 1.3;
  double get xl => baseScale * 1.7;
  double get x2l => baseScale * 2.3;
  double get x3l => baseScale * 3.2;
  double get x4l => baseScale * 4.5;
  double get x5l => baseScale * 6.0;
  double get x6l => baseScale * 15.0;

  // فواصل متغیر هوشمند (حساس به جهت صفحه برای جلوگیری از به هم ریختگی در لنداسکیپ)
  double get _mainAxisDimension => isVertical ? screenWidth : screenHeight;
  double get _crossAxisDimension => isVertical ? screenHeight : screenWidth;

  double get hX4s => _mainAxisDimension * 0.0025;
  double get hX3s => _mainAxisDimension * 0.005;
  double get hX2s => _mainAxisDimension * 0.01;
  double get hXs => _mainAxisDimension * 0.015;
  double get hS => _mainAxisDimension * 0.025;
  double get hSPlus => _mainAxisDimension * 0.035;
  double get hM => _mainAxisDimension * 0.05;
  double get hMPlus => _mainAxisDimension * 0.065;
  double get hL => _mainAxisDimension * 0.08;
  double get hLPlus => _mainAxisDimension * 0.1;
  double get hXl => _mainAxisDimension * 0.12;
  double get hX2l => _mainAxisDimension * 0.16;
  double get hX3l => _mainAxisDimension * 0.2;
  double get hX4l => _mainAxisDimension * 0.25;
  double get hX5l => _mainAxisDimension * 0.35;
  double get hX6l => _mainAxisDimension * 0.55;

  double get vX6s => _crossAxisDimension * 0.0005;
  double get vX5s => _crossAxisDimension * 0.0015;
  double get vX4s => _crossAxisDimension * 0.0025;
  double get vX3s => _crossAxisDimension * 0.005;
  double get vX2s => _crossAxisDimension * 0.01;
  double get vXs => _crossAxisDimension * 0.015;
  double get vS => _crossAxisDimension * 0.025;
  double get vSPlus => _crossAxisDimension * 0.035;
  double get vM => _crossAxisDimension * 0.05;
  double get vMPlus => _crossAxisDimension * 0.065;
  double get vL => _crossAxisDimension * 0.08;
  double get vLPlus => _crossAxisDimension * 0.1;
  double get vXl => _crossAxisDimension * 0.12;
  double get vX2l => _crossAxisDimension * 0.16;
  double get vX3l => _crossAxisDimension * 0.2;
  double get vX4l => _crossAxisDimension * 0.25;
  double get vX5l => _crossAxisDimension * 0.35;
  double get vX6l => _crossAxisDimension * 0.55;
}
