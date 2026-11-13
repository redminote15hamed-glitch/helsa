// lib/home/menu/menu_expand_host.dart
// Two-phase: origin (menu row) → 50%×50% card → fullscreen. ~1.3s total.
// Close reverses the path. Drawer stays open.
import 'dart:async';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

class MenuExpandHost {
  MenuExpandHost._();

  static Future<T?> open<T>({
    required BuildContext context,
    required Rect origin,
    required WidgetBuilder builder,
    ThemeData? theme,
    Duration duration = const Duration(milliseconds: 1300),
  }) {
    final completer = Completer<T?>();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        final th = theme ?? Theme.of(context);
        return Theme(
          data: th,
          child: _ExpandLayer<T>(
            origin: origin,
            duration: duration,
            builder: builder,
            onFinished: (value) {
              entry.remove();
              if (!completer.isCompleted) completer.complete(value);
            },
          ),
        );
      },
    );
    overlay.insert(entry);
    return completer.future;
  }

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

class _ExpandLayer<T> extends StatefulWidget {
  final Rect origin;
  final Duration duration;
  final WidgetBuilder builder;
  final void Function(T? value) onFinished;

  const _ExpandLayer({
    required this.origin,
    required this.duration,
    required this.builder,
    required this.onFinished,
  });

  @override
  State<_ExpandLayer<T>> createState() => _ExpandLayerState<T>();
}

class _ExpandLayerState<T> extends State<_ExpandLayer<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _closing = false;
  // Phase split: 0..0.40 grow to half, 0.40..1.0 to full. No long pause.
  static const double _phase1End = 0.40;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.dismissed && _closing) {
        widget.onFinished(null);
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (_closing) return;
    _closing = true;
    await _c.reverse();
  }

  Rect _halfRect(Size screen) {
    final w = screen.width * 0.50;
    final h = screen.height * 0.50;
    // Sit just to the end-side of the menu, vertically near origin.
    final originCenterY = widget.origin.center.dy;
    var top = originCenterY - h / 2;
    top = top.clamp(24.0, screen.height - h - 24.0);
    // In LTR menu is left → card to the right of origin.
    // In RTL menu is right → card to the left of origin.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    double left;
    if (isRtl) {
      left = (widget.origin.left - w - 8).clamp(16.0, screen.width - w - 16);
    } else {
      left = (widget.origin.right + 8).clamp(16.0, screen.width - w - 16);
    }
    // Prefer centered horizontally if origin is far; still keep near item.
    final preferCenterLeft = (screen.width - w) / 2;
    // Blend slightly toward center so it doesn't stick only to edge on wide screens.
    left = left * 0.55 + preferCenterLeft * 0.45;
    left = left.clamp(16.0, screen.width - w - 16);
    return Rect.fromLTWH(left, top, w, h);
  }

  Rect _fullRect(Size screen) => Offset.zero & screen;

  Rect _lerpRect(Rect a, Rect b, double t) {
    final tt = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    return Rect.lerp(a, b, tt)!;
  }

  Rect _rectFor(double t, Size screen) {
    final half = _halfRect(screen);
    final full = _fullRect(screen);
    final origin = widget.origin;
    if (t <= _phase1End) {
      final p = (t / _phase1End).clamp(0.0, 1.0);
      return _lerpRect(origin, half, p);
    }
    final p = ((t - _phase1End) / (1.0 - _phase1End)).clamp(0.0, 1.0);
    return _lerpRect(half, full, p);
  }

  double _radiusFor(double t) {
    // Round when small, nearly square when full.
    if (t <= _phase1End) {
      final p = t / _phase1End;
      return uiLerp(18, 20, p);
    }
    final p = (t - _phase1End) / (1 - _phase1End);
    return uiLerp(20, 0, p);
  }

  double uiLerp(double a, double b, double t) => a + (b - a) * t;

  double _barrierOpacity(double t) {
    // Soft dim over content (not over menu necessarily — full-screen scrim).
    return Curves.easeOut.transform(t.clamp(0.0, 1.0)) * 0.45;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final rect = _rectFor(t, screen);
        final radius = _radiusFor(t);
        final scrim = _barrierOpacity(t);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Dim only the area outside the expanding card gradually.
            Positioned.fill(
              child: GestureDetector(
                onTap: _requestClose,
                behavior: HitTestBehavior.opaque,
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
                  // Child thinks it's a normal page; we clip/size externally.
                  data: MediaQuery.of(context).copyWith(
                    size: Size(rect.width, rect.height),
                  ),
                  child: _ExpandScope(
                    requestClose: _requestClose,
                    child: widget.builder(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Descendants call [MenuExpandScope.close] to reverse-animate out.
class _ExpandScope extends InheritedWidget {
  final Future<void> Function() requestClose;

  const _ExpandScope({
    required this.requestClose,
    required super.child,
  });

  static _ExpandScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ExpandScope>();

  @override
  bool updateShouldNotify(covariant _ExpandScope old) =>
      requestClose != old.requestClose;
}

class MenuExpandScope {
  static Future<void> close(BuildContext context) async {
    final scope = _ExpandScope.maybeOf(context);
    if (scope != null) {
      await scope.requestClose();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
