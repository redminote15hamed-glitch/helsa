import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class ContinueButton extends StatelessWidget {
  final String currentLang;
  final int stepIndex;
  final bool isStepValid;
  final VoidCallback onContinue;

  /// استپ حساسیت: Skip کنار ادامه
  final bool showSkip;
  final VoidCallback? onSkip;

  const ContinueButton({
    super.key,
    required this.currentLang,
    required this.stepIndex,
    required this.isStepValid,
    required this.onContinue,
    this.showSkip = false,
    this.onSkip,
  });

  void _handleTap(BuildContext context) {
    if (isStepValid) {
      onContinue();
    } else {
      String errorMessage;
      if (stepIndex == 0) {
        errorMessage = SetupText.getString(currentLang, 'err_lang');
      } else if (stepIndex == 1) {
        errorMessage = SetupText.getString(currentLang, 'err_name');
      } else if (stepIndex == 2) {
        errorMessage = SetupText.getString(currentLang, 'err_gender');
      } else if (stepIndex == 3) {
        errorMessage = SetupText.getString(currentLang, 'err_age');
      } else if (stepIndex == 4) {
        errorMessage = SetupText.getString(currentLang, 'err_physical_data');
      } else if (stepIndex == 5) {
        errorMessage = SetupText.getString(currentLang, 'err_activity_level');
      } else if (stepIndex == 6) {
        errorMessage = SetupText.getString(currentLang, 'err_diet_level');
      } else if (stepIndex == 7) {
        errorMessage = SetupText.getString(currentLang, 'err_restriction_level');
      } else if (stepIndex == 8) {
        errorMessage = SetupText.getString(currentLang, 'err_sleep');
      } else {
        errorMessage = SetupText.getString(currentLang, 'err_restriction_level');
      }

      SnackBarer.show(
        context,
        message: errorMessage,
        template: SnackbarTemplate.neutral,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final continueBtn = Opacity(
      opacity: isStepValid ? 1.0 : 0.5,
      child: Buttoner(
        text: SetupText.getString(currentLang, 'continue'),
        template: ButtonTemplate.flatOnSurface,
        isSelected: isStepValid,
        onTap: () => _handleTap(context),
      ),
    );

    if (!showSkip || onSkip == null) {
      return Displayer(
        index: 6,
        template: MotionTemplate.bottomSlide,
        child: continueBtn,
      );
    }

    // Skip + ادامه کوچک‌تر کنار هم
    return Displayer(
      index: 6,
      template: MotionTemplate.bottomSlide,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hS),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Buttoner(
                text: SetupText.getString(currentLang, 'skip'),
                template: ButtonTemplate.flatOnSurface,
                isSelected: false,
                onTap: onSkip!,
              ),
            ),
            SizedBox(width: context.hS),
            Expanded(
              flex: 3,
              child: continueBtn,
            ),
          ],
        ),
      ),
    );
  }
}
