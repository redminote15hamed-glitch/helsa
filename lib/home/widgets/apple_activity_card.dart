// lib/home/widgets/apple_activity_card.dart
// یک اسکیل واحد برای کل ویجت سیب — شکل / آیکون / خط / موج با هم
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

  /// یک اندازه پایه برای هر سه سیب — از عرض صفحه، یکسان
  double _unitSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // سه ستون + padding؛ واحد = ضلع مرجع ویجت کامل (آیکون+سیب)
    final raw = (w - 48) / 3.4;
    return raw.clamp(88.0, 128.0);
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
            if (i > 0) const SizedBox(width: 8),
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
  final double unit; // کل بلوک با یک مقیاس

  const _AppleMetric({
    required this.spec,
    required this.wave,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    // نسبت‌های ثابت داخل unit — همه با هم بزرگ/کوچک می‌شوند
    final iconSize = unit * 0.28;
    final iconGap = unit * 0.06; // فاصله آیکون تا سیب
    final bodyH = unit * 0.92; // ارتفاع بدنه سیب
    final bodyW = unit * 0.78; // عرض بدنه (از ارتفاع کمتر → سیب نه دایره)
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
                    SizedBox(
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
                  ],
                );
              },
            ),
          ),
          SizedBox(height: unit * 0.08),
          Text(
            spec.percentLabel,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: (unit * 0.145).clamp(12.0, 18.0),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: unit * 0.02),
          Text(
            spec.detailLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (unit * 0.11).clamp(10.0, 14.0),
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

/// Path نرمال‌شده 0..1 — با هر Size همان نسبت سیب
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

  /// مختصات نسبی → سیب کلاسیک (شانه پهن، پایین جمع، dimple)
  Path _applePath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;

    final path = Path();
    // dimple مرکز بالا
    path.moveTo(x(0.50), y(0.12));

    // راست بالا → شانه
    path.cubicTo(x(0.58), y(0.04), x(0.95), y(0.18), x(0.97), y(0.42));
    // راست پایین → نوک
    path.cubicTo(x(0.98), y(0.68), x(0.72), y(0.96), x(0.50), y(0.98));
    // چپ پایین
    path.cubicTo(x(0.28), y(0.96), x(0.02), y(0.68), x(0.03), y(0.42));
    // چپ بالا → dimple
    path.cubicTo(x(0.05), y(0.18), x(0.42), y(0.04), x(0.50), y(0.12));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final apple = _applePath(size);
    final strokeW = (size.width * 0.055).clamp(2.0, 5.5);

    // پر خالی
    canvas.drawPath(
      apple,
      Paint()
        ..color = color.withValues(alpha: emptyOpacity)
        ..style = PaintingStyle.fill,
    );

    // موج از پایین
    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(apple);
      final b = apple.getBounds();
      final fillTop = b.bottom - b.height * progress;
      final amp = size.height * 0.018;
      final wave = Path()
        ..moveTo(b.left, b.bottom)
        ..lineTo(b.left, fillTop);
      for (int i = 0; i <= 32; i++) {
        final px = b.left + b.width * (i / 32);
        final py = fillTop +
            math.sin(wavePhase + i * 0.48) * amp +
            math.sin(wavePhase * 1.35 + i * 0.8) * amp * 0.4;
        wave.lineTo(px, py);
      }
      wave
        ..lineTo(b.right, b.bottom)
        ..close();
      canvas.drawPath(wave, Paint()..color = color);
      canvas.restore();
    }

    // اسکلت
    canvas.drawPath(
      apple,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeJoin = StrokeJoin.round,
    );

    // dimple
    final dimple = Path()
      ..moveTo(size.width * 0.38, size.height * 0.14)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.28,
        size.width * 0.62,
        size.height * 0.14,
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
