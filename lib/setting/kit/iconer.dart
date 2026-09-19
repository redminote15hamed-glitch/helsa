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
  final double Function(BuildContext)
      size; // محاسبه پویا و ریسپانسیو ابعاد آیکون
  final Color Function(ThemeData)
      color; // مدیریت هوشمند رنگ بر اساس تم فعال (تاریک/روشن)

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

  const Iconer({
    super.key,
    required this.icon,
    this.template = IconTemplate.medium,
    this.customColor,
    this.customSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ۱. استخراج کانفیگ اختصاصی آیکون از ماتریس تنظیمات
    final IconConfig config = _getIconMatrix(template);

    return Icon(
      icon,
      // اولویت اول با سایز هاردکد شده دستی، اولویت دوم با مقدار ماتریس ریسپانسیو
      size: customSize ?? config.size(context),
      // اولویت اول با رنگ پاس داده شده دستی، اولویت دوم با پالت رنگی ماتریس
      color: customColor ?? config.color(theme),
    );
  }

  /// 📐 ماتریس مرکزی پیکربندی ابعاد و رنگ‌های آیکون در اپلیکیشن هلسا
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
