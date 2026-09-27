// lib/setting/responsive/workspace_area.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/responsive/deviceconfig.dart';

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

    final bottomNavHeight = MediaQuery.paddingOf(context).bottom;

    final EdgeInsets defaultPadding =
        (currentOrientation == DeviceOrientation.vertical)
            ? EdgeInsets.only(
                left: context.hSPlus,
                right: context.hSPlus,
                top: context.vX2s,
                bottom: context.vX5s,
              )
            : EdgeInsets.only(
                left: context.hSPlus,
                right: context.hSPlus,
                top: context.vX2s,
                bottom: context.vM,
              );

    final EdgeInsets effectivePadding = padding ?? defaultPadding;

    final double gradientExtraHeight = context.vL;
    final double totalGradientHeight = bottomNavHeight + gradientExtraHeight;

    final EdgeInsets scrollPadding = effectivePadding.copyWith(
      bottom: effectivePadding.bottom + totalGradientHeight,
    );

    return Scaffold(
      backgroundColor:
          backgroundColor ?? theme.colorScheme.surface.withValues(alpha: 0.0),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!isScrollable) {
                  return Padding(
                    padding: scrollPadding,
                    child: Center(child: child),
                  );
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: scrollPadding,
                      sliver: SliverToBoxAdapter(
                        child: child,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: totalGradientHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface.withValues(alpha: 0.0),
                      theme.colorScheme.surface.withValues(alpha: 0.15),
                      theme.colorScheme.surface.withValues(alpha: 0.40),
                      theme.colorScheme.surface.withValues(alpha: 0.75),
                      theme.colorScheme.surface.withValues(alpha: 0.96),
                    ],
                    stops: const [0.0, 0.20, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
