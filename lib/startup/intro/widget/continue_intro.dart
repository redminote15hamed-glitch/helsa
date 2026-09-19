import 'package:flutter/material.dart';

import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/motion/displayer.dart';

class ContinueIntroButton extends StatelessWidget {
  final VoidCallback onContinue;

  const ContinueIntroButton({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Displayer(
      index: 6,
      template: MotionTemplate.bottomSlide,
      child: Buttoner(
        text: 'Continue',
        template: ButtonTemplate.flatOnSurface,
        isSelected: true,
        onTap: onContinue,
      ),
    );
  }
}
