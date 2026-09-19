// فایل: lib/setting/kit/circle_inkwell.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';

class CircleInkWell extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final IconTemplate iconTemplate;
  final Color? iconColor;
  final Color? splashColor;

  const CircleInkWell({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconTemplate = IconTemplate.medium,
    this.iconColor,
    this.splashColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEnabled = onTap != null;

    // تعیین رنگ آیکون بر اساس وضعیت فعال/غیرفعال بودن دکمه
    final Color effectiveColor = iconColor ??
        (isEnabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.38));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // ─── محدود کردن افکت ریپل به یک دایره کامل ───
        customBorder: const CircleBorder(),
        splashColor: splashColor ?? effectiveColor.withValues(alpha: 0.12),
        highlightColor: splashColor ?? effectiveColor.withValues(alpha: 0.06),
        child: Padding(
          // ایجاد فضای کلیک استاندارد و متناسب دور آیکون
          padding: const EdgeInsets.all(8.0),
          child: Iconer(
            icon: icon,
            template: iconTemplate,
            customColor: effectiveColor,
          ),
        ),
      ),
    );
  }
}
