// lib/home/widgets/apple_burst.dart
// هر بار که یک دور هدف کامل شود → انفجار + تشکیل دوباره
import 'dart:math' as math;
import 'package:flutter/material.dart';

({int cycles, double fill}) appleOverflow(num value, num goal) {
  if (goal <= 0) return (cycles: 0, fill: 0);
  final v = value.toDouble();
  final g = goal.toDouble();
  if (v < g) return (cycles: 0, fill: (v / g).clamp(0.0, 1.0));
  final cycles = (v / g).floor();
  final rem = v - cycles * g;
  return (cycles: cycles, fill: (rem / g).clamp(0.0, 1.0));
}

class AppleBurstController extends ChangeNotifier {
  final AnimationController controller;

  /// آخرین cycles دیده‌شده برای هر متریک
  final Map<String, int> _lastCycles = {};

  /// الان کدام‌ها در حال انفجارند
  final Set<String> _bursting = {};

  AppleBurstController(TickerProvider vsync)
      : controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 1400),
        ) {
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _bursting.clear();
        notifyListeners();
      }
    });
  }

  Animation<double> get animation => controller;

  bool isBursting(String id) => _bursting.contains(id);

  /// هر بار cycles نسبت به قبل بیشتر شد → دوباره انفجار
  void checkCycles(Map<String, int> cyclesById) {
    final toPlay = <String>[];
    for (final e in cyclesById.entries) {
      final prev = _lastCycles[e.key];
      if (prev == null) {
        // اولین بار در این session
        _lastCycles[e.key] = e.value;
        if (e.value > 0) toPlay.add(e.key);
      } else if (e.value > prev) {
        // دور جدید کامل شد (مثلاً ۱→۲ یا ۰→۱)
        _lastCycles[e.key] = e.value;
        toPlay.add(e.key);
      }
    }
    if (toPlay.isEmpty) return;
    if (controller.isAnimating) {
      // اگر وسط انفجار قبلی است، باز از اول
      controller.stop();
    }
    _bursting
      ..clear()
      ..addAll(toPlay);
    controller.forward(from: 0);
    notifyListeners();
  }

  void disposeController() {
    controller.dispose();
  }
}

class AppleBonusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AppleBonusChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class AppleBurstParticlesPainter extends CustomPainter {
  final Color color;
  final double t;

  AppleBurstParticlesPainter({required this.color, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final cx = size.width / 2;
    final cy = size.height / 2;
    const n = 14;
    for (int i = 0; i < n; i++) {
      final ang = (i / n) * math.pi * 2 + rnd.nextDouble() * 0.4;
      final dist = t * (size.width * 0.55) * (0.6 + rnd.nextDouble() * 0.5);
      final px = cx + math.cos(ang) * dist;
      final py = cy + math.sin(ang) * dist;
      final r = (1.0 - t) * (3.0 + rnd.nextDouble() * 3);
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = color.withValues(alpha: (1 - t) * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant AppleBurstParticlesPainter old) => old.t != t;
}

({double opacity, double scale, double particleT}) appleBurstTransform(
  double b, {
  required bool play,
}) {
  if (!play || b >= 1) {
    return (opacity: 1, scale: 1, particleT: 0);
  }
  if (b < 0.45) {
    final t = b / 0.45;
    return (opacity: 1 - t, scale: 1 + t * 0.55, particleT: t);
  }
  final t = (b - 0.45) / 0.55;
  return (opacity: t, scale: 0.6 + t * 0.4, particleT: 0);
}
