import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'speeds.dart';
import 'curves.dart';
import 'hardware_profiler.dart';

class AnimatorWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration touchDuration;
  final Curve touchCurve;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;
  final double startOffsetX;
  final double endOffsetX;
  final double startOffsetY;
  final double endOffsetY;
  final double startBlur;
  final double endBlur;
  final double flipX;
  final double flipY;
  final double perspective;
  final double touchScale;
  final bool isShimmer;
  final int delayMs;
  final bool ignoreHW;
  final VoidCallback? onComplete;

  const AnimatorWrapper({
    super.key,
    required this.child,
    this.duration = AS.balanced,
    this.curve = AC.easeOutCubic,
    this.touchDuration = AS.veryFast,
    this.touchCurve = AC.decelerate,
    this.startScale = 1.0,
    this.endScale = 1.0,
    this.startOpacity = 1.0,
    this.endOpacity = 1.0,
    this.startOffsetX = 0.0,
    this.endOffsetX = 0.0,
    this.startOffsetY = 0.0,
    this.endOffsetY = 0.0,
    this.startBlur = 0.0,
    this.endBlur = 0.0,
    this.flipX = 0.0,
    this.flipY = 0.0,
    this.perspective = 0.0,
    this.touchScale = 1.0,
    this.isShimmer = false,
    this.delayMs = 0,
    this.ignoreHW = false,
    this.onComplete,
  });

  @override
  State<AnimatorWrapper> createState() => _AnimatorWrapperState();
}

class _AnimatorWrapperState extends State<AnimatorWrapper>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _touchController;
  late Animation<double> _mainAnimation;
  late Animation<double> _touchAnimation;
  bool _ready = false;
  bool _removed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;

    final effectiveDuration = HardwareProfiler.getOptimizedSpeed(
      widget.duration,
      ignoreHW: widget.ignoreHW,
      context: context,
    );

    final effectiveTouchDuration = HardwareProfiler.getOptimizedSpeed(
      widget.touchDuration,
      ignoreHW: widget.ignoreHW,
      context: context,
    );

    _mainController = AnimationController(
      vsync: this,
      duration: effectiveDuration,
    );

    _touchController = AnimationController(
      vsync: this,
      duration: effectiveTouchDuration,
    );

    _mainAnimation = CurvedAnimation(
      parent: _mainController,
      curve: widget.curve,
    );

    _touchAnimation = CurvedAnimation(
      parent: _touchController,
      curve: widget.touchCurve,
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();

        final isExit = widget.endOpacity < widget.startOpacity ||
            widget.endScale < widget.startScale ||
            (widget.endOffsetX != 0.0 && widget.startOffsetX == 0.0) ||
            (widget.endOffsetY != 0.0 && widget.startOffsetY == 0.0) ||
            widget.endBlur > widget.startBlur;

        if (isExit && mounted) {
          setState(() => _removed = true);
        }
      }
    });

    if (widget.isShimmer) {
      if (HardwareProfiler.isLowEndDevice() && !widget.ignoreHW) {
        _mainController.value = 1.0;
      } else {
        _mainController.repeat(reverse: true);
      }
    } else if (effectiveDuration == AS.instant) {
      _mainController.value = 1.0;
    } else if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _mainController.forward();
      });
    } else {
      _mainController.forward();
    }
  }

  @override
  void dispose() {
    if (_ready) {
      _mainController.dispose();
      _touchController.dispose();
    }
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.touchScale == 1.0) return;
    _touchController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.touchScale == 1.0) return;
    _touchController.reverse();
  }

  void _onTapCancel() {
    if (widget.touchScale == 1.0) return;
    _touchController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (_removed) return const SizedBox.shrink();
    if (!_ready) return widget.child;

    final allowHeavy = HardwareProfiler.shouldAllowHeavyEffects(
      ignoreHW: widget.ignoreHW,
      context: context,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_mainAnimation, _touchAnimation]),
      builder: (context, child) {
        final t = _mainAnimation.value;
        final touchT = _touchAnimation.value;

        final baseScale = lerpDouble(widget.startScale, widget.endScale, t)!;
        final touchFactor = lerpDouble(1.0, widget.touchScale, touchT)!;
        final scale = baseScale * touchFactor;

        final opacity =
            lerpDouble(widget.startOpacity, widget.endOpacity, t)!.clamp(0.0, 1.0);

        final offsetX = lerpDouble(widget.startOffsetX, widget.endOffsetX, t)!;
        final offsetY = lerpDouble(widget.startOffsetY, widget.endOffsetY, t)!;

        final blur = allowHeavy
            ? lerpDouble(widget.startBlur, widget.endBlur, t)!
            : 0.0;

        final transform = Matrix4.identity();
        if (allowHeavy) {
          if (widget.perspective > 0) {
            transform.setEntry(3, 2, widget.perspective * 0.001);
          }
          if (widget.flipX != 0.0) {
            transform.rotateX((1.0 - t) * widget.flipX * math.pi);
          }
          if (widget.flipY != 0.0) {
            transform.rotateY((1.0 - t) * widget.flipY * math.pi);
          }
        }

        Widget result = Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: widget.child,
              ),
            ),
          ),
        );

        if (blur > 0.01) {
          result = ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: result,
          );
        }

        if (widget.touchScale != 1.0) {
          result = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: result,
          );
        }

        return result;
      },
    );
  }
}
