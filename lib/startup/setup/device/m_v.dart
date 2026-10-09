// lib/startup/setup/device/m_v.dart

import 'package:flutter/material.dart';

import 'package:helsa/setting/responsive/responsive_utils.dart';

import 'package:helsa/startup/setup/widget/setup_header.dart';
import 'package:helsa/startup/setup/widget/title_setup.dart';
import 'package:helsa/startup/setup/widget/continue_button.dart';
import 'package:helsa/startup/setup/widget/skip_button.dart';

class SetupMobileVertical extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String currentLang;
  final bool isStepValid;
  final bool showSkip;
  final VoidCallback? onSkip;
  final VoidCallback onBackPressed;
  final VoidCallback onContinuePressed;
  final Widget Function(String lang) buildStepContent;

  const SetupMobileVertical({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.currentLang,
    required this.isStepValid,
    this.showSkip = false,
    this.onSkip,
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.buildStepContent,
  });

  @override
  Widget build(BuildContext context) {
    final double gapTop = context.vX3s;
    final double gapTitleContent = context.vX3s;
    final double gapBottom = context.vX3s;

    final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
    final bool keyboardOpen = keyboardBottom > 0;

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
                  totalSteps: totalSteps,
                ),
                Expanded(
                  // فقط همین ناحیه با ارتفاع کیبورد کم می‌شود
                  // → عنوان و فیلدها بالای کیبورد جمع می‌شوند
                  child: Padding(
                    padding: EdgeInsets.only(bottom: keyboardBottom),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: context.hS),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              // کیبورد باز: از بالا؛ بسته: وسط
                              mainAxisAlignment: keyboardOpen
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
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
                ),
              ],
            ),
          ),
        ),

        // دکمه ادامه: با کیبورد بالا نمی‌آید (خارج از padding کیبورد)
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
                  if (showSkip && onSkip != null)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SkipButton(
                            currentLang: currentLang,
                            onSkip: onSkip!,
                          ),
                        ),
                        SizedBox(width: context.hS),
                        Expanded(
                          flex: 3,
                          child: ContinueButton(
                            currentLang: currentLang,
                            stepIndex: currentStep,
                            isStepValid: isStepValid,
                            onContinue: onContinuePressed,
                          ),
                        ),
                      ],
                    )
                  else
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
