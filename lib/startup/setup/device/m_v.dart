// lib/startup/setup/device/m_v.dart

import 'package:flutter/material.dart';

import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

import 'package:helsa/startup/setup/widget/setup_header.dart';
import 'package:helsa/startup/setup/widget/title_setup.dart';
import 'package:helsa/startup/setup/widget/continue_button.dart';

class SetupMobileVertical extends StatelessWidget {
  final int currentStep;
  final String currentLang;
  final bool isStepValid;
  final VoidCallback onBackPressed;
  final VoidCallback onContinuePressed;
  final Widget Function(String lang) buildStepContent;

  const SetupMobileVertical({
    super.key,
    required this.currentStep,
    required this.currentLang,
    required this.isStepValid,
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.buildStepContent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                SetupHeader(
                  onBackPressed: onBackPressed,
                  currentStep: currentStep,
                ),
                Expanded(
                  child: WorkspaceArea(
                    isScrollable: true,
                    child: Column(
                      children: [
                        SizedBox(height: context.vX2s),

                        // عنوان: بدون ارتفاع ثابت — خودش اندازه می‌گیرد
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: TitleSetup(
                            key: ValueKey('title_$currentStep'),
                            currentLang: currentLang,
                            step: currentStep,
                          ),
                        ),

                        SizedBox(height: context.vS),

                        // محتوا: فضای باقی‌مانده (نه vX5l ثابت)
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: KeyedSubtree(
                              key: ValueKey('content_$currentStep'),
                              child: buildStepContent(currentLang),
                            ),
                          ),
                        ),

                        SizedBox(height: context.vX2s),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            children: [
              ContinueButton(
                currentLang: currentLang,
                stepIndex: currentStep,
                isStepValid: isStepValid,
                onContinue: onContinuePressed,
              ),
              SizedBox(height: context.vS),
            ],
          ),
        ),
      ],
    );
  }
}
