import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewbuttoner.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class DietSetup extends StatelessWidget {
  final String currentLang;
  final int? selectedDiet;
  final Function(int) onDietSelected;

  const DietSetup({
    super.key,
    required this.currentLang,
    this.selectedDiet,
    required this.onDietSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> diets = [
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'diet_omnivore',
        'desc': 'diet_desc_omnivore'
      },
      {
        'icon': Icons.egg,
        'title': 'diet_vegetarian',
        'desc': 'diet_desc_vegetarian'
      },
      {
        'icon': Icons.spa_rounded,
        'title': 'diet_vegan',
        'desc': 'diet_desc_vegan'
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'title': 'diet_keto',
        'desc': 'diet_desc_keto'
      },
      {
        'icon': Icons.fastfood_rounded,
        'title': 'diet_low_carb',
        'desc': 'diet_desc_low_carb'
      },
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // ─── متن راهنما (عنوان جدید) ───
        Displayer(
          index: 1,
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(currentLang, 'diet_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ),

        SizedBox(height: context.vS),

        // ─── لیست رژیم‌های غذایی ───
        Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: ListViewButtoner(
            items: diets.map((item) {
              return {
                'icon': item['icon'],
                'title': SetupText.getString(currentLang, item['title']),
                'desc': SetupText.getString(currentLang, item['desc']),
              };
            }).toList(),
            selectedIndex: selectedDiet,
            onSelected: onDietSelected,
            itemWidth: context.hX6l + context.hXl,
            itemHeight: context.vX4l,
            currentLang: currentLang,
          ),
        ),
      ],
    );
  }
}
