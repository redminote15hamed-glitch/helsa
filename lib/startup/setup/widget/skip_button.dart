// lib/startup/setup/widget/skip_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Skip — same vertical size as Continue (uses Buttoner).
/// Always enabled; softer look via opacity.
class SkipButton extends StatelessWidget {
  final String currentLang;
  final VoidCallback onSkip;

  const SkipButton({
    super.key,
    required this.currentLang,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Displayer(
      index: 5,
      template: MotionTemplate.bottomSlide,
      child: Opacity(
        // between disabled continue (0.5) and enabled (1.0)
        opacity: 0.72,
        child: Buttoner(
          text: SetupText.getString(currentLang, 'skip'),
          template: ButtonTemplate.flatOnSurface,
          isSelected: false,
          onTap: onSkip,
        ),
      ),
    );
  }
}
