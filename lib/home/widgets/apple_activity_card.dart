// lib/home/widgets/apple_activity_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/widgets/apple_burst.dart';
import 'package:helsa/home/widgets/walk_aura.dart';
import 'package:helsa/home/widgets/ghost_progress.dart';
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
    // نبض قدم حذف شد — فقط موج مایع شیشه‌ای در painter
    _triggerBurst();
  }

  @override
  void dispose() {
    _wave.dispose();
    _burst.disposeController();
    super.dispose();
  }

  void _syncWaveSpeed() {
    // پیاده‌روی: موج سریع‌تر و هم‌فاز برای هر سه سیب
    final ms = widget.isWalking ? 900 : 2200;
    if (_wave.duration?.inMilliseconds != ms) {
      final v = _wave.value;
      _wave.duration = Duration(milliseconds: ms);
      _wave.forward(from: v);
      _wave.repeat();
    }
  }

  void _triggerBurst() {
    final s = appleOverflow(widget.steps, widget.stepsGoal);
    final c = appleOverflow(widget.calories, widget.caloriesGoal);
    final a = appleOverflow(widget.activeMinutes, widget.activeMinutesGoal);
    // هر افزایش cycles → انفجار دوباره
    _burst.checkCycles({
      'steps': s.cycles,
      'calories': c.cycles,
      'active': a.cycles,
    });
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
        // فقط دور فعلی سیب
        detailLabel:
            '${(s.fill * widget.stepsGoal).round()} / ${widget.stepsGoal}',
        // مجموع کل بین اسم و سیب
        totalLabel: '${widget.steps}',
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
            '${(c.fill * widget.caloriesGoal).round()} / ${widget.caloriesGoal.round()}',
        totalLabel: widget.calories.toStringAsFixed(0),
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
            '${(a.fill * widget.activeMinutesGoal).round()} / ${widget.activeMinutesGoal} ${HomeText.getString(widget.language, 'minutes')}',
        totalLabel: '${widget.activeMinutes}',
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
                    child: items[i].id == 'steps'
                        ? WalkAura(
                            steps: widget.steps,
                            isWalking: widget.isWalking,
                            color: items[i].color,
                            child: _AppleMetric(
                              spec: items[i],
                              wave: _wave,
                              burst: _burst.animation,
                              playBurst: _burst.isBursting(items[i].id),
                              unit: unit,
                              ghostProgress: GhostProgress.yesterdayStepsProgress(
                                fallbackGoal: widget.stepsGoal,
                              ),
                              isWalking: widget.isWalking,
                            ),
                          )
                        : _AppleMetric(
                            spec: items[i],
                            wave: _wave,
                            burst: _burst.animation,
                            playBurst: _burst.isBursting(items[i].id),
                            unit: unit,
                            isWalking: widget.isWalking,
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
  final String totalLabel;
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
    required this.totalLabel,
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
  final double ghostProgress;
  final bool isWalking;

  const _AppleMetric({
    required this.spec,
    required this.wave,
    required this.burst,
    required this.playBurst,
    required this.unit,
    this.ghostProgress = 0,
    this.isWalking = false,
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
    final topBlock = iconSize + gapIconName + nameSize + 4 + nameSize + gapNameBody;

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
                  // مجموع کل (مثلاً ۳۸۰) بین اسم و سیب
                  Text(
                    spec.totalLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: (nameSize * 0.95).clamp(10.0, 13.0),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: gapNameBody * 0.7),
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
                                  ghostProgress: ghostProgress,
                                  isWalking: isWalking,
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
  final double ghostProgress;
  final bool isWalking;

  _ApplePainter({
    required this.color,
    required this.progress,
    required this.wavePhase,
    required this.emptyOpacity,
    this.ghostProgress = 0,
    this.isWalking = false,
  });

  Path _bodyPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.50), y(0.22));
    path.cubicTo(x(0.62), y(0.12), x(0.92), y(0.18), x(0.94), y(0.42));
    path.cubicTo(x(0.96), y(0.62), x(0.82), y(0.86), x(0.62), y(0.94));
    path.cubicTo(x(0.55), y(0.98), x(0.45), y(0.98), x(0.38), y(0.94));
    path.cubicTo(x(0.18), y(0.86), x(0.04), y(0.62), x(0.06), y(0.42));
    path.cubicTo(x(0.08), y(0.18), x(0.38), y(0.12), x(0.50), y(0.22));
    path.close();
    return path;
  }

  Path _stemPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.48), y(0.22));
    path.quadraticBezierTo(x(0.46), y(0.12), x(0.50), y(0.04));
    path.quadraticBezierTo(x(0.54), y(0.12), x(0.52), y(0.22));
    path.close();
    return path;
  }

  Path _leafPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.52), y(0.12));
    path.cubicTo(x(0.62), y(0.02), x(0.78), y(0.06), x(0.80), y(0.16));
    path.cubicTo(x(0.78), y(0.24), x(0.62), y(0.22), x(0.52), y(0.14));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final body = _bodyPath(size);
    final stem = _stemPath(size);
    final leaf = _leafPath(size);
    final strokeW = (size.width * 0.048).clamp(2.0, 4.5);
    final b = body.getBounds();

    // —— لایه شیشه: گرادیان خالی ——
    final glassShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: emptyOpacity * 0.55),
        color.withValues(alpha: emptyOpacity),
        color.withValues(alpha: emptyOpacity * 0.7),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(b);
    canvas.drawPath(
      body,
      Paint()
        ..shader = glassShader
        ..style = PaintingStyle.fill,
    );

    // سایهٔ دیروز
    if (ghostProgress > 0.01) {
      canvas.save();
      canvas.clipPath(body);
      final top = b.bottom - b.height * ghostProgress.clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTRB(b.left, top, b.right, b.bottom),
        Paint()..color = color.withValues(alpha: 0.16),
      );
      final dash = Paint()
        ..color = color.withValues(alpha: 0.32)
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;
      final path = Path();
      double x = b.left;
      while (x < b.right) {
        path.moveTo(x, top);
        path.lineTo(math.min(x + 4, b.right), top);
        x += 8;
      }
      canvas.drawPath(path, dash);
      canvas.restore();
    }

    // —— مایع داخل شیشه ——
    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(body);
      final fillH = b.height * progress.clamp(0.0, 1.0);
      final fillTop = b.bottom - fillH;
      // تکان مایع قوی‌تر وقتی راه می‌رود
      final amp = size.height * (isWalking ? 0.028 : 0.014);
      final wave = Path()
        ..moveTo(b.left - 2, b.bottom + 2)
        ..lineTo(b.left - 2, fillTop);
      for (int i = 0; i <= 40; i++) {
        final t = i / 40.0;
        final px = b.left + b.width * t;
        final py = fillTop +
            math.sin(wavePhase + t * 6.2) * amp +
            math.sin(wavePhase * 1.7 + t * 3.1) * amp * 0.4;
        wave.lineTo(px, py);
      }
      wave
        ..lineTo(b.right + 2, b.bottom + 2)
        ..close();

      // —— سه لایه مایع ——
      final deep = Color.lerp(color, const Color(0xFF000000), 0.28)!;
      final mid = color;
      final bright = Color.lerp(color, const Color(0xFFFFFFFF), 0.28)!;

      // لایه ۱: عمق تیره
      canvas.drawPath(
        wave,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [deep, mid.withValues(alpha: 0.95)],
            stops: const [0.0, 1.0],
          ).createShader(Rect.fromLTRB(b.left, fillTop - amp, b.right, b.bottom))
          ..style = PaintingStyle.fill,
      );

      // لایه ۲: باند میانی درخشان (شیشه سه‌لایه)
      final midBand = Path()
        ..moveTo(b.left, b.bottom)
        ..lineTo(b.left, fillTop + fillH * 0.35);
      for (int i = 0; i <= 40; i++) {
        final tt = i / 40.0;
        final px = b.left + b.width * tt;
        final py = fillTop +
            fillH * 0.35 +
            math.sin(wavePhase * 0.9 + tt * 5.0) * amp * 0.5;
        midBand.lineTo(px, py);
      }
      midBand
        ..lineTo(b.right, b.bottom)
        ..close();
      canvas.drawPath(
        midBand,
        Paint()
          ..color = mid.withValues(alpha: 0.55)
          ..style = PaintingStyle.fill
          ..blendMode = BlendMode.softLight,
      );

      // لایه ۳: سطح روشن موج‌دار
      final topBand = Path()
        ..moveTo(b.left, fillTop + fillH * 0.15 + amp)
        ..lineTo(b.left, fillTop);
      for (int i = 0; i <= 40; i++) {
        final tt = i / 40.0;
        final px = b.left + b.width * tt;
        final py = fillTop +
            math.sin(wavePhase + tt * 6.2) * amp +
            math.sin(wavePhase * 1.7 + tt * 3.1) * amp * 0.4;
        topBand.lineTo(px, py);
      }
      topBand
        ..lineTo(b.right, fillTop + fillH * 0.15 + amp)
        ..close();
      canvas.drawPath(
        topBand,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              bright.withValues(alpha: 0.55),
              bright.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTRB(b.left, fillTop - amp, b.right, fillTop + fillH * 0.25))
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    }

    // —— هایلایت شیشه (انعکاس) ——
    canvas.save();
    canvas.clipPath(body);
    final highlight = Path()
      ..moveTo(b.left + b.width * 0.12, b.top + b.height * 0.12)
      ..quadraticBezierTo(
        b.left + b.width * 0.28,
        b.top + b.height * 0.08,
        b.left + b.width * 0.38,
        b.top + b.height * 0.22,
      )
      ..quadraticBezierTo(
        b.left + b.width * 0.22,
        b.top + b.height * 0.38,
        b.left + b.width * 0.12,
        b.top + b.height * 0.12,
      )
      ..close();
    canvas.drawPath(
      highlight,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(b)
        ..style = PaintingStyle.fill,
    );
    // لبهٔ نرم پایین شیشه
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.35
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();

    // stroke + stem + leaf
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      stem,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      leaf,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ApplePainter old) =>
      old.color != color ||
      old.progress != progress ||
      old.wavePhase != wavePhase ||
      old.emptyOpacity != emptyOpacity ||
      old.ghostProgress != ghostProgress ||
      old.isWalking != isWalking;
}
