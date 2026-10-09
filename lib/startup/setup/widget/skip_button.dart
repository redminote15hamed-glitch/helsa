// lib/startup/setup/widget/skip_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// دکمه «رد کردن»
/// - همیشه فعال
/// - رنگ متفاوت از ادامه
/// - شفافیت بین ادامه غیرفعال (0.5) و فعال (1.0)
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

    return Displayer(
      index: 5,
      template: MotionTemplate.bottomSlide,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSkip, // همیشه فعال
          borderRadius: BorderRadius.circular(context.m),
          child: Ink(
            decoration: BoxDecoration(
              // رنگ متفاوت از ادامه؛ پررنگ‌تر از شبح محض
              color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(context.m),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.28),
                width: context.baseScale * 0.06,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.vS,
                horizontal: context.hS,
              ),
              child: Center(
                child: Opacity(
                  // بین ادامه غیرفعال (0.5) و فعال (1.0)
                  opacity: 0.72,
                  child: Text(
                    SetupText.getString(currentLang, 'skip'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
