import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';

enum ButtonTemplate {
  primary,
  flatPrimary,
  flatOnSurface,
  secondary,
  textOnly,
  squarePrimary, // قالب جدید برای دکمه‌های با ابعاد سفارشی
}

class ButtonConfig {
  final Color Function(ThemeData, bool) backgroundColor;
  final Color Function(ThemeData, bool) textColor;
  final Border? Function(ThemeData, bool) border;
  final double Function(BuildContext) width;
  final double Function(BuildContext) height;
  final double Function(BuildContext) borderRadius;

  const ButtonConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.border,
    required this.width,
    required this.height,
    required this.borderRadius,
  });
}

class Buttoner extends StatelessWidget {
  final String text;
  final ButtonTemplate template;
  final bool isSelected;
  final VoidCallback? onTap;

  final Widget? child; // استفاده برای جایگذاری آیکون و TextFielder
  final double? customWidth;
  final double? customHeight;

  const Buttoner({
    super.key,
    required this.text,
    required this.template,
    this.isSelected = true,
    required this.onTap,
    this.child,
    this.customWidth,
    this.customHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ButtonConfig config = _getButtonMatrix(template);

    final bool isEnabled = onTap != null;
    final bg = config.backgroundColor(theme, isSelected && isEnabled);
    final textStyleColor = config.textColor(theme, isSelected && isEnabled);
    final currentBorder = config.border(theme, isSelected && isEnabled);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.zero,
      width: customWidth ?? config.width(context),
      height: customHeight ?? config.height(context),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(config.borderRadius(context)),
        border: currentBorder,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(config.borderRadius(context)),
          splashColor: textStyleColor.withValues(alpha: 0.12),
          highlightColor: textStyleColor.withValues(alpha: 0.06),
          child: Center(
            // اگر child ارسال نشود، از TextFielder استاندارد استفاده می‌کند
            child: child ??
                TextFielder(
                  text: text,
                  template: TextTemplate.button,
                  customStyle: TextStyle(
                    color: textStyleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  ButtonConfig _getButtonMatrix(ButtonTemplate template) {
    // تابع کمکی برای استایل‌های Primary و Square
    ButtonConfig primaryBase = ButtonConfig(
      backgroundColor: (t, s) =>
          s ? t.colorScheme.primary : t.colorScheme.primary.withValues(alpha: 0.09),
      textColor: (t, s) => s ? t.colorScheme.onPrimary : t.colorScheme.primary,
      border: (t, s) => Border.all(
        color:
            s ? t.colorScheme.primary : t.colorScheme.primary.withValues(alpha: 0.2),
        width: s ? 1.5 : 0.8,
      ),
      width: (c) => c.screenWidth * 0.75,
      height: (c) => c.vM,
      borderRadius: (c) => c.m,
    );

    switch (template) {
      case ButtonTemplate.squarePrimary:
        return primaryBase;
      case ButtonTemplate.primary:
        return primaryBase;
      case ButtonTemplate.flatPrimary:
        return ButtonConfig(
          backgroundColor: (t, e) => e
              ? t.colorScheme.primary
              : t.colorScheme.onSurface.withValues(alpha: 0.12),
          textColor: (t, e) => e
              ? t.colorScheme.onPrimary
              : t.colorScheme.onSurface.withValues(alpha: 0.35),
          border: (t, e) => null,
          width: (c) => c.screenWidth * 0.75,
          height: (c) => c.vM,
          borderRadius: (c) => c.m,
        );
      case ButtonTemplate.flatOnSurface:
        return ButtonConfig(
          backgroundColor: (t, e) => e
              ? t.colorScheme.onSurface
              : t.colorScheme.onSurface.withValues(alpha: 0.12),
          textColor: (t, e) => e
              ? t.colorScheme.surface
              : t.colorScheme.onSurface.withValues(alpha: 0.35),
          border: (t, e) => null,
          width: (c) => c.screenWidth * 0.75,
          height: (c) => c.vM,
          borderRadius: (c) => c.m,
        );
      case ButtonTemplate.secondary:
        return ButtonConfig(
          backgroundColor: (t, s) => s
              ? t.colorScheme.onSurface.withValues(alpha: 0.05)
              : Colors.transparent,
          textColor: (t, s) => t.colorScheme.onSurface,
          border: (t, s) => Border.all(
              color: s ? t.colorScheme.primary : t.colorScheme.outline,
              width: s ? 1.5 : 0.8),
          width: (c) => c.screenWidth * 0.75,
          height: (c) => c.vM,
          borderRadius: (c) => c.m,
        );
      case ButtonTemplate.textOnly:
        return ButtonConfig(
          backgroundColor: (t, s) => Colors.transparent,
          textColor: (t, s) => s
              ? t.colorScheme.primary
              : t.colorScheme.onSurface.withValues(alpha: 0.6),
          border: (t, s) => null,
          width: (c) => c.screenWidth * 0.5,
          height: (c) => c.vS,
          borderRadius: (c) => c.s,
        );
    }
  }
}
