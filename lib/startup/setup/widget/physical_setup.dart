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

    // الگوی خواب: ارتفاع لیست و فاصله‌ها از سیستم ریسپانسیو
    final double listHeight = context.vM;
    final double gapLabelList = context.vX3s;
    final double gapSections = context.vS;
    final double labelSize = context.baseScale * 0.95;

    Widget section({
      required String titleKey,
      required List<String> rawItems,
      required int initialIndex,
      required void Function(int index) onChanged,
    }) {
      final items = rawItems
          .map((value) => value == '----'
              ? value
              : value.toLocalizedDigits(context, languageCode: currentLang))
          .toList();

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Displayer(
            index: 2,
            template: MotionTemplate.leftSlide,
            child: TextFielder(
              text: SetupText.getString(currentLang, titleKey),
              template: TextTemplate.subtitle,
              textAlign: TextAlign.center,
              customStyle: TextStyle(
                fontSize: labelSize,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: gapLabelList),
          Displayer(
            index: 3,
            template: MotionTemplate.zoomFade,
            child: SizedBox(
              height: listHeight,
              child: ListViewer(
                items: items,
                languageCode: currentLang,
                initialIndex: initialIndex,
                isVertical: false,
                onSelectedItemChanged: onChanged,
              ),
            ),
          ),
        ],
      );
    }

    Widget divider() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hM),
        child: Container(
          width: double.infinity,
          height: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        section(
          titleKey: 'weight_title',
          rawItems: weightItems,
          initialIndex: initialWeightIndex,
          onChanged: (index) {
            if (index == 0) {
              onWeightChanged(null);
            } else {
              onWeightChanged(30 + (index - 1) * 0.1);
            }
          },
        ),
        SizedBox(height: gapSections),
        divider(),
        SizedBox(height: gapSections),
        section(
          titleKey: 'height_title',
          rawItems: heightItems,
          initialIndex: initialHeightIndex,
          onChanged: (index) {
            if (index == 0) {
              onHeightChanged(null);
            } else {
              onHeightChanged(50 + (index - 1).toDouble());
            }
          },
        ),
        SizedBox(height: gapSections),
        divider(),
        SizedBox(height: gapSections),
        section(
          titleKey: 'waist_title',
          rawItems: waistItems,
          initialIndex: initialWaistIndex,
          onChanged: (index) {
            if (index == 0) {
              onWaistChanged(null);
            } else {
              onWaistChanged(60 + (index - 1).toDouble());
            }
          },
        ),
      ],
    );
  }
}
