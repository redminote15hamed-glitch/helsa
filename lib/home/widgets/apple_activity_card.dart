// lib/home/widgets/apple_activity_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/widgets/apple_burst.dart';
import 'package:helsa/home/widgets/metric_icon_pulse.dart';

enum _GoalKind { steps, calories, active }

class AppleActivityCard extends StatefulWidget {
  final String language;
  final int steps;
  final int stepsGoal;
  final double calories;
  final double caloriesGoal;
  final int activeMinutes;
  final int activeMinutesGoal;
  final bool isWalking;
  final bool isNight;

  const AppleActivityCard({
    super.key,
    required this.language,
    required this.steps,
    required this.stepsGoal,
    required this.calories,
    required this.caloriesGoal,
    required this.activeMinutes,
    required this.activeMinutesGoal,
    this.isWalking = false,
    this.isNight = false,
  });

  @override
  State<AppleActivityCard> createState() => _AppleActivityCardState();
}

class _AppleActivityCardState extends State<AppleActivityCard>
    with TickerProviderStateMixin {
  late final AnimationController _wave;
  late final AppleBurstController _burst;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _syncWaveSpeed();
    _burst = AppleBurstController(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerBurst());
  }

  @override
  void didUpdateWidget(covariant AppleActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isWalking != widget.isWalking) {
      _syncWaveSpeed();
    }
    _triggerBurst();
  }

  @override
  void dispose() {
    _wave.dispose();
    _burst.disposeController();
    super.dispose();
  }

  void _triggerBurst() {
    final ids = <String>[];
    if (appleOverflow(widget.steps, widget.stepsGoal).cycles > 0) {
      ids.add('steps');
    }
    if (appleOverflow(widget.calories, widget.caloriesGoal).cycles > 0) {
      ids.add('calories');
    }
    if (appleOverflow(widget.activeMinutes, widget.activeMinutesGoal).cycles >
        0) {
      ids.add('active');
    }
    _burst.maybePlay(ids);
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

  double _unitSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final raw = (w - 36) / 3.5;
    return raw.clamp(80.0, 118.0);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unitSize(context);
    final s = appleOverflow(widget.steps, widget.stepsGoal);
    final c = appleOverflow(widget.calories, widget.caloriesGoal);
    final a = appleOverflow(widget.activeMinutes, widget.activeMinutesGoal);

    final items = <_AppleSpec>[
      _AppleSpec(
        id: 'steps',
        kind: _GoalKind.steps,
        color: ColorPalette.mintPrimary,
        icon: Icons.directions_walk_rounded,
        name: HomeText.getString(widget.language, 'steps'),
        progress: s.fill,
        cycles: s.cycles,
        bonusLabel: s.cycles > 0 ? '+${s.cycles * widget.stepsGoal}' : null,
        percentLabel: '${(s.fill * 100).round()}%',
        detailLabel: '${widget.steps} / ${widget.stepsGoal}',
        goalValue: widget.stepsGoal,
        valueKey: widget.steps,
      ),
      _AppleSpec(
        id: 'calories',
        kind: _GoalKind.calories,
        color: ColorPalette.calorieBurn,
        icon: Icons.local_fire_department_rounded,
        name: HomeText.getString(widget.language, 'calories'),
        progress: c.fill,
        cycles: c.cycles,
        bonusLabel: c.cycles > 0
            ? '+${(c.cycles * widget.caloriesGoal).round()}'
            : null,
        percentLabel: '${(c.fill * 100).round()}%',
        detailLabel:
            '${widget.calories.toStringAsFixed(0)} / ${widget.caloriesGoal.toStringAsFixed(0)}',
        goalValue: widget.caloriesGoal.round(),
        valueKey: widget.calories.round(),
      ),
      _AppleSpec(
        id: 'active',
        kind: _GoalKind.active,
        color: ColorPalette.skyBlue,
        icon: Icons.timer_outlined,
        name: HomeText.getString(widget.language, 'active'),
        progress: a.fill,
        cycles: a.cycles,
        bonusLabel:
            a.cycles > 0 ? '+${a.cycles * widget.activeMinutesGoal}' : null,
        percentLabel: '${(a.fill * 100).round()}%',
        detailLabel:
            '${widget.activeMinutes} / ${widget.activeMinutesGoal} ${HomeText.getString(widget.language, 'minutes')}',
        goalValue: widget.activeMinutesGoal,
        valueKey: widget.activeMinutes,
      ),
    ];

    final nightDim = widget.isNight ? 0.55 : 1.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.vX2s),
      child: Opacity(
        opacity: nightDim,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: unit,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(unit * 0.18),
                    onTap: () =>
                        _editGoal(items[i].kind, items[i].goalValue),
                    child: _AppleMetric(
                      spec: items[i],
                      wave: _wave,
                      burst: _burst.animation,
                      playBurst: items[i].cycles > 0 &&
                          _burst.hasPlayed(items[i].id),
                      unit: unit,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _syncWaveSpeed() {}
}

class _AppleSpec {
  final String id;
  final _GoalKind kind;
  final Color color;
  final IconData icon;
  final String name;
  final double progress;
  final int cycles;
  final String? bonusLabel;
  final String percentLabel;
  final String detailLabel;
  final int goalValue;
  final Object valueKey;

  const _AppleSpec({
    required this.id,
    required this.kind,
    required this.color,
    required this.icon,
    required this.name,
    required this.progress,
    required this.cycles,
    required this.bonusLabel,
    required this.percentLabel,
    required this.detailLabel,
    required this.goalValue,
    required this.valueKey,
  });
}

class _AppleMetric extends StatelessWidget {
  final _AppleSpec spec;
  final Animation<double> wave;
  final Animation<double> burst;
  final bool playBurst;
  final double unit;

  const _AppleMetric({
    required this.spec,
    required this.wave,
    required this.burst,
    required this.playBurst,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = unit * 0.24;
    final nameSize = (unit * 0.11).clamp(10.0, 13.0);
    final gapIconName = unit * 0.04;
    final gapNameBody = unit * 0.06;
    final bodyW = unit * 0.84;
    final bodyH = unit * 0.90;
    final percentSize = (unit * 0.135).clamp(11.0, 16.0);
    final detailSize = (unit * 0.10).clamp(9.5, 12.5);
    final topBlock = iconSize + gapIconName + nameSize + 4 + gapNameBody;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: unit,
          height: topBlock + bodyH,
          child: AnimatedBuilder(
            animation: Listenable.merge([wave, burst]),
            builder: (context, _) {
              final tr = appleBurstTransform(burst.value, play: playBurst);

              return Column(
                children: [
                  SizedBox(
                    height: iconSize,
                    width: unit,
                    child: MetricIconPulse(
                      icon: spec.icon,
                      color: spec.color,
                      size: iconSize,
                      value: spec.valueKey,
                      style: switch (spec.kind) {
                        _GoalKind.steps => MetricIconStyle.steps,
                        _GoalKind.calories => MetricIconStyle.calories,
                        _GoalKind.active => MetricIconStyle.active,
                      },
                    ),
                  ),
                  SizedBox(height: gapIconName),
                  SizedBox(
                    height: nameSize + 4,
                    child: Text(
                      spec.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        color: spec.color,
                      ),
                    ),
                  ),
                  SizedBox(height: gapNameBody),
                  SizedBox(
                    width: unit,
                    height: bodyH,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (tr.particleT > 0)
                          CustomPaint(
                            size: Size(unit, bodyH),
                            painter: AppleBurstParticlesPainter(
                              color: spec.color,
                              t: tr.particleT,
                            ),
                          ),
                        Opacity(
                          opacity: tr.opacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: tr.scale,
                            child: SizedBox(
                              width: bodyW,
                              height: bodyH,
                              child: CustomPaint(
                                painter: _ApplePainter(
                                  color: spec.color,
                                  progress: spec.progress,
                                  wavePhase: wave.value * math.pi * 2,
                                  emptyOpacity: 0.40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (spec.bonusLabel != null)
                          Positioned(
                            right: -2,
                            top: bodyH * 0.08,
                            child: AppleBonusChip(
                              label: spec.bonusLabel!,
                              color: spec.color,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: unit * 0.06),
        Text(
          spec.percentLabel,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: percentSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2),
        Text(
          spec.detailLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: detailSize,
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
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.50), y(0.14));
    path.cubicTo(x(0.58), y(0.02), x(0.98), y(0.10), x(0.98), y(0.40));
    path.cubicTo(x(0.98), y(0.62), x(0.82), y(0.88), x(0.62), y(0.96));
    path.cubicTo(x(0.55), y(1.00), x(0.45), y(1.00), x(0.38), y(0.96));
    path.cubicTo(x(0.18), y(0.88), x(0.02), y(0.62), x(0.02), y(0.40));
    path.cubicTo(x(0.02), y(0.10), x(0.42), y(0.02), x(0.50), y(0.14));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final apple = _applePath(size);
    final strokeW = (size.width * 0.055).clamp(2.2, 5.0);

    canvas.drawPath(
      apple,
      Paint()
        ..color = color.withValues(alpha: emptyOpacity)
        ..style = PaintingStyle.fill,
    );

    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(apple);
      final b = apple.getBounds();
      final fillTop = b.bottom - b.height * progress;
      final amp = size.height * 0.018;
      final wave = Path()
        ..moveTo(b.left, b.bottom)
        ..lineTo(b.left, fillTop);
      for (int i = 0; i <= 36; i++) {
        final px = b.left + b.width * (i / 36);
        final py = fillTop +
            math.sin(wavePhase + i * 0.45) * amp +
            math.sin(wavePhase * 1.4 + i * 0.75) * amp * 0.35;
        wave.lineTo(px, py);
      }
      wave
        ..lineTo(b.right, b.bottom)
        ..close();
      canvas.drawPath(wave, Paint()..color = color);
      canvas.restore();
    }

    canvas.drawPath(
      apple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dimple = Path()
      ..moveTo(size.width * 0.36, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.30,
        size.width * 0.64,
        size.height * 0.16,
      );
    canvas.drawPath(
      dimple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.85
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
