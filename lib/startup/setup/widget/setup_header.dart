// فایل: lib/startup/setup/widget/setup_header.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/header.dart';
import 'package:helsa/setting/kit/circle_inkwell.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/startup/setup/widget/setup_progress.dart';

class SetupHeader extends StatelessWidget {
  final VoidCallback onBackPressed;
  final int currentStep;

  const SetupHeader({
    super.key,
    required this.onBackPressed,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Header(
      leftFlex: 1,
      centerFlex: 4,
      rightFlex: 1,
      leftChild: Align(
        alignment: Alignment.centerLeft,
        // استپ ۰ (انتخاب زبان): دکمه عقب مخفی، فقط جای خالی
        child: currentStep == 0
            ? const SizedBox(width: 48, height: 48)
            : CircleInkWell(
                icon: Icons.arrow_back_ios_new_rounded,
                iconTemplate: IconTemplate.medium,
                onTap: onBackPressed,
              ),
      ),
      centerChild: Center(
        child: SetupProgress(
          totalSteps: 8,
          currentStep: currentStep,
        ),
      ),
      rightChild: Align(
        alignment: Alignment.centerRight,
        child: CircleInkWell(
          icon: Icons.support_agent_rounded,
          iconTemplate: IconTemplate.medium,
          onTap: () {},
        ),
      ),
    );
  }
}
