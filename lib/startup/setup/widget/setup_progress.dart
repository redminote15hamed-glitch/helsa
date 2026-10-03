// lib/startup/setup/widget/setup_progress.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class SetupProgress extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const SetupProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int safeTotal = totalSteps < 1 ? 1 : totalSteps;
    final double progress =
        ((currentStep + 1).clamp(0, safeTotal)) / safeTotal;

    return Container(
      width: double.infinity,
      height: context.vX3s,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(context.m),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        // از ابتدای جهت متن پر شود (چپ در LTR، راست در RTL) — نه از وسط
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          widthFactor: progress.clamp(0.0, 1.0),
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(context.m),
            ),
          ),
        ),
      ),
    );
  }
}
