import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class TitleSetup extends StatelessWidget {
  final String currentLang;
  final int step; // 0: زبان، 1: نام، 2: جنسیت، 3: سن

  const TitleSetup({
    super.key,
    required this.currentLang,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String textKey;

    switch (step) {
      case 0:
        icon = Icons.language_rounded;
        textKey = 'title';
        break;
      case 1:
        icon = Icons.person_rounded;
        textKey = 'familiarity_title';
        break;
      case 2:
        icon = Icons.transgender_rounded;
        textKey = 'gender_title';
        break;
      case 3:
        icon = Icons.cake_rounded; // آیکون سن
        textKey = 'age_title'; // کلید جدید در SetupText
        break;
      case 4:
        icon =
            Icons.self_improvement_rounded; // آیکون مناسب‌تر برای فیزیک جسمانی
        textKey = 'physical_data_title';
        break;
      case 5:
        icon = Icons.fitness_center_rounded; // آیکون مرحله فعالیت
        textKey = 'activity_title';
        break;
      case 6:
        icon = Icons.restaurant_menu_rounded; // آیکون مرحله رژیم غذایی
        textKey = 'diet_title';
        break;
      case 7:
        icon = Icons.food_bank; // آیکون مرحله حساسیت غذایی
        textKey = 'restriction_title';
        break;
      default:
        icon = Icons.info_rounded;
        textKey = 'title';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Displayer(
            index: 0,
            template: MotionTemplate.zoomFade,
            child: Iconer(icon: icon, template: IconTemplate.giant)),
        SizedBox(height: context.vX2s),
        Displayer(
          index: 1,
          template: MotionTemplate.flipX,
          child: TextFielder(
            text: SetupText.getString(currentLang, textKey),
            template: TextTemplate.title,
            textAlign: TextAlign.center,
            customStyle:
                TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
