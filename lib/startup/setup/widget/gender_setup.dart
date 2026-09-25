import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class GenderSetup extends StatelessWidget {
  final String currentLang;
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderSetup({
    super.key,
    required this.currentLang,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double gapBetween = context.m;
    final double cardW = context.hX5l;
    final double cardH = context.vX4l;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Displayer(
              index: 1,
              template: MotionTemplate.flipY,
              child: _buildGenderOption(
                context,
                'female',
                Icons.female_rounded,
                cardW,
                cardH,
              ),
            ),
            SizedBox(width: gapBetween),
            Displayer(
              index: 1,
              template: MotionTemplate.flipYReverse,
              child: _buildGenderOption(
                context,
                'male',
                Icons.male_rounded,
                cardW,
                cardH,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(
    BuildContext context,
    String gender,
    IconData icon,
    double width,
    double height,
  ) {
    final bool isSelected = selectedGender == gender;
    final theme = Theme.of(context);
    final Color contentColor =
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return Buttoner(
      text: "",
      template: ButtonTemplate.squarePrimary,
      isSelected: isSelected,
      onTap: () => onGenderSelected(gender),
      customWidth: width,
      customHeight: height,
      child: ClipRect(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Iconer(
              icon: icon,
              template: IconTemplate.large,
              customColor: contentColor,
            ),
            SizedBox(height: context.vX3s),
            TextFielder(
              text: SetupText.getString(currentLang, 'gender_$gender'),
              template: TextTemplate.button,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              customStyle: TextStyle(
                color: contentColor,
                fontWeight: FontWeight.bold,
                fontSize: context.baseScale * 0.95,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
