import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class TitleSetup extends StatelessWidget {
  final String currentLang;
  final int step;

  const TitleSetup({
    super.key,
    required this.currentLang,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String textKey;

    switch (step) {
      case 0:
        icon = Icons.language_rounded;
        textKey = 'title';
        break;
      case 1:
        icon = Icons.person_rounded;
        textKey = 'familiarity_title';
        break;
      case 2:
        icon = Icons.transgender_rounded;
        textKey = 'gender_title';
        break;
      case 3:
        icon = Icons.cake_rounded;
        textKey = 'age_title';
        break;
      case 4:
        icon = Icons.self_improvement_rounded;
        textKey = 'physical_data_title';
        break;
      case 5:
        icon = Icons.fitness_center_rounded;
        textKey = 'activity_title';
        break;
      case 6:
        icon = Icons.restaurant_menu_rounded;
        textKey = 'diet_title';
        break;
      case 7:
        icon = Icons.nightlight_round;
        textKey = 'sleep_title';
        break;
      default:
        icon = Icons.info_rounded;
        textKey = 'title';
    }

    final Widget iconWidget = step == 7
        ? _SleepTitleIcon(color: Theme.of(context).colorScheme.primary)
        : Iconer(icon: icon, template: IconTemplate.giant);

    // mainAxisSize.min تا در ارتفاع کم (شناور) overflow ندهد
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Displayer(
          index: 0,
          template: MotionTemplate.zoomFade,
          child: iconWidget,
        ),
        SizedBox(height: context.vX3s),
        Displayer(
          index: 1,
          template: MotionTemplate.flipX,
          child: TextFielder(
            text: SetupText.getString(currentLang, textKey),
            template: TextTemplate.title,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// هلال + ستاره چهارپر داخل فضای باز
class _SleepTitleIcon extends StatelessWidget {
  final Color color;

  const _SleepTitleIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    final double unit = context.baseScale;

    final double boxW = unit * 3.8;
    final double boxH = unit * 3.2;

    final double moonSize = unit * 3.0;
    final double starSize = unit * 0.95;

    final double starLeft = boxW * 0.52;
    final double starTop = boxH * 0.18;

    return SizedBox(
      width: boxW,
      height: boxH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: (boxH - moonSize) / 2,
            child: Icon(
              Icons.nightlight_round,
              size: moonSize,
              color: color,
            ),
          ),
          Positioned(
            left: starLeft,
            top: starTop,
            child: CustomPaint(
              size: Size(starSize, starSize),
              painter: _FourPointStarPainter(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FourPointStarPainter extends CustomPainter {
  final Color color;

  _FourPointStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outer = size.width / 2;
    final inner = outer * 0.28;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final outerAngle = -math.pi / 2 + i * math.pi / 2;
      final innerAngle = outerAngle + math.pi / 4;

      final ox = cx + outer * math.cos(outerAngle);
      final oy = cy + outer * math.sin(outerAngle);
      final ix = cx + inner * math.cos(innerAngle);
      final iy = cy + inner * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FourPointStarPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
