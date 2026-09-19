// lib/startup/splash/widget/splash_object.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/motion/displayer.dart'; // کیت ورود
import 'package:helsa/setting/motion/concealer.dart'; // کیت خروج جدید
import 'package:helsa/startup/splash/widget/splash_text.dart';

class SplashObject extends StatelessWidget {
  final double? iconSize;
  final Color? color;

  const SplashObject({
    super.key,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final String currentLang = Localizations.localeOf(context).languageCode;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const Spacer(flex: 5),

        // آیکون قلب: با popIn وارد می‌شود / با پله آخر خروج (ردیف ۳) به صورت زوم محو می‌شود
        Concealer(
          index: 3,
          template: ConcealTemplate.zoomFade,
          child: Displayer(
            index: 1,
            template: MotionTemplate.popIn,
            child: Iconer(
              icon: Icons.favorite_outline_rounded,
              template: IconTemplate.giant,
              customColor: color,
              customSize: iconSize,
            ),
          ),
        ),
        SizedBox(height: context.vX3s),

        // عنوان اصلی: با flipY وارد می‌شود / همزمان با قلب (ردیف ۳) با افکت چپ غیب می‌شود
        Concealer(
          index: 3,
          template: ConcealTemplate.leftSlide,
          child: Displayer(
            index: 2,
            template: MotionTemplate.flipY,
            child: TextFielder(
              text: SplashText.getString(currentLang, 'title'),
              template: TextTemplate.title,
            ),
          ),
        ),

        // زیرعنوان: با bottomSlide وارد می‌شود / در پله دوم خروج (ردیف ۲) با افکت راست غیب می‌شود
        Concealer(
          index: 2,
          template: ConcealTemplate.rightSlide,
          child: Displayer(
            index: 3,
            template: MotionTemplate.bottomSlide,
            child: TextFielder(
              text: SplashText.getString(currentLang, 'subtitle'),
              template: TextTemplate.subtitle,
            ),
          ),
        ),
        const Spacer(flex: 5),

        // نسخه اپلیکیشن: با فید ساده وارد می‌شود / اولین المانی است که خروج را استارت می‌زند (ردیف ۱)
        SafeArea(
          top: false,
          child: Concealer(
            index: 1,
            template: ConcealTemplate.fade,
            child: Displayer(
              index: 4,
              template: MotionTemplate.fade,
              child: TextFielder(
                text: SplashText.getString(currentLang, 'version'),
                template: TextTemplate.caption,
                customStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
