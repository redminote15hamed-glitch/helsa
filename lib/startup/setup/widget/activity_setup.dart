import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewbuttoner.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class ActivitySetup extends StatelessWidget {
  final String currentLang;
  final int? selectedLevel;
  final Function(int) onActivitySelected;

  const ActivitySetup({
    super.key,
    required this.currentLang,
    this.selectedLevel,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> activities = [
      {
        'icon': Icons.chair_rounded,
        'title': 'activity_sedentary',
        'desc': 'activity_desc_sedentary'
      },
      {
        'icon': Icons.airline_seat_flat_rounded,
        'title': 'activity_light_very',
        'desc': 'activity_desc_light_very'
      },
      {
        'icon': Icons.directions_walk_rounded,
        'title': 'activity_light',
        'desc': 'activity_desc_light'
      },
      {
        'icon': Icons.sports_gymnastics_rounded,
        'title': 'activity_moderate',
        'desc': 'activity_desc_moderate'
      },
      {
        'icon': Icons.fitness_center_rounded,
        'title': 'activity_active',
        'desc': 'activity_desc_active'
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
            text: SetupText.getString(currentLang, 'activity_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ),

        SizedBox(height: context.vS),

        // ─── لیست فعالیت‌ها ───
        Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: ListViewButtoner(
            items: activities.map((item) {
              return {
                'icon': item['icon'],
                'title': SetupText.getString(currentLang, item['title']),
                'desc': SetupText.getString(currentLang, item['desc']),
              };
            }).toList(),
            selectedIndex: selectedLevel,
            onSelected: onActivitySelected,
            itemWidth: context.hX6l + context.hXl,
            itemHeight: context.vX4l,
            currentLang: currentLang,
          ),
        ),
      ],
    );
  }
}
