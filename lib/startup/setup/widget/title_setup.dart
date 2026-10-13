// lib/startup/setup/widget/title_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class TitleSetup extends StatelessWidget {
  final String currentLang;
  final int step;

  const TitleSetup({
    super.key,
    required this.currentLang,
    required this.step,
  });

  static const Map<int, (IconData, String)> _map = {
    0: (Icons.language_rounded, 'title'),
    1: (Icons.person_rounded, 'familiarity_title'),
    2: (Icons.transgender_rounded, 'gender_title'),
    3: (Icons.cake_rounded, 'age_title'),
    4: (Icons.self_improvement_rounded, 'physical_data_title'),
    5: (Icons.fitness_center_rounded, 'activity_title'),
    6: (Icons.restaurant_menu_rounded, 'diet_title'),
    7: (Icons.health_and_safety_rounded, 'restriction_title'),
    8: (Icons.favorite_rounded, 'favorite_food_title'),
    9: (Icons.nightlight_round, 'sleep_title'),
    10: (Icons.fact_check_rounded, 'summary_title'),
  };

  @override
  Widget build(BuildContext context) {
    final entry = _map[step] ?? (Icons.fact_check_rounded, 'summary_title');
    final IconData icon = entry.$1;
    final String textKey = entry.$2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Displayer(
          index: 0,
          template: MotionTemplate.zoomFade,
          child: Iconer(
            key: ValueKey('title_icon_$step'),
            icon: icon,
            template: IconTemplate.giant,
          ),
        ),
        SizedBox(height: context.vX3s),
        Displayer(
          index: 1,
          template: MotionTemplate.flipX,
          child: TextFielder(
            key: ValueKey('title_text_$step'),
            text: SetupText.getString(currentLang, textKey),
            template: TextTemplate.title,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
