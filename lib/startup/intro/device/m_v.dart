import 'package:flutter/material.dart';

import 'package:helsa/setting/kit/header.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/startup/intro/widget/title_intro.dart';

import 'package:helsa/startup/intro/widget/continue_intro.dart';

class IntroMobileVertical extends StatelessWidget {
  final VoidCallback onContinue;

  const IntroMobileVertical({
    super.key,
    required this.onContinue,
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
                const Header(),
                Expanded(
                  child: WorkspaceArea(
                    isScrollable: true,
                    child: Column(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: context.vX3l,
                          width: double
                              .infinity, // اضافه کردن width در اینجا برای تمیزی بیشتر
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.0),
                              borderRadius: BorderRadius.circular(context.l),
                            ),
                            // اینجا جایگزین شد:
                            child: const TitleIntro(),
                          ),
                        ),
// ...
                        SizedBox(
                          height: context.vX5l,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(context.l),
                            ),
                          ),
                        ),
                        const Spacer(),
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
              ContinueIntroButton(
                onContinue: onContinue,
              ),
              SizedBox(height: context.vS),
            ],
          ),
        ),
      ],
    );
  }
}
