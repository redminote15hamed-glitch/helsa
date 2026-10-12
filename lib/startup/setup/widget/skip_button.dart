// lib/startup/setup/widget/skip_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Jump (formerly Skip) — theme primary green.
/// Height matches Continue via Expanded + stretch in parent Row.
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
            // پر ارتفاع والد (هم‌ارتفاع Continue)
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(context.m),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hX2s),
                child: TextFielder(
                  text: SetupText.getString(currentLang, 'jump'),
                  template: TextTemplate.button,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
