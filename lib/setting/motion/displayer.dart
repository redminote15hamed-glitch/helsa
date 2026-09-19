import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MotionTemplate {
  fade,
  leftSlide,
  rightSlide,
  topSlide,
  bottomSlide,
  popIn,
  flipX,
  flipY,
  flipYReverse,
  zoomFade,
}

class Displayer extends StatelessWidget {
  final Widget child;
  final int index;
  final MotionTemplate template;
  final Duration baseDuration;
  final Duration intervalDelay;

  const Displayer({
    super.key,
    required this.child,
    required this.index,
    this.template = MotionTemplate.fade,
    this.baseDuration = const Duration(milliseconds: 700),
    this.intervalDelay = const Duration(milliseconds: 160),
  });

  @override
  Widget build(BuildContext context) {
    final startDelay = intervalDelay * index;

    // استفاده از FutureBuilder برای مدیریت زمان‌بندی شروع انیمیشن
    return FutureBuilder<bool>(
      future: Future.delayed(startDelay, () => true),
      initialData: false,
      builder: (context, snapshot) {
        final shouldAnimate = snapshot.data ?? false;
        final Curve customCurve = template == MotionTemplate.popIn
            ? Curves.elasticOut
            : Curves.easeOutCubic;

        return TweenAnimationBuilder<double>(
          // کلید داخلی تضمین می‌کند که با هر بازسازی، انیمیشن ریست شود
          key: ValueKey('animator_${index}_$shouldAnimate'),
          tween: Tween<double>(begin: 0.0, end: shouldAnimate ? 1.0 : 0.0),
          duration: baseDuration,
          curve: customCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: template == MotionTemplate.popIn ? 1.0 : value,
              child: _applyCreativeTransformation(value, child!),
            );
          },
          child: child,
        );
      },
    );
  }

  Widget _applyCreativeTransformation(double value, Widget child) {
    const double slideOffset = 45.0;
    switch (template) {
      case MotionTemplate.fade:
        return child;
      case MotionTemplate.leftSlide:
        return Transform.translate(
            offset: Offset(-slideOffset * (1.0 - value), 0.0), child: child);
      case MotionTemplate.rightSlide:
        return Transform.translate(
            offset: Offset(slideOffset * (1.0 - value), 0.0), child: child);
      case MotionTemplate.topSlide:
        return Transform.translate(
            offset: Offset(0.0, -slideOffset * (1.0 - value)), child: child);
      case MotionTemplate.bottomSlide:
        return Transform.translate(
            offset: Offset(0.0, slideOffset * (1.0 - value)), child: child);
      case MotionTemplate.popIn:
        return Transform.scale(scale: value, child: child);
      case MotionTemplate.flipX:
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX((1.0 - value) * math.pi / 2),
          alignment: Alignment.center,
          child: child,
        );
      case MotionTemplate.flipY:
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY((1.0 - value) * -math.pi / 2),
          alignment: Alignment.centerRight,
          child: child,
        );
      case MotionTemplate.flipYReverse:
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY((1.0 - value) * math.pi / 2),
          alignment: Alignment.centerLeft,
          child: child,
        );
      case MotionTemplate.zoomFade:
        final double scaleValue = 1.5 - (0.5 * value);
        return Transform.scale(scale: scaleValue, child: child);
    }
  }
}
