// lib/home/widgets/hex_activity_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/color/color_palette.dart';

/// 3 nested hexagons: steps (outer), calories (mid), active time (inner).
/// Unfilled arc = same color @ 50% opacity; filled = 100%.
/// Icons sit at the top vertex of each ring (like circular health UIs).
class HexActivityCard extends StatelessWidget {
  final String language;
  final int steps;
  final int stepsGoal;
  final double calories;
  final double caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  final String activeTimeText;

  const HexActivityCard({
    super.key,
    required this.language,
    required this.steps,
    required this.stepsGoal,
    required this.calories,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
    required this.activeTimeText,
  });

  bool get _rtl =>
      language.toLowerCase().startsWith('fa') ||
      language.toLowerCase().startsWith('ar');

  String _label(String key) {
    const fa = {
      'steps': 'قدم',
      'calories': 'کالری',
      'active': 'زمان حرکت',
    };
    const en = {
      'steps': 'Steps',
      'calories': 'Calories',
      'active': 'Active',
    };
    const fr = {
      'steps': 'Pas',
      'calories': 'Calories',
      'active': 'Actif',
    };
    final code = language.toLowerCase();
    final map = code.startsWith('fa')
        ? fa
        : code.startsWith('fr')
            ? fr
            : en;
    return map[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepsColor = ColorPalette.mintAccent;
    final calColor = ColorPalette.calorieBurn;
    final activeColor = theme.colorScheme.primary;

    final stepsP = stepsGoal <= 0
        ? 0.0
        : (steps / stepsGoal).clamp(0.0, 1.0);
    final calP = caloriesGoal <= 0
        ? 0.0
        : (calories / caloriesGoal).clamp(0.0, 1.0);
    final actP = activeMinutesGoal <= 0
        ? 0.0
        : (activeMinutes / activeMinutesGoal).clamp(0.0, 1.0);

    final hexSize = context.baseScale * 7.2;

    final legend = Column(
      crossAxisAlignment:
          _rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendRow(
          color: stepsColor,
          icon: Icons.directions_walk_rounded,
          title: _label('steps'),
          value: '$steps / $stepsGoal',
        ),
        SizedBox(height: context.vX2s),
        _LegendRow(
          color: calColor,
          icon: Icons.local_fire_department_rounded,
          title: _label('calories'),
          value:
              '${calories.toStringAsFixed(0)} / ${caloriesGoal.toStringAsFixed(0)} kcal',
        ),
        SizedBox(height: context.vX2s),
        _LegendRow(
          color: activeColor,
          icon: Icons.timer_outlined,
          title: _label('active'),
          value: activeTimeText,
        ),
      ],
    );

    final hex = SizedBox(
      width: hexSize,
      height: hexSize,
      child: CustomPaint(
        painter: _NestedHexPainter(
          stepsProgress: stepsP,
          caloriesProgress: calP,
          activeProgress: actP,
          stepsColor: stepsColor,
          caloriesColor: calColor,
          activeColor: activeColor,
          strokeWidth: context.baseScale * 0.28,
          ringGap: context.baseScale * 0.55, // فاصله بیشتر بین حلقه‌ها
        ),
        child: Stack(
          children: [
            // آیکون بالای هر حلقه (نزدیک رأس بالا)
            _TopIcon(
              color: stepsColor,
              icon: Icons.directions_walk_rounded,
              size: context.m * 0.85,
              topFraction: 0.02,
            ),
            _TopIcon(
              color: calColor,
              icon: Icons.local_fire_department_rounded,
              size: context.m * 0.75,
              topFraction: 0.18,
            ),
            _TopIcon(
              color: activeColor,
              icon: Icons.timer_outlined,
              size: context.m * 0.65,
              topFraction: 0.34,
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(context.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(context.m * 1.2),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(child: legend),
          SizedBox(width: context.hS),
          hex,
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  final double topFraction;

  const _TopIcon({
    required this.color,
    required this.icon,
    required this.size,
    required this.topFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(0, -1 + topFraction * 2),
      child: Icon(icon, size: size, color: color),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String value;

  const _LegendRow({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: context.s * 0.55,
          height: context.s * 0.55,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.hX3s),
        Icon(icon, size: context.m * 0.9, color: color),
        SizedBox(width: context.hX3s),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: context.s * 0.9,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.m * 0.95,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NestedHexPainter extends CustomPainter {
  final double stepsProgress;
  final double caloriesProgress;
  final double activeProgress;
  final Color stepsColor;
  final Color caloriesColor;
  final Color activeColor;
  final double strokeWidth;
  final double ringGap;

  _NestedHexPainter({
    required this.stepsProgress,
    required this.caloriesProgress,
    required this.activeProgress,
    required this.stepsColor,
    required this.caloriesColor,
    required this.activeColor,
    required this.strokeWidth,
    required this.ringGap,
  });

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      // رأس بالا: -90°
      final angle = -math.pi / 2 + i * math.pi / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double progress,
    Color color,
    double stroke,
  ) {
    final path = _hexPath(center, radius);
    final metric = path.computeMetrics().first;

    // پس‌زمینه: همان رنگ با شفافیت ۵۰٪ (نه سفید/خاکستری)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, bgPaint);

    // قسمت پر شده: شفافیت ۱۰۰٪
    if (progress > 0) {
      final extract = metric.extractPath(0, metric.length * progress);
      final fgPaint = Paint()
        ..color = color.withValues(alpha: 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(extract, fgPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 - strokeWidth;

    // سه حلقه با فاصله بیشتر (ringGap)
    final rOuter = maxR;
    final rMid = maxR - ringGap - strokeWidth;
    final rInner = maxR - 2 * (ringGap + strokeWidth);

    _drawRing(canvas, center, rOuter, stepsProgress, stepsColor, strokeWidth);
    _drawRing(
        canvas, center, rMid, caloriesProgress, caloriesColor, strokeWidth);
    _drawRing(
        canvas, center, rInner, activeProgress, activeColor, strokeWidth);
  }

  @override
  bool shouldRepaint(covariant _NestedHexPainter old) =>
      old.stepsProgress != stepsProgress ||
      old.caloriesProgress != caloriesProgress ||
      old.activeProgress != activeProgress ||
      old.stepsColor != stepsColor ||
      old.caloriesColor != caloriesColor ||
      old.activeColor != activeColor ||
      old.strokeWidth != strokeWidth ||
      old.ringGap != ringGap;
}
