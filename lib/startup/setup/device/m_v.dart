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
                      // اگر محتوا کوتاه باشد، حداقل به اندازه صفحه کشیده می‌شود
                      // اگر بلندتر باشد، اسکرول فعال می‌شود — بدون Expanded داخل اسکرول
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
                            mainAxisAlignment: MainAxisAlignment.start,
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
                              // سقف ارتفاع محتوا نسبت به صفحه (فشرده روی صفحه کوچک)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: KeyedSubtree(
                                  key: ValueKey('content_$currentStep'),
                                  child: _StepContentShell(
                                    maxHeight: constraints.maxHeight,
                                    child: buildStepContent(currentLang),
                                  ),
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
          child: Column(
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
      ],
    );
  }
}

/// به استپ‌هایی که لیست بلند دارند سقف ارتفاع می‌دهد تا روی صفحه کوچک
/// هم جا شوند و هم در صورت نیاز کل صفحه اسکرول شود.
class _StepContentShell extends StatelessWidget {
  final double maxHeight;
  final Widget child;

  const _StepContentShell({
    required this.maxHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // حدود ۵۵٪ ارتفاع مفید برای بدنه استپ؛ روی صفحه خیلی کوچک حداقل یک مقدار ریسپانسیو
    final double cap = (maxHeight * 0.55).clamp(
      context.vX3l,
      maxHeight * 0.75,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: cap),
      child: child,
    );
  }
}
