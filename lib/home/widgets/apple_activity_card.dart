// lib/home/widgets/apple_activity_card.dart
// سیب کلاسیک مثل مرجع + آیکون جدا و بالاتر + اسکیل واحد
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

  double _unitSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // کمی کوچک‌تر تا سه تا راحت جا شوند و شبیه مرجع بمانند
    final raw = (w - 40) / 3.55;
    return raw.clamp(78.0, 112.0);
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unitSize(context);

    final items = <_AppleSpec>[
      _AppleSpec(
        kind: _GoalKind.steps,
        color: ColorPalette.mintPrimary,
        icon: Icons.directions_walk_rounded,
        progress: _p(widget.steps, widget.stepsGoal),
        percentLabel:
            '${(_p(widget.steps, widget.stepsGoal) * 100).round()}%',
        detailLabel: '${widget.steps} / ${widget.stepsGoal}',
        goalValue: widget.stepsGoal,
      ),
      _AppleSpec(
        kind: _GoalKind.calories,
        color: ColorPalette.calorieBurn,
        icon: Icons.local_fire_department_rounded,
        progress: _p(widget.calories, widget.caloriesGoal),
        percentLabel:
            '${(_p(widget.calories, widget.caloriesGoal) * 100).round()}%',
        detailLabel:
            '${widget.calories.toStringAsFixed(0)} / ${widget.caloriesGoal.toStringAsFixed(0)}',
        goalValue: widget.caloriesGoal.round(),
      ),
      _AppleSpec(
        kind: _GoalKind.active,
        color: ColorPalette.skyBlue,
        icon: Icons.timer_outlined,
        progress: _p(widget.activeMinutes, widget.activeMinutesGoal),
        percentLabel:
            '${(_p(widget.activeMinutes, widget.activeMinutesGoal) * 100).round()}%',
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
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(unit * 0.2),
                  onTap: () => _editGoal(items[i].kind, items[i].goalValue),
                  child: _AppleMetric(
                    spec: items[i],
                    wave: _wave,
                    unit: unit,
                  ),
                ),
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
  final double unit;

  const _AppleMetric({
    required this.spec,
    required this.wave,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    // آیکون خیلی بالاتر از بدنه
    final iconSize = unit * 0.26;
    final iconGap = unit * 0.28; // فاصله واضح
    // بدنه باریک‌تر از مربع تا شبیه سیب مرجع باشد
    final bodyW = unit * 0.72;
    final bodyH = unit * 0.88;
    final totalH = iconSize + iconGap + bodyH;

    return SizedBox(
      width: unit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: unit,
            height: totalH,
            child: AnimatedBuilder(
              animation: wave,
              builder: (context, _) {
                return Column(
                  children: [
                    SizedBox(
                      height: iconSize,
                      width: unit,
                      child: Icon(
                        spec.icon,
                        size: iconSize,
                        color: spec.color,
                      ),
                    ),
                    SizedBox(height: iconGap),
                    Center(
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
                  ],
                );
              },
            ),
          ),
          SizedBox(height: unit * 0.07),
          Text(
            spec.percentLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: (unit * 0.14).clamp(11.0, 17.0),
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
              fontSize: (unit * 0.105).clamp(9.5, 13.0),
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// سیب خطی کلاسیک شبیه تصویر مرجع (بدون برگ)
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
    // شروع از وسط فرورفتگی بالا (dimple عمیق مثل مرجع)
    path.moveTo(x(0.50), y(0.16));

    // قوس راست بالای dimple → شانه راست پهن
    path.cubicTo(
      x(0.56), y(0.02),
      x(0.92), y(0.08),
      x(0.96), y(0.36),
    );
    // شانه راست → پایین راست (جمع‌شونده)
    path.cubicTo(
      x(1.00), y(0.58),
      x(0.88), y(0.82),
      x(0.68), y(0.94),
    );
    // نوک پایین
    path.cubicTo(
      x(0.58), y(1.00),
      x(0.42), y(1.00),
      x(0.32), y(0.94),
    );
    // پایین چپ → شانه چپ
    path.cubicTo(
      x(0.12), y(0.82),
      x(0.00), y(0.58),
      x(0.04), y(0.36),
    );
    // شانه چپ → برگشت به dimple
    path.cubicTo(
      x(0.08), y(0.08),
      x(0.44), y(0.02),
      x(0.50), y(0.16),
    );
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final apple = _applePath(size);
    final strokeW = (size.width * 0.06).clamp(2.2, 5.0);

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
      final amp = size.height * 0.02;
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

    // dimple واضح‌تر (مثل خط مرجع)
    final dimple = Path()
      ..moveTo(size.width * 0.34, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.34,
        size.width * 0.66,
        size.height * 0.18,
      );
    canvas.drawPath(
      dimple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.9
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
