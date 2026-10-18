// lib/home/widgets/metric_icon_pulse.dart
// انیمیشن مخصوص هر متریک وقتی مقدار عوض می‌شود
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
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void didUpdateWidget(covariant MetricIconPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
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
      builder: (context, child) {
        final t = _c.value; // 0..1 یک‌بار
        switch (widget.style) {
          case MetricIconStyle.steps:
            // راه رفتن: جابه‌جایی افقی + کمی کج شدن
            final walk = math.sin(t * math.pi * 2) * 3.5;
            final lean = math.sin(t * math.pi * 2) * 0.12;
            return Transform.translate(
              offset: Offset(walk, -math.sin(t * math.pi).abs() * 2),
              child: Transform.rotate(
                angle: lean,
                child: child,
              ),
            );
          case MetricIconStyle.calories:
            // سوختن: لرزش + scale ضربان + کمی چرخش
            final flicker = 1.0 + math.sin(t * math.pi * 4) * 0.12;
            final shake = math.sin(t * math.pi * 6) * 1.2;
            final glow = (math.sin(t * math.pi * 3).abs());
            return Transform.translate(
              offset: Offset(shake, -glow * 2),
              child: Transform.scale(
                scale: flicker,
                child: Icon(
                  widget.icon,
                  size: widget.size,
                  color: Color.lerp(
                    widget.color,
                    const Color(0xFFFFD54F),
                    glow * 0.45,
                  ),
                  shadows: [
                    Shadow(
                      color: widget.color.withValues(alpha: 0.35 + glow * 0.4),
                      blurRadius: 6 + glow * 8,
                    ),
                  ],
                ),
              ),
            );
          case MetricIconStyle.active:
            // ساعت: چرخش یک دور نرم
            final angle = t * math.pi * 2;
            return Transform.rotate(
              angle: angle,
              child: child,
            );
        }
      },
      child: Icon(
        widget.icon,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
