// lib/startup/setup/widget/continue_button.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class ContinueButton extends StatelessWidget {
  final String currentLang;
  final int stepIndex;
  final bool isStepValid;
  final VoidCallback onContinue;

  const ContinueButton({
    super.key,
    required this.currentLang,
    required this.stepIndex,
    required this.isStepValid,
    required this.onContinue,
  });

  void _handleTap(BuildContext context) {
    if (isStepValid) {
      onContinue();
      return;
    }

    String errorMessage;
    switch (stepIndex) {
      case 0:
        errorMessage = SetupText.getString(currentLang, 'err_lang');
        break;
      case 1:
        errorMessage = SetupText.getString(currentLang, 'err_name');
        break;
      case 2:
        errorMessage = SetupText.getString(currentLang, 'err_gender');
        break;
      case 3:
        errorMessage = SetupText.getString(currentLang, 'err_age');
        break;
      case 4:
        errorMessage = SetupText.getString(currentLang, 'err_physical_data');
        break;
      case 5:
        errorMessage = SetupText.getString(currentLang, 'err_activity_level');
        break;
      case 6:
        errorMessage = SetupText.getString(currentLang, 'err_diet_level');
        break;
      case 7:
        errorMessage = SetupText.getString(currentLang, 'err_restriction_level');
        break;
      case 8:
        errorMessage = SetupText.getString(currentLang, 'err_sleep');
        break;
      default:
        errorMessage = SetupText.getString(currentLang, 'err_restriction_level');
    }

    SnackBarer.show(
      context,
      message: errorMessage,
      template: SnackbarTemplate.neutral,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Displayer(
      index: 6,
      template: MotionTemplate.bottomSlide,
      child: Opacity(
        opacity: isStepValid ? 1.0 : 0.5,
        child: Buttoner(
          text: SetupText.getString(currentLang, 'continue'),
          template: ButtonTemplate.flatOnSurface,
          isSelected: isStepValid,
          onTap: () => _handleTap(context),
        ),
      ),
    );
  }
}
