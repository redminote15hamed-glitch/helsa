// lib/home/widgets/metric_icon_pulse.dart
// انیمیشن طبیعی و هماهنگ با هر آیکون — با هر تغییر مقدار
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MetricIconStyle { steps, calories, active }

class MetricIconPulse extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Object value;
  final MetricIconStyle style;

  const MetricIconPulse({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.value,
    required this.style,
  });

  @override
  State<MetricIconPulse> createState() => _MetricIconPulseState();
}

class _MetricIconPulseState extends State<MetricIconPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    _c.duration = _durationFor(widget.style);
  }

  Duration _durationFor(MetricIconStyle s) {
    switch (s) {
      case MetricIconStyle.steps:
        return const Duration(milliseconds: 720); // دو قدم
      case MetricIconStyle.calories:
        return const Duration(milliseconds: 900); // شعله
      case MetricIconStyle.active:
        return const Duration(milliseconds: 1000); // یک دور عقربه
    }
  }

  @override
  void didUpdateWidget(covariant MetricIconPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.style != widget.style) {
      _c.duration = _durationFor(widget.style);
    }
    if (oldWidget.value != widget.value) {
      // هر تغییر عدد → یک سیکل کامل طبیعی
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        switch (widget.style) {
          case MetricIconStyle.steps:
            return _buildWalk(t);
          case MetricIconStyle.calories:
            return _buildFire(t);
          case MetricIconStyle.active:
            return _buildClock(t);
        }
      },
    );
  }

  /// راه رفتن واقعی: دو گام، بالا-پایین پا، کج شدن بدن
  Widget _buildWalk(double t) {
    // دو سیکل سینوسی در یک انیمیشن = دو قدم
    final step = math.sin(t * math.pi * 2);
    final bounce = math.sin(t * math.pi * 2).abs(); // هر قدم یک جهش
    final lean = step * 0.18; // رادیان
    final x = step * (widget.size * 0.12);
    final y = -bounce * (widget.size * 0.10);

    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.rotate(
        angle: lean,
        child: Icon(
          widget.icon,
          size: widget.size,
          color: widget.color,
        ),
      ),
    );
  }

  /// آتش: زبانه کشیدن به بالا + لرزش نرم + تغییر روشنایی
  Widget _buildFire(double t) {
    final flicker1 = math.sin(t * math.pi * 3);
    final flicker2 = math.sin(t * math.pi * 5 + 0.4);
    final rise = math.sin(t * math.pi).abs(); // یک بار زبانه بالا
    final scaleY = 1.0 + rise * 0.22 + flicker1 * 0.04;
    final scaleX = 1.0 - rise * 0.06 + flicker2 * 0.03;
    final shake = flicker2 * 1.1;
    final glow = rise;

    return Transform.translate(
      offset: Offset(shake, -rise * (widget.size * 0.08)),
      child: Transform(
        alignment: Alignment.bottomCenter, // از پایه شعله رشد کند
        transform: Matrix4.diagonal3Values(scaleX, scaleY, 1),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: Color.lerp(
            widget.color,
            const Color(0xFFFFE082),
            glow * 0.5,
          ),
          shadows: [
            Shadow(
              color: widget.color.withValues(alpha: 0.3 + glow * 0.45),
              blurRadius: 4 + glow * 10,
              offset: Offset(0, -glow * 2),
            ),
          ],
        ),
      ),
    );
  }

  /// ساعت: چرخش یک دور کامل نرم (عقربه)
  Widget _buildClock(double t) {
    // ease: سریع شروع، نرم توقف در ۱۲
    final angled = Curves.easeInOutCubic.transform(t) * math.pi * 2;
    final tick = math.sin(t * math.pi * 8) * 0.03 * (1 - t); // تیک‌های ریز اول

    return Transform.rotate(
      angle: angled + tick,
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
