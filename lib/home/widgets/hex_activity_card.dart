// lib/home/widgets/hex_activity_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/setting/color/color_palette.dart';

/// سه شش‌ضلعی تو در تو (قدم / کالری / زمان) + راهنمای رنگ سمت دیگر.
class HexActivityCard extends StatelessWidget {
  final int steps;
  final int stepsGoal;
  final int calories;
  final int caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  /// اگر ست شود به‌جای "دقیقه" خام نشان داده می‌شود (مثلاً 12:34)
  final String? activeTimeText;

  /// Optional override; defaults to profile language.
  final String? language;

  const HexActivityCard({
    super.key,
    this.steps = 0,
    this.stepsGoal = 8000,
    this.calories = 0,
    this.caloriesGoal = 300,
    this.activeMinutes = 0,
    this.activeMinutesGoal = 30,
    this.activeTimeText,
    this.language,
  });

  static const Color stepsColor = ColorPalette.steps;
  static const Color caloriesColor = ColorPalette.calorieBurn;
  static const Color timeColor = ColorPalette.activeTime;

  String get _lang {
    final raw = (language ??
            ProfileStore.profile?['language']?.toString() ??
            'en')
        .toLowerCase();
    if (raw.startsWith('fa')) return 'fa';
    if (raw.startsWith('fr')) return 'fr';
    return 'en';
  }

  bool get _rtl => _lang == 'fa';

  String _t(String key) {
    const map = {
      'fa': {
        'steps': 'قدم',
        'calories': 'کالری',
        'time': 'زمان حرکت',
        'kcal': 'kcal',
        'min': 'دقیقه',
      },
      'en': {
        'steps': 'Steps',
        'calories': 'Calories',
        'time': 'Active time',
        'kcal': 'kcal',
        'min': 'min',
      },
      'fr': {
        'steps': 'Pas',
        'calories': 'Calories',
        'time': 'Temps actif',
        'kcal': 'kcal',
        'min': 'min',
      },
    };
    return map[_lang]?[key] ?? map['en']![key]!;
  }

  double _p(int v, int goal) {
    if (goal <= 0) return 0;
    return (v / goal).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hexSize = context.baseScale * 7.2;

    final hex = SizedBox(
      width: hexSize,
      height: hexSize,
      child: CustomPaint(
        painter: _NestedHexPainter(
          stepsProgress: _p(steps, stepsGoal),
          caloriesProgress: _p(calories, caloriesGoal),
          timeProgress: _p(activeMinutes, activeMinutesGoal),
          stepsColor: stepsColor,
          caloriesColor: caloriesColor,
          timeColor: timeColor,
          trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
    );

    final legend = Column(
      crossAxisAlignment:
          _rtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendRow(
          color: stepsColor,
          icon: Icons.directions_walk_rounded,
          label: _t('steps'),
          value: '$steps / $stepsGoal',
        ),
        SizedBox(height: context.vX2s),
        _LegendRow(
          color: caloriesColor,
          icon: Icons.local_fire_department_rounded,
          label: _t('calories'),
          value: '$calories / $caloriesGoal ${_t('kcal')}',
        ),
        SizedBox(height: context.vX2s),
        _LegendRow(
          color: timeColor,
          icon: Icons.timer_rounded,
          label: _t('time'),
          value: '$activeMinutes / $activeMinutesGoal ${_t('min')}',
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(context.hS),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(context.m),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          // شش‌ضلعی‌ها — در LTR چپ، در RTL راست (اولین فرزند جهت)
          hex,
          SizedBox(width: context.hS),
          Expanded(child: legend),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;

  const _LegendRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: context.s * 0.7,
          height: context.s * 0.7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: context.hX3s),
        Iconer(
          icon: icon,
          template: IconTemplate.small,
          customColor: color,
          useGradient: false,
        ),
        SizedBox(width: context.hX3s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFielder(
                text: label,
                template: TextTemplate.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                customStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: context.s * 0.85,
                ),
              ),
              TextFielder(
                text: value,
                template: TextTemplate.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                customStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: context.m * 0.9,
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
  final double timeProgress;
  final Color stepsColor;
  final Color caloriesColor;
  final Color timeColor;
  final Color trackColor;

  _NestedHexPainter({
    required this.stepsProgress,
    required this.caloriesProgress,
    required this.timeProgress,
    required this.stepsColor,
    required this.caloriesColor,
    required this.timeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;

    // outer → steps, mid → calories, inner → time
    _drawHexRing(
      canvas,
      center,
      maxR * 0.90,
      maxR * 0.18,
      trackColor,
      stepsColor,
      stepsProgress,
    );
    _drawHexRing(
      canvas,
      center,
      maxR * 0.64,
      maxR * 0.17,
      trackColor,
      caloriesColor,
      caloriesProgress,
    );
    _drawHexRing(
      canvas,
      center,
      maxR * 0.38,
      maxR * 0.16,
      trackColor,
      timeColor,
      timeProgress,
    );
  }

  void _drawHexRing(
    Canvas canvas,
    Offset center,
    double radius,
    double stroke,
    Color track,
    Color progressColor,
    double progress,
  ) {
    // مسیر باز از رأس بالا، ساعت‌گرد — پیشرفت از بالا شروع می‌شود
    final path = _hexPathFromTop(center, radius);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // ترک کامل (بسته)
    final closed = Path.from(path)..close();
    canvas.drawPath(closed, trackPaint);

    if (progress <= 0) return;

    final metric = path.computeMetrics().first;
    final extract = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extract, progressPaint);
  }

  /// رأس بالا (angle = -pi/2) → ساعت‌گرد، بدون close برای metric تمیز
  Path _hexPathFromTop(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i <= 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _NestedHexPainter old) {
    return old.stepsProgress != stepsProgress ||
        old.caloriesProgress != caloriesProgress ||
        old.timeProgress != timeProgress ||
        old.stepsColor != stepsColor ||
        old.caloriesColor != caloriesColor ||
        old.timeColor != timeColor ||
        old.trackColor != trackColor;
  }
}
