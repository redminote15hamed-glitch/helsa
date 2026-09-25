import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/utils/farsi_digit.dart';
import 'package:helsa/setting/kit/textfielder.dart';
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

    // ارتفاع لیست افقی وابسته به صفحه (مثل SleepWakeSetup)
    final double listHeight = context.vM;
    final double gapAfterSubtitle = context.vS;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Displayer(
          index: 1,
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(currentLang, 'age_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.60),
              fontSize: context.baseScale * 0.95,
            ),
          ),
        ),

        SizedBox(height: gapAfterSubtitle),

        Displayer(
          index: 3,
          template: MotionTemplate.zoomFade,
          child: SizedBox(
            height: listHeight,
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
        ),
      ],
    );
  }
}
