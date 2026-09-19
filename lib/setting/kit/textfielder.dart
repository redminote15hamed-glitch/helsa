// lib/setting/kit/textfielder.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/utils/farsi_digit.dart';

enum TextTemplate {
  headline, // عناوینی بسیار بزرگ ابتدای صفحات اصلی
  title, // عناوین استاندارد، هدر کامپوننت‌ها و کارت‌ها
  subtitle, // عناوین فرعی و توضیحات کوتاه
  body, // متن بدنه اصلی، پاراگراف‌ها و توضیحات طولانی
  button, // بهینه‌شده برای دکمه‌های اصلی
  caption, // متون بسیار ریز، راهنماها و ارورها
}

class FontConfig {
  final String fontFamily;
  final FontWeight fontWeight;
  final double Function(BuildContext) fontSize;
  final Color Function(ThemeData) color;
  final double Function(BuildContext) bottomSpacing;
  final double? height;
  final double? letterSpacing;

  const FontConfig({
    required this.fontFamily,
    required this.fontWeight,
    required this.fontSize,
    required this.color,
    required this.bottomSpacing,
    this.height,
    this.letterSpacing,
  });
}

class TextFielder extends StatelessWidget {
  final String text;
  final TextTemplate template;
  final String? languageCode;
  final TextStyle? customStyle;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDirection? textDirection;

  const TextFielder({
    super.key,
    required this.text,
    this.template = TextTemplate.body,
    this.languageCode,
    this.customStyle,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ۱. شناسایی زبان و تعیین جهت متن به صورت خودکار
    final String lang =
        (languageCode ?? Localizations.localeOf(context).languageCode)
            .toLowerCase();
    final bool isRtl = (lang == 'fa' || lang == 'ar');
    final TextDirection direction =
        textDirection ?? (isRtl ? TextDirection.rtl : TextDirection.ltr);

    // ۲. استخراج کانفیگ از ماتریس
    final FontConfig config = _getFontMatrix(context, lang, template);

    // ۳. ساخت استایل پایه
    final TextStyle baseStyle = TextStyle(
      fontFamily: config.fontFamily,
      fontWeight: config.fontWeight,
      fontSize: config.fontSize(context),
      color: config.color(theme),
      height: config.height,
      letterSpacing: config.letterSpacing,
    );

    // ۴. تعیین تراز هوشمند
    TextAlign defaultTextAlign = isRtl ? TextAlign.right : TextAlign.left;
    if (template == TextTemplate.body && isRtl) {
      defaultTextAlign = TextAlign.justify;
    } else if (template == TextTemplate.button) {
      defaultTextAlign = TextAlign.center;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: config.bottomSpacing(context)),
      child: Text(
        text.toLocalizedDigits(context, languageCode: lang),
        textAlign: textAlign ?? defaultTextAlign,
        style: baseStyle.merge(customStyle),
        textDirection: direction,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }

  FontConfig _getFontMatrix(
      BuildContext context, String lang, TextTemplate template) {
    final Map<TextTemplate, FontConfig> faMatrix = {
      TextTemplate.headline: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w900,
          fontSize: (c) => c.x3l,
          color: (t) => t.colorScheme.primary,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.title: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w800,
          fontSize: (c) => c.x2l,
          color: (t) => t.colorScheme.primary,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.subtitle: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w600,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.85),
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.body: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w400,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onSurface,
          height: 1.5,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.button: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w700,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onPrimary,
          bottomSpacing: (c) => 0.0),
      TextTemplate.caption: FontConfig(
          fontFamily: 'YekanBakh',
          fontWeight: FontWeight.w400,
          fontSize: (c) => c.s,
          color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.55),
          bottomSpacing: (c) => c.vX6s),
    };

    final Map<TextTemplate, FontConfig> enMatrix = {
      TextTemplate.headline: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w800,
          fontSize: (c) => c.x2l * 1.2,
          color: (t) => t.colorScheme.primary,
          letterSpacing: 0.5,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.title: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w900,
          fontSize: (c) => c.xl * 1.3,
          color: (t) => t.colorScheme.primary,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.subtitle: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w500,
          fontSize: (c) => c.s * 1.1,
          color: (t) => t.colorScheme.onSurface,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.body: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w400,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onSurface,
          height: 1.35,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.button: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onPrimary,
          letterSpacing: 0.75,
          bottomSpacing: (c) => 0.0),
      TextTemplate.caption: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w300,
          fontSize: (c) => c.s,
          color: (t) => t.colorScheme.onSurface,
          bottomSpacing: (c) => c.vX6s),
    };

    final Map<TextTemplate, FontConfig> frMatrix = {
      TextTemplate.headline: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w700,
          fontSize: (c) => c.x2l * 1.1,
          color: (t) => t.colorScheme.primary,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.title: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
          fontSize: (c) => c.xl * 1.1,
          color: (t) => t.colorScheme.primary,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.subtitle: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w500,
          fontSize: (c) => c.s * 1.05,
          color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.75),
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.body: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w400,
          fontSize: (c) => c.m,
          color: (t) => t.colorScheme.onSurface,
          height: 1.4,
          bottomSpacing: (c) => c.vX6s),
      TextTemplate.button: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w600,
          fontSize: (c) => c.m * 0.95,
          color: (t) => t.colorScheme.onPrimary,
          bottomSpacing: (c) => 0.0),
      TextTemplate.caption: FontConfig(
          fontFamily: 'Vazirmatn',
          fontWeight: FontWeight.w400,
          fontSize: (c) => c.s * 0.9,
          color: (t) => t.colorScheme.onSurface.withValues(alpha: 0.45),
          bottomSpacing: (c) => c.vX6s),
    };

    if (lang == 'fa' || lang == 'ar') return faMatrix[template]!;
    if (lang == 'fr') return frMatrix[template]!;
    return enMatrix[template]!;
  }
}
