// lib/setting/motion/transitioner.dart

import 'package:flutter/material.dart';

enum TransitionTemplate {
  slideRight,
  slideLeft,

  zoomFade,

  fade, // فید ساده
  slideUp, // ورود از پایین
  slideDown, // ورود از بالا

  rotationFade, // چرخش + فید
  slideFadeRight, // اسلاید + فید از راست
  slideFadeLeft, // اسلاید + فید از چپ
}

class Transitioner {
  static Route<T> createRoute<T>({
    required Widget page,
    TransitionTemplate template = TransitionTemplate.slideRight,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder<T>(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        switch (template) {
          /// -------------------------------
          /// Slide Right
          /// -------------------------------
          case TransitionTemplate.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          /// -------------------------------
          /// Slide Left
          /// -------------------------------
          case TransitionTemplate.slideLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          /// -------------------------------
          /// Zoom Fade
          /// -------------------------------
          case TransitionTemplate.zoomFade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.85,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child,
              ),
            );

          /// -------------------------------
          /// Simple Fade
          /// -------------------------------
          case TransitionTemplate.fade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: child,
            );

          /// -------------------------------

          /// -------------------------------
          /// Slide Up
          /// -------------------------------
          case TransitionTemplate.slideUp:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          /// -------------------------------
          /// Slide Down
          /// -------------------------------
          case TransitionTemplate.slideDown:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );

          /// -------------------------------
          /// Rotation Fade
          /// -------------------------------
          case TransitionTemplate.rotationFade:
            return FadeTransition(
              opacity: curvedAnimation,
              child: RotationTransition(
                turns: Tween<double>(
                  begin: 0.92,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child,
              ),
            );

          /// -------------------------------
          /// Slide Fade Right
          /// -------------------------------
          case TransitionTemplate.slideFadeRight:
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0.0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );

          /// -------------------------------
          /// Slide Fade Left
          /// -------------------------------
          case TransitionTemplate.slideFadeLeft:
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.3, 0.0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
        }
      },
    );
  }
}
