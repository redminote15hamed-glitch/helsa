// lib/startup/setup/widget/skip_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Skip — same vertical size as Continue (Buttoner).
/// Always enabled, full opacity (not disabled look).
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
        opacity: 1.0,
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
