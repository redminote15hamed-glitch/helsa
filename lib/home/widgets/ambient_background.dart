// lib/home/widgets/ambient_background.dart
// ته‌رنگ ثابت + حرکت خیلی آرام (بدون شلوغی)
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/color/color_palette.dart';

/// Canvas زنده برای Home — گرادیان آرام با همان ته‌سبز خنثی
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
    // خیلی کند: یک چرخه حدود ۱۸ ثانیه — حس نفس کشیدن، نه انیمیشن تند
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // پایه ثابت (همان پیشنهاد ارشد)
    final base = isDark ? const Color(0xFF0C1210) : const Color(0xFFF4F7F5);
    // دو لکه خیلی ملایم از برند — opacity پایین تا اذیت نکند
    final blobA = isDark
        ? ColorPalette.mintPrimary.withValues(alpha: 0.07)
        : ColorPalette.mintPrimary.withValues(alpha: 0.06);
    final blobB = isDark
        ? ColorPalette.skyBlue.withValues(alpha: 0.05)
        : ColorPalette.mintAccent.withValues(alpha: 0.05);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0 → 1 → 0
        final dx = math.sin(t * math.pi) * 0.08;
        final dy = math.cos(t * math.pi * 0.85) * 0.06;

        return Stack(
          fit: StackFit.expand,
          children: [
            // لایه ثابت
            ColoredBox(color: base),
            // لکه نرم ۱ — جابه‌جایی خیلی کم
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.55 + dx, -0.65 + dy),
                  radius: 1.05,
                  colors: [blobA, base.withValues(alpha: 0)],
                ),
              ),
            ),
            // لکه نرم ۲ — خلاف جهت
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.60 - dx, 0.55 - dy),
                  radius: 0.95,
                  colors: [blobB, base.withValues(alpha: 0)],
                ),
              ),
            ),
            // محتوای صفحه
            widget.child,
          ],
        );
      },
    );
  }
}
