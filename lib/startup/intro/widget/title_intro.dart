// lib/startup/intro/widget/title_intro.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class TitleIntro extends StatelessWidget {
  const TitleIntro({super.key});

  @override
  Widget build(BuildContext context) {
    // استفاده از یک Key ثابت در سطح والد، به Displayerها کمک می‌کند
    // تا در صورت rebuild شدن کل صفحه، انیمیشن را از ابتدا شروع کنند.
    return Column(
      key: const ValueKey('title_intro_content'),
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Displayer(
          index: 0,
          template: MotionTemplate.zoomFade,
          child: Iconer(
            icon: Icons.health_and_safety_rounded,
            template: IconTemplate.giant,
          ),
        ),
        SizedBox(height: context.vX2s),
        const Displayer(
          index: 1,
          template: MotionTemplate.flipX,
          child: TextFielder(
            text: 'خوش اومدی',
            template: TextTemplate.headline,
            textAlign: TextAlign.center,
          ),
        ),
        const Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: TextFielder(
            text: 'دستیار هوشمند سلامت تو',
            template: TextTemplate.subtitle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
