// lib/home/widgets/apple_activity_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/services/step_tracker.dart';

enum _GoalKind { steps, calories, active }

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

  Future<void> _editGoal(_GoalKind kind, int currentGoal) async {
    final controller = TextEditingController(text: '$currentGoal');
    final titleKey = switch (kind) {
      _GoalKind.steps => 'goal_steps',
      _GoalKind.calories => 'goal_calories',
      _GoalKind.active => 'goal_active',
    };

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(HomeText.getString(widget.language, titleKey)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            decoration: InputDecoration(
              hintText: HomeText.getString(widget.language, 'goal_hint'),
            ),
            onSubmitted: (v) {
              final n = int.tryParse(v.trim());
              if (n != null && n > 0) Navigator.of(ctx).pop(n);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(HomeText.getString(widget.language, 'cancel')),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(controller.text.trim());
                if (n != null && n > 0) Navigator.of(ctx).pop(n);
              },
              child: Text(HomeText.getString(widget.language, 'confirm')),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (result == null) return;

    final tracker = StepTracker.instance;
    switch (kind) {
      case _GoalKind.steps:
        await tracker.setStepsGoal(result);
      case _GoalKind.calories:
        await tracker.setCaloriesGoal(result);
      case _GoalKind.active:
        await tracker.setActiveGoal(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepsP = _p(widget.steps, widget.stepsGoal);
    final calP = _p(widget.calories, widget.caloriesGoal);
    final actP = _p(widget.activeMinutes, widget.activeMinutesGoal);

    final items = <_AppleSpec>[
      _AppleSpec(
        kind: _GoalKind.steps,
        color: ColorPalette.mintPrimary,
        icon: Icons.directions_walk_rounded,
        progress: stepsP,
        percentLabel: '${(stepsP * 100).round()}%',
        detailLabel: '${widget.steps} / ${widget.stepsGoal}',
        goalValue: widget.stepsGoal,
      ),
      _AppleSpec(
        kind: _GoalKind.calories,
        color: ColorPalette.calorieBurn,
        icon: Icons.local_fire_department_rounded,
        progress: calP,
        percentLabel: '${(calP * 100).round()}%',
        detailLabel:
            '${widget.calories.toStringAsFixed(0)} / ${widget.caloriesGoal.toStringAsFixed(0)}',
        goalValue: widget.caloriesGoal.round(),
      ),
      _AppleSpec(
        kind: _GoalKind.active,
        color: ColorPalette.skyBlue,
        icon: Icons.timer_outlined,
        progress: actP,
        percentLabel: '${(actP * 100).round()}%',
        detailLabel:
            '${widget.activeMinutes} / ${widget.activeMinutesGoal} ${HomeText.getString(widget.language, 'minutes')}',
        goalValue: widget.activeMinutesGoal,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vX2s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: context.hS),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _editGoal(items[i].kind, items[i].goalValue),
                child: _AppleMetric(spec: items[i], wave: _wave),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppleSpec {
  final _GoalKind kind;
  final Color color;
  final IconData icon;
  final double progress;
  final String percentLabel;
  final String detailLabel;
  final int goalValue;

  const _AppleSpec({
    required this.kind,
    required this.color,
    required this.icon,
    required this.progress,
    required this.percentLabel,
    required this.detailLabel,
    required this.goalValue,
  });
}

class _AppleMetric extends StatelessWidget {
  final _AppleSpec spec;
  final Animation<double> wave;

  const _AppleMetric({required this.spec, required this.wave});

  @override
  Widget build(BuildContext context) {
    final size = context.baseScale * 5.6;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size * 1.22,
          child: AnimatedBuilder(
            animation: wave,
            builder: (context, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ApplePainter(
                        color: spec.color,
                        progress: spec.progress,
                        wavePhase: wave.value * math.pi * 2,
                        emptyOpacity: 0.40,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Icon(
                      spec.icon,
                      size: size * 0.34,
                      color: spec.color,
                    ),
                  ),
                ],
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
        SizedBox(height: context.vX4s * 0.35),
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
    final top = h * 0.16;
    final bottom = h * 0.96;
    final midY = h * 0.52;
    final cx = w * 0.50;

    final path = Path();
    path.moveTo(cx, top + h * 0.06);
    path.cubicTo(
      w * 0.78, top + h * 0.02,
      w * 0.98, midY * 0.55,
      w * 0.94, midY,
    );
    path.cubicTo(
      w * 0.90, h * 0.78,
      w * 0.72, bottom,
      cx, bottom,
    );
    path.cubicTo(
      w * 0.28, bottom,
      w * 0.10, h * 0.78,
      w * 0.06, midY,
    );
    path.cubicTo(
      w * 0.02, midY * 0.55,
      w * 0.22, top + h * 0.02,
      cx, top + h * 0.06,
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final apple = _applePath(size);

    canvas.drawPath(
      apple,
      Paint()
        ..color = color.withValues(alpha: emptyOpacity)
        ..style = PaintingStyle.fill,
    );

    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(apple);
      final bounds = apple.getBounds();
      final fillTop = bounds.bottom - bounds.height * progress;
      final amp = size.height * 0.016;
      final wave = Path()
        ..moveTo(bounds.left, bounds.bottom)
        ..lineTo(bounds.left, fillTop);
      const n = 28;
      for (int i = 0; i <= n; i++) {
        final x = bounds.left + bounds.width * (i / n);
        final y = fillTop +
            math.sin(wavePhase + i * 0.5) * amp +
            math.sin(wavePhase * 1.4 + i * 0.85) * amp * 0.4;
        wave.lineTo(x, y);
      }
      wave
        ..lineTo(bounds.right, bounds.bottom)
        ..close();
      canvas.drawPath(
        wave,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    canvas.drawPath(
      apple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055
        ..strokeJoin = StrokeJoin.round,
    );

    final dimple = Path()
      ..moveTo(size.width * 0.38, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.32,
        size.width * 0.62,
        size.height * 0.22,
      );
    canvas.drawPath(
      dimple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04
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
