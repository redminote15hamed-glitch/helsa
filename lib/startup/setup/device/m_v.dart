// lib/startup/setup/device/m_v.dart

import 'package:flutter/material.dart';

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
    final double gapTop = context.vX3s;
    final double gapTitleContent = context.vX3s;
    final double gapBottom = context.vX3s;

    // کیبورد باز است؟ → دکمه ادامه مخفی/غیرقابل لمس
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: context.hS),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: gapTop),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: TitleSetup(
                                  key: ValueKey('title_$currentStep'),
                                  currentLang: currentLang,
                                  step: currentStep,
                                ),
                              ),
                              SizedBox(height: gapTitleContent),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: KeyedSubtree(
                                  key: ValueKey('content_$currentStep'),
                                  child: buildStepContent(currentLang),
                                ),
                              ),
                              SizedBox(height: gapBottom),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: AnimatedOpacity(
            opacity: keyboardOpen ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: keyboardOpen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ContinueButton(
                    currentLang: currentLang,
                    stepIndex: currentStep,
                    isStepValid: isStepValid,
                    onContinue: onContinuePressed,
                  ),
                  SizedBox(height: context.vX3s),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
