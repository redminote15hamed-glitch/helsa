// lib/home/widgets/walk_aura.dart
// حلقه‌های نورانی دور سیب قدم — با هر قدم منبسط و محو می‌شوند
import 'package:flutter/material.dart';

class WalkAura extends StatefulWidget {
  final int steps;
  final bool isWalking;
  final Color color;
  final Widget child;

  const WalkAura({
    super.key,
    required this.steps,
    required this.isWalking,
    required this.color,
    required this.child,
  });

  @override
  State<WalkAura> createState() => _WalkAuraState();
}

class _WalkAuraState extends State<WalkAura> with TickerProviderStateMixin {
  late final AnimationController _c1;
  late final AnimationController _c2;
  int _lastSteps = 0;

  @override
  void initState() {
    super.initState();
    _lastSteps = widget.steps;
    _c1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _c2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  }

  @override
  void didUpdateWidget(covariant WalkAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps > _lastSteps && widget.isWalking) {
      _lastSteps = widget.steps;
      _burst();
    } else {
      _lastSteps = widget.steps;
    }
  }

  void _burst() {
    _c1.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _c2.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c1, _c2]),
      builder: (context, _) {
        return CustomPaint(
          painter: _AuraPainter(
            progress1: _c1.value,
            progress2: _c2.value,
            color: widget.color,
            active: widget.isWalking,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _AuraPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final Color color;
  final bool active;

  _AuraPainter({
    required this.progress1,
    required this.progress2,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide * 0.42;

    void ring(double p) {
      if (p <= 0 || p >= 1) return;
      final r = base * (1.0 + p * 0.85);
      final opacity = (1.0 - p) * 0.45;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1.0 - p * 0.5)
        ..color = color.withValues(alpha: opacity);
      canvas.drawCircle(c, r, paint);
    }

    ring(progress1);
    ring(progress2);

    // هالهٔ خیلی ملایم وقتی در حال پیاده‌روی است
    if (active) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: 0.12);
      canvas.drawCircle(c, base * 1.08, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.progress1 != progress1 ||
      old.progress2 != progress2 ||
      old.color != color ||
      old.active != active;
}
