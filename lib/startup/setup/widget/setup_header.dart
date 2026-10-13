// lib/startup/setup/widget/setup_header.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/setting/kit/header.dart';
import 'package:helsa/setting/kit/circle_inkwell.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_progress.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class SetupHeader extends StatelessWidget {
  final VoidCallback onBackPressed;
  final int currentStep;
  final int totalSteps;
  final String currentLang;

  static const String supportEmail = 'redmi.note.15.hamed@gmail.com';

  const SetupHeader({
    super.key,
    required this.onBackPressed,
    required this.currentStep,
    required this.totalSteps,
    this.currentLang = 'fa',
  });

  void _showSupportSheet(BuildContext context) {
    final theme = Theme.of(context);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'support',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim, secAnim) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        // ورود از چپ + خروج از چپ (همان مسیر)
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        final Animation<double> fade = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        );

        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.hM,
                      0,
                      context.hM,
                      context.vM,
                    ),
                    child: Displayer(
                      index: 0,
                      template: MotionTemplate.leftSlide,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          context.hM,
                          context.vS,
                          context.hM,
                          context.vS,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(context.m * 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: context.baseScale * 0.8,
                              offset: Offset(0, context.baseScale * 0.15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: context.baseScale * 2.2,
                              height: context.baseScale * 0.22,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(context.m),
                              ),
                            ),
                            SizedBox(height: context.vS),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.hS,
                                vertical: context.vX2s,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(context.m),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.25),
                                  width: context.baseScale * 0.06,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Iconer(
                                    icon: Icons.email_rounded,
                                    template: IconTemplate.small,
                                    customColor: theme.colorScheme.primary,
                                    useGradient: false,
                                  ),
                                  SizedBox(width: context.hX2s),
                                  Expanded(
                                    child: TextFielder(
                                      text: supportEmail,
                                      template: TextTemplate.body,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      customStyle: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: context.m * 0.9,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.hX3s),
                                  Material(
                                    color: theme.colorScheme.primary,
                                    borderRadius:
                                        BorderRadius.circular(context.m * 0.7),
                                    child: InkWell(
                                      onTap: () async {
                                        await Clipboard.setData(
                                          const ClipboardData(
                                            text: supportEmail,
                                          ),
                                        );
                                        if (ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                SetupText.getString(
                                                  currentLang,
                                                  'support_copied',
                                                ),
                                              ),
                                              duration:
                                                  const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(
                                        context.m * 0.7,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: context.hS,
                                          vertical: context.vX2s,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.copy_rounded,
                                              size: context.m,
                                              color:
                                                  theme.colorScheme.onPrimary,
                                            ),
                                            SizedBox(width: context.hX3s),
                                            Text(
                                              SetupText.getString(
                                                currentLang,
                                                'support_copy',
                                              ),
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme.onPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: context.s,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.vS),
                            TextFielder(
                              text: SetupText.getString(
                                currentLang,
                                'support_hint',
                              ),
                              template: TextTemplate.caption,
                              textAlign: TextAlign.center,
                              customStyle: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                fontSize: context.s,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Header(
      leftFlex: 1,
      centerFlex: 4,
      rightFlex: 1,
      leftChild: Align(
        alignment: Alignment.centerLeft,
        child: currentStep == 0
            ? SizedBox(width: context.x2l, height: context.x2l)
            : CircleInkWell(
                icon: Icons.arrow_back_ios_new_rounded,
                iconTemplate: IconTemplate.medium,
                onTap: onBackPressed,
              ),
      ),
      centerChild: Center(
        child: SetupProgress(
          totalSteps: totalSteps,
          currentStep: currentStep,
        ),
      ),
      rightChild: Align(
        alignment: Alignment.centerRight,
        child: CircleInkWell(
          icon: Icons.support_agent_rounded,
          iconTemplate: IconTemplate.medium,
          onTap: () => _showSupportSheet(context),
        ),
      ),
    );
  }
}
