// lib/startup/setup/widget/skip_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Skip — full primary (theme green), same vertical feel as Continue.
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
    final theme = Theme.of(context);
    final Color bg = theme.colorScheme.primary;
    final Color fg = theme.colorScheme.onPrimary;

    return Displayer(
      index: 5,
      template: MotionTemplate.bottomSlide,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSkip,
          borderRadius: BorderRadius.circular(context.m),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(context.m),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.vS,
                horizontal: context.hS,
              ),
              child: Center(
                child: TextFielder(
                  text: SetupText.getString(currentLang, 'skip'),
                  template: TextTemplate.button,
                  textAlign: TextAlign.center,
                  customStyle: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: context.m,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
