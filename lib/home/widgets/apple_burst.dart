// lib/home/widgets/apple_burst.dart
// انفجار / تشکیل دوباره + نشان +هدف — جدا از سیب
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// چند دور هدف کامل شده و باقی‌مانده برای پر شدن UI
({int cycles, double fill}) appleOverflow(num value, num goal) {
  if (goal <= 0) return (cycles: 0, fill: 0);
  final v = value.toDouble();
  final g = goal.toDouble();
  if (v < g) return (cycles: 0, fill: (v / g).clamp(0.0, 1.0));
  final cycles = (v / g).floor();
  final rem = v - cycles * g;
  return (cycles: cycles, fill: (rem / g).clamp(0.0, 1.0));
}

/// کنترلر انفجار مشترک برای کارت سیب‌ها
class AppleBurstController extends ChangeNotifier {
  final AnimationController controller;
  final Set<String> _played = {};

  AppleBurstController(TickerProvider vsync)
      : controller = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 1400),
        );

  Animation<double> get animation => controller;

  bool hasPlayed(String id) => _played.contains(id);

  void markPlayed(String id) => _played.add(id);

  /// اگر متریک‌هایی با cycles>0 و هنوز پخش‌نشده باشند → انفجار
  void maybePlay(List<String> idsNeedingBurst) {
    final fresh = idsNeedingBurst.where((id) => !_played.contains(id)).toList();
    if (fresh.isEmpty) return;
    _played.addAll(fresh);
    controller.forward(from: 0);
    notifyListeners();
  }

  void disposeController() {
    controller.dispose();
  }
}

/// نشان +100 کنار سیب
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

/// ذرات انفجار
class AppleBurstParticlesPainter extends CustomPainter {
  final Color color;
  final double t; // 0..1

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

/// از مقدار انیمیشن: opacity / scale / particleT
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
