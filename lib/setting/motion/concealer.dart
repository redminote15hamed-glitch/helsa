// lib/setting/motion/concealer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ConcealTemplate {
  fade,
  leftSlide,
  rightSlide,
  topSlide,
  bottomSlide,
  popOut,
  flipX,
  flipY,
  zoomFade,
}

class Concealer extends StatelessWidget {
  final Widget child;
  final int index;
  final ConcealTemplate template;
  final Duration baseDuration;
  final Duration intervalDelay;

  const Concealer({
    super.key,
    required this.child,
    required this.index,
    this.template = ConcealTemplate.fade,
    this.baseDuration = const Duration(milliseconds: 600),
    this.intervalDelay = const Duration(milliseconds: 160),
  });

  @override
  Widget build(BuildContext context) {
    final startDelay = const Duration(seconds: 1) + (intervalDelay * index);
    return FutureBuilder<bool>(
      key: ValueKey('concealer_$index'),
      future: Future.delayed(startDelay, () => true),
      initialData: false,
      builder: (context, snapshot) {
        final shouldConceal = snapshot.data ?? false;
        final Curve customCurve = template == ConcealTemplate.popOut
            ? Curves.easeInBack
            : Curves.easeInCubic;

        return TweenAnimationBuilder<double>(
          // در شروع انیمیشن مقدار روی 1.0 (کاملا آشکار) تنظیم شده و با شروع شدن وضعیت مخفی‌سازی، به سمت 0.0 حرکت می‌کند.
          tween: Tween<double>(begin: 1.0, end: shouldConceal ? 0.0 : 1.0),
          duration: baseDuration,
          curve: customCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: template == ConcealTemplate.popOut ? 1.0 : value,
              child: _applyConcealTransformation(value, child!),
            );
          },
          child: child,
        );
      },
    );
  }

  Widget _applyConcealTransformation(double value, Widget child) {
    const double slideOffset = 45.0;
    switch (template) {
      case ConcealTemplate.fade:
        return child;
      case ConcealTemplate.leftSlide:
        return Transform.translate(
          offset: Offset(-slideOffset * (1.0 - value), 0.0),
          child: child,
        );
      case ConcealTemplate.rightSlide:
        return Transform.translate(
          offset: Offset(slideOffset * (1.0 - value), 0.0),
          child: child,
        );
      case ConcealTemplate.topSlide:
        return Transform.translate(
          offset: Offset(0.0, -slideOffset * (1.0 - value)),
          child: child,
        );
      case ConcealTemplate.bottomSlide:
        return Transform.translate(
          offset: Offset(0.0, slideOffset * (1.0 - value)),
          child: child,
        );
      case ConcealTemplate.popOut:
        return Transform.scale(
          scale: value,
          child: child,
        );
      case ConcealTemplate.flipX:
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX((1.0 - value) * -math.pi / 2),
          alignment: Alignment.center,
          child: child,
        );
      case ConcealTemplate.flipY:
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY((1.0 - value) * math.pi / 2),
          alignment: Alignment.center,
          child: child,
        );
      case ConcealTemplate.zoomFade:
        final double scaleValue = 0.5 + (0.5 * value);
        return Transform.scale(
          scale: scaleValue,
          child: child,
        );
    }
  }
}
