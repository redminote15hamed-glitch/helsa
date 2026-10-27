// lib/setting/motion/animator/effects/genie_effect.dart
// Real Mac-like Genie: horizontal strip warp toward an edge.
// Better smoothness via more strips + smoothstep curve.
// Low-end devices fall back to soft scale slide (HardwareProfiler).
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/speeds.dart';
import '../core/curves.dart';
import '../core/hardware_profiler.dart';

enum GenieEdge { start, end, top, bottom }

class GenieEffect extends StatefulWidget {
  final Widget child;
  final bool opening; // true = enter (expand from edge), false = exit
  final Duration duration;
  final Curve curve;
  final GenieEdge edge;
  final int stripCount;
  final VoidCallback? onComplete;
  final bool ignoreHW;

  const GenieEffect({
    super.key,
    required this.child,
    required this.opening,
    this.duration = AS.slow,
    this.curve = AC.easeOutCubic,
    this.edge = GenieEdge.start,
    this.stripCount = 28,
    this.onComplete,
    this.ignoreHW = false,
  });

  @override
  State<GenieEffect> createState() => _GenieEffectState();
}

class _GenieEffectState extends State<GenieEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;
  final GlobalKey _key = GlobalKey();
  ui.Image? _snapshot;
  bool _capturing = false;
  bool _done = false;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    final dur = HardwareProfiler.getOptimizedSpeed(
      widget.duration,
      ignoreHW: widget.ignoreHW,
    );
    // Fewer strips + fallback on weak hardware
    _useFallback = !widget.ignoreHW && HardwareProfiler.isLowEndDevice();

    _c = AnimationController(vsync: this, duration: dur);
    _t = CurvedAnimation(parent: _c, curve: widget.curve);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (!widget.opening && mounted) {
          setState(() => _done = true);
        }
      }
    });

    if (_useFallback) {
      _c.forward(from: 0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
    }
  }

  Future<void> _capture() async {
    if (_capturing || !mounted) return;
    _capturing = true;
    try {
      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _useFallback = true;
        if (mounted) {
          setState(() {});
          _c.forward(from: 0);
        }
        return;
      }
      final image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.5),
      );
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _snapshot = image);
      _c.forward(from: 0);
    } catch (_) {
      _useFallback = true;
      if (mounted) {
        setState(() {});
        _c.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final edge = widget.edge;
    // Resolve horizontal edge with RTL
    final GenieEdge resolved = switch (edge) {
      GenieEdge.start => isRtl ? GenieEdge.end : GenieEdge.start,
      GenieEdge.end => isRtl ? GenieEdge.start : GenieEdge.end,
      _ => edge,
    };

    if (_useFallback || _snapshot == null) {
      // Keep child visible for capture; during fallback animate transform
      return AnimatedBuilder(
        animation: _t,
        builder: (context, child) {
          final raw = widget.opening ? _t.value : (1.0 - _t.value);
          final p = raw;
          final scaleX = 0.22 + 0.78 * p;
          final scaleY = 0.90 + 0.10 * p;
          final opacity = p.clamp(0.0, 1.0);
          Alignment align;
          double dx = 0, dy = 0;
          switch (resolved) {
            case GenieEdge.start:
              align = Alignment.centerLeft;
              dx = (1 - p) * -48;
              break;
            case GenieEdge.end:
              align = Alignment.centerRight;
              dx = (1 - p) * 48;
              break;
            case GenieEdge.top:
              align = Alignment.topCenter;
              dy = (1 - p) * -36;
              break;
            case GenieEdge.bottom:
              align = Alignment.bottomCenter;
              dy = (1 - p) * 36;
              break;
          }
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                alignment: align,
                child: child,
              ),
            ),
          );
        },
        child: RepaintBoundary(key: _key, child: widget.child),
      );
    }

    final strips = widget.stripCount.clamp(12, 48);
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final progress = widget.opening ? _t.value : (1.0 - _t.value);
        return CustomPaint(
          painter: _GeniePainter(
            image: _snapshot!,
            progress: progress,
            edge: resolved,
            strips: strips,
          ),
          // Size from child snapshot
          size: Size(
            _snapshot!.width / MediaQuery.devicePixelRatioOf(context),
            _snapshot!.height / MediaQuery.devicePixelRatioOf(context),
          ),
          child: Opacity(
            opacity: 0,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _GeniePainter extends CustomPainter {
  final ui.Image image;
  final double progress; // 0 collapsed → 1 full
  final GenieEdge edge;
  final int strips;

  _GeniePainter({
    required this.image,
    required this.progress,
    required this.edge,
    required this.strips,
  });

  // Smoothstep
  double _s(double x) {
    x = x.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = _s(progress);
    if (p <= 0.001) return;

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    final scaleX = size.width / imgW;
    final scaleY = size.height / imgH;

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    final horizontal = edge == GenieEdge.start || edge == GenieEdge.end;
    final n = strips;

    if (horizontal) {
      final stripH = imgH / n;
      for (int i = 0; i < n; i++) {
        final v0 = i / n;
        final v1 = (i + 1) / n;
        // Genie curve: middle lags, edges lead slightly — classic lamp funnel
        final mid = (v0 + v1) * 0.5;
        final funnel = math.sin(mid * math.pi); // 0 at ends, 1 at center
        // Width factor: collapsed narrow, expands with progress
        // Center expands later than edges for organic feel
        final lag = 0.15 * funnel;
        final localP = ((p - lag) / (1.0 - lag)).clamp(0.0, 1.0);
        final widthFactor = 0.06 + 0.94 * _s(localP);

        final srcTop = i * stripH;
        final src = Rect.fromLTWH(0, srcTop, imgW, stripH + 0.5);

        double left;
        double right;
        if (edge == GenieEdge.start) {
          // Anchor left, squeeze toward left
          left = 0;
          right = size.width * widthFactor;
        } else {
          right = size.width;
          left = size.width * (1.0 - widthFactor);
        }

        // Slight vertical pull toward anchor as it collapses
        final yPull = (1.0 - p) * funnel * 6.0;
        final dstTop = (srcTop * scaleY) + (edge == GenieEdge.start || edge == GenieEdge.end ? yPull * 0 : 0);
        final dst = Rect.fromLTRB(left, srcTop * scaleY, right, (srcTop + stripH) * scaleY);

        canvas.drawImageRect(image, src, dst, paint);
      }
    } else {
      final stripW = imgW / n;
      for (int i = 0; i < n; i++) {
        final u0 = i / n;
        final mid = u0 + 0.5 / n;
        final funnel = math.sin(mid * math.pi);
        final lag = 0.15 * funnel;
        final localP = ((p - lag) / (1.0 - lag)).clamp(0.0, 1.0);
        final heightFactor = 0.06 + 0.94 * _s(localP);

        final srcLeft = i * stripW;
        final src = Rect.fromLTWH(srcLeft, 0, stripW + 0.5, imgH);

        double top;
        double bottom;
        if (edge == GenieEdge.top) {
          top = 0;
          bottom = size.height * heightFactor;
        } else {
          bottom = size.height;
          top = size.height * (1.0 - heightFactor);
        }

        final dst = Rect.fromLTRB(
          srcLeft * scaleX,
          top,
          (srcLeft + stripW) * scaleX,
          bottom,
        );
        canvas.drawImageRect(image, src, dst, paint);
      }
    }

    // Soft opacity overall when nearly collapsed
    if (p < 0.2) {
      // already narrow; nothing extra
    }
  }

  @override
  bool shouldRepaint(covariant _GeniePainter old) =>
      old.progress != progress || old.image != image || old.edge != edge;
}

/// Convenience wrappers matching Animator style.
extension AnimatorGenie on Widget {
  Widget enGenieReal(
    BuildContext context, {
    Duration s = AS.slow,
    Curve c = AC.easeOutCubic,
    GenieEdge edge = GenieEdge.start,
    int strips = 32,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return GenieEffect(
      opening: true,
      duration: s,
      curve: c,
      edge: edge,
      stripCount: strips,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }

  Widget exGenieReal(
    BuildContext context, {
    Duration s = AS.balanced,
    Curve c = AC.easeInCubic,
    GenieEdge edge = GenieEdge.start,
    int strips = 32,
    bool ignoreHW = false,
    VoidCallback? onComplete,
  }) {
    return GenieEffect(
      opening: false,
      duration: s,
      curve: c,
      edge: edge,
      stripCount: strips,
      ignoreHW: ignoreHW,
      onComplete: onComplete,
      child: this,
    );
  }
}
