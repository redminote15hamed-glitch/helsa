// lib/setting/kit/iconer.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

enum IconTemplate {
  giant, // آیکون‌های بسیار بزرگ (مثل صفحه اسپلش یا هدرهای خاص)
  large, // آیکون‌های بزرگ برای کارت‌ها و بخش‌های اصلی
  medium, // سایز استاندارد اپلیکیشن برای منوها و لیست‌ها
  small, // آیکون‌های کوچک برای دراپ‌داون‌ها و فیلدهای متنی
  micro, // آیکون‌های مینیاتوری در کنار متون راهنما و کپشن‌ها
}

/// شناسنامه مشخصات اندازه و رنگ آیکون
class IconConfig {
  final double Function(BuildContext) size;
  final Color Function(ThemeData) color;

  const IconConfig({
    required this.size,
    required this.color,
  });
}

class Iconer extends StatelessWidget {
  final IconData icon;
  final IconTemplate template;
  final Color? customColor;
  final double? customSize;

  /// گرادیان از رنگ اصلی → نسخه روشن‌تر (alpha کمتر)
  /// پیش‌فرض: true وقتی رنگ از تم primary می‌آید
  final bool? useGradient;

  /// شفافیت رنگ دوم گرادیان (۰–۱)
  final double gradientAlpha;

  const Iconer({
    super.key,
    required this.icon,
    this.template = IconTemplate.medium,
    this.customColor,
    this.customSize,
    this.useGradient,
    this.gradientAlpha = 0.55,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final IconConfig config = _getIconMatrix(template);
    final double size = customSize ?? config.size(context);
    final Color base = customColor ?? config.color(theme);

    // گرادیان: پیش‌فرض برای primaryهای تم؛ برای onSurface اختیاری
    final bool gradient = useGradient ??
        (customColor == null &&
            (template == IconTemplate.giant ||
                template == IconTemplate.large ||
                base == theme.colorScheme.primary));

    final iconWidget = Icon(
      icon,
      size: size,
      // ShaderMask با srcIn به رنگ سفید نیاز دارد
      color: gradient ? Colors.white : base,
    );

    if (!gradient) return iconWidget;

    final Color end = base.withValues(alpha: gradientAlpha);

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, end],
        ).createShader(bounds);
      },
      child: iconWidget,
    );
  }

  IconConfig _getIconMatrix(IconTemplate template) {
    final Map<IconTemplate, IconConfig> matrix = {
      IconTemplate.giant: IconConfig(
        size: (c) => c.x4l,
        color: (t) => t.colorScheme.primary,
      ),
      IconTemplate.large: IconConfig(
        size: (c) => c.x2l,
        color: (t) => t.colorScheme.primary,
      ),
      IconTemplate.medium: IconConfig(
        size: (c) => c.l,
        color: (t) => t.colorScheme.onSurface,
      ),
      IconTemplate.small: IconConfig(
        size: (c) => c.m,
        color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      IconTemplate.micro: IconConfig(
        size: (c) => c.s,
        color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    };

    return matrix[template]!;
  }
}
