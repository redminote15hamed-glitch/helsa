// lib/setting/responsive/workspace_area.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/device_config.dart';

class WorkspaceArea extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool isScrollable;
  final EdgeInsets? padding;

  const WorkspaceArea({
    super.key,
    required this.child,
    this.backgroundColor,
    this.isScrollable = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentOrientation = DeviceConfig.getOrientation(context);

    // محاسبه پدینگ پیش‌فرض تمیزتر بر اساس جهت صفحه
    final EdgeInsets effectivePadding = padding ??
        (currentOrientation == DeviceOrientation.vertical
            ? EdgeInsets.only(
                left: context.hSPlus,
                right: context.hSPlus,
                top: context.vX2s,
                bottom: context.vS,
              )
            : EdgeInsets.only(
                left: context.hSPlus,
                right: context.hSPlus,
                top: context.vX2s,
                bottom: context.vM,
              ));

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!isScrollable) {
              return Padding(
                padding: effectivePadding,
                child: Center(child: child),
              );
            }

            // استفاده از سیستم Sliver برای مدیریت حرفه‌ای اسکرول و جلوگیری از Overflow
            return CustomScrollView(
              physics: const BouncingScrollPhysics(), // فیزیک نرم و نیتیو
              slivers: [
                SliverPadding(
                  padding: effectivePadding,
                  sliver: SliverFillRemaining(
                    hasScrollBody:
                        false, // اجازه می‌دهد محتوای کوچک فیت صفحه بماند
                    child: Center(child: child),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
