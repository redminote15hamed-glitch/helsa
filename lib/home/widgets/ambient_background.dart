// lib/home/widgets/ambient_background.dart
// آسمان وضعیت: صبح / ظهر / عصر / شب + حرکت خیلی آرام
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/color/color_palette.dart';

enum _SkyPhase { morning, noon, evening, night }

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  _SkyPhase get _phase {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return _SkyPhase.morning;
    if (h >= 11 && h < 16) return _SkyPhase.noon;
    if (h >= 16 && h < 20) return _SkyPhase.evening;
    return _SkyPhase.night;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final phase = _phase;

    // پایه + ته‌رنگ آسمان بر اساس ساعت
    late Color base;
    late Color blobA;
    late Color blobB;
    late Color blobC;

    if (isDark || phase == _SkyPhase.night) {
      base = const Color(0xFF0A0E14);
      blobA = const Color(0xFF1A2740).withValues(alpha: 0.55);
      blobB = ColorPalette.skyBlue.withValues(alpha: 0.08);
      blobC = const Color(0xFF2A1F4A).withValues(alpha: 0.12);
    } else {
      switch (phase) {
        case _SkyPhase.morning:
          base = const Color(0xFFF7F3EC);
          blobA = const Color(0xFFFFE0B2).withValues(alpha: 0.35);
          blobB = ColorPalette.mintPrimary.withValues(alpha: 0.08);
          blobC = const Color(0xFFFFCC80).withValues(alpha: 0.12);
          break;
        case _SkyPhase.noon:
          base = const Color(0xFFF3F8F6);
          blobA = ColorPalette.mintPrimary.withValues(alpha: 0.10);
          blobB = ColorPalette.skyBlue.withValues(alpha: 0.10);
          blobC = ColorPalette.mintAccent.withValues(alpha: 0.07);
          break;
        case _SkyPhase.evening:
          base = const Color(0xFFF8F0EB);
          blobA = const Color(0xFFFFAB91).withValues(alpha: 0.22);
          blobB = const Color(0xFFCE93D8).withValues(alpha: 0.10);
          blobC = ColorPalette.mintPrimary.withValues(alpha: 0.06);
          break;
        case _SkyPhase.night:
          base = const Color(0xFF0A0E14);
          blobA = const Color(0xFF1A2740).withValues(alpha: 0.55);
          blobB = ColorPalette.skyBlue.withValues(alpha: 0.08);
          blobC = const Color(0xFF2A1F4A).withValues(alpha: 0.12);
          break;
      }
    }

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final dx = math.sin(t * math.pi) * 0.10;
        final dy = math.cos(t * math.pi * 0.8) * 0.07;

        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            // آسمان بالا
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    blobA,
                    base.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
            // لکه نرم شناور
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.5 + dx, -0.55 + dy),
                  radius: 1.1,
                  colors: [blobB, base.withValues(alpha: 0)],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.55 - dx, 0.5 - dy),
                  radius: 1.0,
                  colors: [blobC, base.withValues(alpha: 0)],
                ),
              ),
            ),
            // ستارهٔ خیلی کم‌نور فقط شب
            if (phase == _SkyPhase.night || isDark)
              CustomPaint(painter: _StarDustPainter(t: t)),
            widget.child,
          ],
        );
      },
    );
  }
}

class _StarDustPainter extends CustomPainter {
  final double t;
  _StarDustPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.55;
      final twinkle = 0.15 + 0.25 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + i));
      paint.color = Colors.white.withValues(alpha: twinkle);
      canvas.drawCircle(Offset(x, y), 1.1 + rnd.nextDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarDustPainter old) => old.t != t;
}
