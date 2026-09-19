// فایل: lib/startup/setup/widget/setup_progress.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class SetupProgress extends StatelessWidget {
  final int totalSteps; // کل مراحل (مثلاً ۲)
  final int currentStep; // مرحله فعلی (صفر شروع می‌شود)

  const SetupProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // محاسبه درصد پیشرفت (مثلاً مرحله 0 از 2 می‌شود 0.5)
    // برای اینکه در مرحله آخر کامل پر شود:
    final double progress = (currentStep + 1) / totalSteps;

    return Container(
      width: double.infinity, // پر کردن کل فضای در دسترس
      height: context.vX3s, // ارتفاع نوار
      decoration: BoxDecoration(
        color:
            theme.colorScheme.onSurface.withValues(alpha: 0.1), // رنگ پس‌زمینه نوار
        borderRadius: BorderRadius.circular(context.m),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                widthFactor: progress, // تغییر طول بر اساس درصد پیشرفت
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary, // رنگ بخش پر شده
                    borderRadius: BorderRadius.circular(context.m),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
