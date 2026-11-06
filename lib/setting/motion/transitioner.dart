// lib/setting/motion/transitioner.dart

import 'dart:math' as math;

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

  /// Two-phase: [origin] → ~50% card → fullscreen (same as MenuExpandHost).
  /// Pass [origin] via [Transitioner.createRoute]. Default duration ~1300ms.
  expandTwoPhase,
}

class Transitioner {
  static Route<T> createRoute<T>({
    required Widget page,
    TransitionTemplate template = TransitionTemplate.slideRight,
    Duration duration = const Duration(milliseconds: 500),

    /// Source rect for [TransitionTemplate.expandTwoPhase]
    /// (e.g. menu row via [Transitioner.rectOf]).
    Rect? origin,
  }) {
    final effectiveDuration = template == TransitionTemplate.expandTwoPhase &&
            duration.inMilliseconds == 500
        ? const Duration(milliseconds: 1300)
        : duration;

    return PageRouteBuilder<T>(
      opaque: template != TransitionTemplate.expandTwoPhase,
      barrierColor: template == TransitionTemplate.expandTwoPhase
          ? Colors.transparent
          : null,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: effectiveDuration,
      reverseTransitionDuration: effectiveDuration,
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

          /// -------------------------------
          /// Expand two-phase (MenuExpandHost)
          /// origin → 50% card → fullscreen
          /// -------------------------------
          case TransitionTemplate.expandTwoPhase:
            return _ExpandTwoPhaseTransition(
              animation: animation,
              origin: origin,
              child: child,
            );
        }
      },
    );
  }

  /// Same helper as [MenuExpandHost.rectOf] — capture a widget's global rect.
  static Rect rectOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromLTWH(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.4,
        48,
      );
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// Mirrors MenuExpandHost geometry:
/// phase 0..0.40 → origin → half card
/// phase 0.40..1 → half → fullscreen
/// reverse path on pop.
class _ExpandTwoPhaseTransition extends StatelessWidget {
  const _ExpandTwoPhaseTransition({
    required this.animation,
    required this.origin,
    required this.child,
  });

  final Animation<double> animation;
  final Rect? origin;
  final Widget child;

  /// Phase split identical to MenuExpandHost.
  static const double _phase1End = 0.40;

  Rect _fallbackOrigin(Size screen) {
    return Rect.fromLTWH(
      screen.width * 0.3,
      screen.height * 0.4,
      screen.width * 0.4,
      48,
    );
  }

  Rect _halfRect(Size screen, Rect origin, bool isRtl) {
    final w = screen.width * 0.50;
    final h = screen.height * 0.50;
    final originCenterY = origin.center.dy;
    var top = originCenterY - h / 2;
    top = top.clamp(24.0, screen.height - h - 24.0);

    double left;
    if (isRtl) {
      left = (origin.left - w - 8).clamp(16.0, screen.width - w - 16);
    } else {
      left = (origin.right + 8).clamp(16.0, screen.width - w - 16);
    }
    final preferCenterLeft = (screen.width - w) / 2;
    left = left * 0.55 + preferCenterLeft * 0.45;
    left = left.clamp(16.0, screen.width - w - 16);
    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _fullRect(Size screen) => Offset.zero & screen;

  Rect _lerpRect(Rect a, Rect b, double t) {
    final tt = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    return Rect.lerp(a, b, tt)!;
  }

  Rect _rectFor(double t, Size screen, Rect origin, bool isRtl) {
    final half = _halfRect(screen, origin, isRtl);
    final full = _fullRect(screen);
    if (t <= _phase1End) {
      final p = (t / _phase1End).clamp(0.0, 1.0);
      return _lerpRect(origin, half, p);
    }
    final p = ((t - _phase1End) / (1.0 - _phase1End)).clamp(0.0, 1.0);
    return _lerpRect(half, full, p);
  }

  double _radiusFor(double t) {
    if (t <= _phase1End) {
      final p = t / _phase1End;
      return _lerp(18, 20, p);
    }
    final p = (t - _phase1End) / (1 - _phase1End);
    return _lerp(20, 0, p);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _barrierOpacity(double t) {
    return Curves.easeOut.transform(t.clamp(0.0, 1.0)) * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final src = origin ?? _fallbackOrigin(screen);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final rect = _rectFor(t, screen, src, isRtl);
        final radius = _radiusFor(t);
        final scrim = _barrierOpacity(t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Soft scrim — same strength as MenuExpandHost
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: scrim),
                ),
              ),
            ),
            Positioned(
              left: rect.left,
              top: rect.top,
              width: math.max(rect.width, 1),
              height: math.max(rect.height, 1),
              child: Material(
                elevation: 12 * t,
                color: theme.colorScheme.surface,
                shadowColor: Colors.black54,
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(rect.width, rect.height),
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
