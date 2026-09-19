import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/utils/farsi_digit.dart';
import 'package:helsa/setting/kit/textfielder.dart'; // حتما این را وارد کنید
import 'package:helsa/startup/setup/widget/setup_text.dart';

class AgeSetup extends StatelessWidget {
  final String currentLang;
  final int? selectedAge;
  final Function(int?) onAgeSelected;

  const AgeSetup({
    super.key,
    required this.currentLang,
    required this.selectedAge,
    required this.onAgeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> items = [
      '----',
      ...List.generate(
        99,
        (i) => (i + 1)
            .toString()
            .toLocalizedDigits(context, languageCode: currentLang),
      ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // متن اضافه شده به بالای لیست
        Displayer(
          index: 1,
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(currentLang, 'age_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ),

        SizedBox(height: context.vL),
        Displayer(
          index: 3,
          template: MotionTemplate.zoomFade,
          child: ListViewer(
            items: items,
            languageCode: currentLang,
            initialIndex: selectedAge ?? 0,
            isVertical: false,
            onSelectedItemChanged: (index) {
              onAgeSelected(index == 0 ? null : index);
            },
          ),
        ),
      ],
    );
  }
}
