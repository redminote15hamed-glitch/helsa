import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/listviewer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/utils/farsi_digit.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class PhysicalSetup extends StatelessWidget {
  final String currentLang;
  final double? height;
  final double? weight;
  final double? waist;
  final Function(double?) onHeightChanged;
  final Function(double?) onWeightChanged;
  final Function(double?) onWaistChanged;

  const PhysicalSetup({
    super.key,
    required this.currentLang,
    this.height,
    this.weight,
    this.waist,
    required this.onHeightChanged,
    required this.onWeightChanged,
    required this.onWaistChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weightItems = [
      '----',
      ...List.generate(
        1701,
        (index) => (30 + index * 0.5).toStringAsFixed(1),
      ),
    ];
    final heightItems = [
      '----',
      ...List.generate(
        181,
        (index) => (50 + index).toString(),
      ),
    ];
    final waistItems = [
      '----',
      ...List.generate(
        141,
        (index) => (60 + index).toString(),
      ),
    ];

    final int initialWeightIndex = weight != null
        ? 1 + ((weight! - 30.0) * 10).round().clamp(0, weightItems.length - 2)
        : 0;
    final int initialHeightIndex = height != null
        ? 1 + (height! - 50).round().clamp(0, heightItems.length - 2)
        : 0;
    final int initialWaistIndex = waist != null
        ? 1 + (waist! - 60).round().clamp(0, waistItems.length - 2)
        : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Displayer(
              index: 2,
              template: MotionTemplate.leftSlide,
              child: TextFielder(
                text: SetupText.getString(currentLang, 'weight_title'),
                template: TextTemplate.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.vX2s),
            Displayer(
              index: 3,
              template: MotionTemplate.zoomFade,
              child: SizedBox(
                height: context.vM,
                child: ListViewer(
                  items: weightItems
                      .map((value) => value == '----'
                          ? value
                          : value.toLocalizedDigits(context,
                              languageCode: currentLang))
                      .toList(),
                  languageCode: currentLang,
                  initialIndex: initialWeightIndex,
                  isVertical: false,
                  onSelectedItemChanged: (index) {
                    if (index == 0) {
                      onWeightChanged(null);
                    } else {
                      onWeightChanged(30 + (index - 1) * 0.1);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.vXs),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.vM),
          child: Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: context.vXs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Displayer(
              index: 2,
              template: MotionTemplate.leftSlide,
              child: TextFielder(
                text: SetupText.getString(currentLang, 'height_title'),
                template: TextTemplate.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.vX2s),
            Displayer(
              index: 3,
              template: MotionTemplate.zoomFade,
              child: SizedBox(
                height: context.vM,
                child: ListViewer(
                  items: heightItems
                      .map((value) => value == '----'
                          ? value
                          : value.toLocalizedDigits(context,
                              languageCode: currentLang))
                      .toList(),
                  languageCode: currentLang,
                  initialIndex: initialHeightIndex,
                  isVertical: false,
                  onSelectedItemChanged: (index) {
                    if (index == 0) {
                      onHeightChanged(null);
                    } else {
                      onHeightChanged(50 + (index - 1).toDouble());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.vXs),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.vM),
          child: Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: context.vXs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Displayer(
              index: 2,
              template: MotionTemplate.leftSlide,
              child: TextFielder(
                text: SetupText.getString(currentLang, 'waist_title'),
                template: TextTemplate.subtitle,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.vX2s),
            Displayer(
              index: 3,
              template: MotionTemplate.zoomFade,
              child: SizedBox(
                height: context.vM,
                child: ListViewer(
                  items: waistItems
                      .map((value) => value == '----'
                          ? value
                          : value.toLocalizedDigits(context,
                              languageCode: currentLang))
                      .toList(),
                  languageCode: currentLang,
                  initialIndex: initialWaistIndex,
                  isVertical: false,
                  onSelectedItemChanged: (index) {
                    if (index == 0) {
                      onWaistChanged(null);
                    } else {
                      onWaistChanged(60 + (index - 1).toDouble());
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
