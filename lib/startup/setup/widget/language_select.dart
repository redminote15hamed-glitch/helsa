// فایل: lib/startup/setup/widget/language_select.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/motion/displayer.dart'; // 👈 ایمپورت کیت انیمیشن موشن
import 'package:helsa/startup/setup/widget/setup_text.dart';

class LanguageSelect extends StatelessWidget {
  final String currentLang;
  final String selectedLang;
  final bool hasUserSelected;
  final ValueChanged<String> onLanguageSelected;

  const LanguageSelect({
    super.key,
    required this.currentLang,
    required this.selectedLang,
    required this.hasUserSelected,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // ─── انیمیشن متن راهنما (ساب‌تایتل) ───
        Displayer(
          index: 2, // شروع توالی بعد از عنوان اصلی صفحه
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(currentLang, 'subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ),

        SizedBox(height: context.vXs),

        // ─── انیمیشن دکمه فرانسوی ───
        Displayer(
          index: 3,
          template: MotionTemplate.bottomSlide,
          child: Buttoner(
            text: SetupText.getString(currentLang, 'btn_fr'),
            template: ButtonTemplate.primary,
            isSelected: selectedLang == 'fr' && hasUserSelected,
            onTap: () => onLanguageSelected('fr'),
          ),
        ),
        SizedBox(height: context.vX2s),
        // ─── انیمیشن دکمه فارسی ───
        Displayer(
          index: 4,
          template: MotionTemplate.bottomSlide,
          child: Buttoner(
            text: SetupText.getString(currentLang, 'btn_fa'),
            template: ButtonTemplate.primary,
            isSelected: selectedLang == 'fa' && hasUserSelected,
            onTap: () => onLanguageSelected('fa'),
          ),
        ),
        SizedBox(height: context.vX2s),
        // ─── انیمیشن دکمه انگلیسی ───
        Displayer(
          index: 5,
          template: MotionTemplate.bottomSlide,
          child: Buttoner(
            text: SetupText.getString(currentLang, 'btn_en'),
            template: ButtonTemplate.primary,
            isSelected: selectedLang == 'en' && hasUserSelected,
            onTap: () => onLanguageSelected('en'),
          ),
        ),
      ],
    );
  }
}
