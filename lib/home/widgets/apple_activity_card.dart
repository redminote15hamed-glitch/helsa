// lib/home/widgets/apple_activity_card.dart
// سه سیب متریک: پر شدن از پایین به بالا + موج لبه + آیکون به‌جای برگ
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/home/home_text.dart';

class AppleActivityCard extends StatefulWidget {
  final String language;
  final int steps;
  final int stepsGoal;
  final double calories;
  final double caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;

  const AppleActivityCard({
    super.key,
    required this.language,
    required this.steps,
    required this.stepsGoal,
    required this.calories,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
  });

  @override
  State<AppleActivityCard> createState() => _AppleActivityCardState();
}

class _AppleActivityCardState extends State<AppleActivityCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  double _p(num value, num goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final stepsP = _p(widget.steps, widget.stepsGoal);
    final calP = _p(widget.calories, widget.caloriesGoal);
    final actP = _p(widget.activeMinutes, widget.activeMinutesGoal);

    final items = <_AppleSpec>[
      _AppleSpec(
        color: ColorPalette.mintPrimary,
        icon: Icons.directions_walk_rounded,
        progress: stepsP,
        percentLabel: '${(stepsP * 100).round()}%',
        detailLabel: '${widget.steps} / ${widget.stepsGoal}',
      ),
      _AppleSpec(
        color: ColorPalette.calorieBurn,
        icon: Icons.local_fire_department_rounded,
        progress: calP,
        percentLabel: '${(calP * 100).round()}%',
        detailLabel:
            '${widget.calories.toStringAsFixed(0)} / ${widget.caloriesGoal.toStringAsFixed(0)}',
      ),
      _AppleSpec(
        color: ColorPalette.skyBlue,
        icon: Icons.timer_outlined,
        progress: actP,
        percentLabel: '${(actP * 100).round()}%',
        detailLabel:
            '${widget.activeMinutes} / ${widget.activeMinutesGoal} ${HomeText.getString(widget.language, 'minutes')}',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vX2s),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: context.hS),
            Expanded(
              child: _AppleMetric(
                spec: items[i],
                wave: _wave,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppleSpec {
  final Color color;
  final IconData icon;
  final double progress;
  final String percentLabel;
  final String detailLabel;

  const _AppleSpec({
    required this.color,
    required this.icon,
    required this.progress,
    required this.percentLabel,
    required this.detailLabel,
  });
}

class _AppleMetric extends StatelessWidget {
  final _AppleSpec spec;
  final Animation<double> wave;

  const _AppleMetric({
    required this.spec,
    required this.wave,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.baseScale * 5.2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 1.15,
          child: AnimatedBuilder(
            animation: wave,
            builder: (context, _) {
              return CustomPaint(
                painter: _ApplePainter(
                  color: spec.color,
                  progress: spec.progress,
                  wavePhase: wave.value * math.pi * 2,
                  emptyOpacity: 0.40,
                ),
                child: Align(
                  // جای برگ — صاف بالای سیب
                  alignment: const Alignment(0, -0.92),
                  child: Icon(
                    spec.icon,
                    size: size * 0.22,
                    color: spec.color,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.vX3s),
        Text(
          spec.percentLabel,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: context.m,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: context.vX4s * 0.4),
        Text(
          spec.detailLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: context.s * 0.85,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// اسکلت سیب + پر شدن از پایین با لبه موج‌دار
class _ApplePainter extends CustomPainter {
  final Color color;
  final double progress;
  final double wavePhase;
  final double emptyOpacity;

  _ApplePainter({
    required this.color,
    required this.progress,
    required this.wavePhase,
    required this.emptyOpacity,
  });

  Path _applePath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // اسکلت سیب (شبیه لوگوی داخل دایره، بدون برگ)
    path.moveTo(w * 0.50, h * 0.18);
    // شانه راست
    path.cubicTo(
      w * 0.72, h * 0.18,
      w * 0.92, h * 0.34,
      w * 0.90, h * 0.55,
    );
    path.cubicTo(
      w * 0.88, h * 0.78,
      w * 0.70, h * 0.96,
      w * 0.50, h * 0.96,
    );
    path.cubicTo(
      w * 0.30, h * 0.96,
      w * 0.12, h * 0.78,
      w * 0.10, h * 0.55,
    );
    path.cubicTo(
      w * 0.08, h * 0.34,
      w * 0.28, h * 0.18,
      w * 0.50, h * 0.18,
    );
    path.close();

    // فرورفتگی کوچک بالای سیب (dimple)
    // با stroke جدا کشیده می‌شود

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final apple = _applePath(size);

    // خالی: همان رنگ با ۴۰٪
    final emptyPaint = Paint()
      ..color = color.withValues(alpha: emptyOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(apple, emptyPaint);

    // پر شدن از پایین
    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(apple);

      final fillTop = size.height * (1.0 - progress);
      final waveAmp = size.height * 0.018;
      final wave = Path();
      wave.moveTo(0, size.height);
      wave.lineTo(0, fillTop);
      const steps = 24;
      for (int i = 0; i <= steps; i++) {
        final x = size.width * (i / steps);
        final y = fillTop +
            math.sin(wavePhase + i * 0.55) * waveAmp +
            math.sin(wavePhase * 1.3 + i * 0.9) * waveAmp * 0.45;
        wave.lineTo(x, y);
      }
      wave.lineTo(size.width, size.height);
      wave.close();

      final fillPaint = Paint()
        ..color = color.withValues(alpha: 1.0)
        ..style = PaintingStyle.fill;
      canvas.drawPath(wave, fillPaint);
      canvas.restore();
    }

    // خط اسکلت
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(apple, stroke);

    // فرورفتگی بالای سیب
    final dimple = Path();
    dimple.moveTo(size.width * 0.42, size.height * 0.20);
    dimple.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.28,
      size.width * 0.58,
      size.height * 0.20,
    );
    canvas.drawPath(
      dimple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ApplePainter old) =>
      old.color != color ||
      old.progress != progress ||
      old.wavePhase != wavePhase ||
      old.emptyOpacity != emptyOpacity;
}
