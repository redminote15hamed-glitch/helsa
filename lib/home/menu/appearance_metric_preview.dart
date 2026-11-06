import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

/// Apple metric previews + heart color dock for Appearance.
class AppearancePreviewApple extends StatelessWidget {
  const AppearancePreviewApple({super.key, 
    required this.label,
    required this.color,
    required this.fill,
    required this.size,
    required this.wave,
  });

  final String label;
  final Color color;
  final double fill;
  final double size;
  final double wave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.s,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: context.vX3s),
        CustomPaint(
          size: Size(size, size * 1.12),
          painter: AppearanceApplePainter(
            color: color,
            fill: fill,
            wavePhase: wave * math.pi * 2,
          ),
        ),
        SizedBox(height: context.vX3s),
        Text(
          '${(fill * 100).round()}%',
          style: TextStyle(
            fontSize: context.xs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class AppearanceApplePainter extends CustomPainter {
  AppearanceApplePainter({
    required this.color,
    required this.fill,
    required this.wavePhase,
  });

  final Color color;
  final double fill;
  final double wavePhase;

  Path _bodyPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.50), y(0.22));
    path.cubicTo(x(0.62), y(0.12), x(0.92), y(0.18), x(0.94), y(0.42));
    path.cubicTo(x(0.96), y(0.62), x(0.82), y(0.86), x(0.62), y(0.94));
    path.cubicTo(x(0.55), y(0.98), x(0.45), y(0.98), x(0.38), y(0.94));
    path.cubicTo(x(0.18), y(0.86), x(0.04), y(0.62), x(0.06), y(0.42));
    path.cubicTo(x(0.08), y(0.18), x(0.38), y(0.12), x(0.50), y(0.22));
    path.close();
    return path;
  }

  Path _stemPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.48), y(0.22));
    path.quadraticBezierTo(x(0.46), y(0.12), x(0.50), y(0.04));
    path.quadraticBezierTo(x(0.54), y(0.12), x(0.52), y(0.22));
    path.close();
    return path;
  }

  Path _leafPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.52), y(0.12));
    path.cubicTo(x(0.62), y(0.02), x(0.78), y(0.06), x(0.80), y(0.16));
    path.cubicTo(x(0.78), y(0.24), x(0.62), y(0.22), x(0.52), y(0.14));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final body = _bodyPath(size);
    final stem = _stemPath(size);
    final leaf = _leafPath(size);
    final b = body.getBounds();
    final strokeW = (size.width * 0.048).clamp(1.8, 2.8);

    final glass = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.28),
        color.withValues(alpha: 0.18),
      ],
    ).createShader(b);
    canvas.drawPath(
      body,
      Paint()
        ..shader = glass
        ..style = PaintingStyle.fill,
    );

    if (fill > 0.001) {
      canvas.save();
      canvas.clipPath(body);
      final fillH = b.height * fill.clamp(0.0, 1.0);
      final top = b.bottom - fillH;
      final amp = size.height * 0.018;
      final wave = Path();
      wave.moveTo(b.left, b.bottom);
      wave.lineTo(b.left, top);
      for (var i = 0; i <= 12; i++) {
        final t = i / 12.0;
        final px = b.left + b.width * t;
        final py = top + math.sin(wavePhase + t * math.pi * 2) * amp;
        wave.lineTo(px, py);
      }
      wave.lineTo(b.right, b.bottom);
      wave.close();
      canvas.drawPath(
        wave,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.85),
              color,
            ],
          ).createShader(b),
      );
      canvas.restore();
    }

    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawPath(stem, Paint()..color = color.withValues(alpha: 0.92));
    canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: 0.82));
  }

  @override
  bool shouldRepaint(covariant AppearanceApplePainter old) =>
      old.color != color || old.fill != fill || old.wavePhase != wavePhase;
}

class AppearanceHeartDock extends StatelessWidget {
  const AppearanceHeartDock({super.key, required this.colors, required this.width});

  final List<Color> colors;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.55),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.12),
              blurRadius: 8,
              spreadRadius: 0.2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in colors)
              Icon(Icons.favorite_rounded, color: c, size: 20),
          ],
        ),
      ),
    );
  }
}

