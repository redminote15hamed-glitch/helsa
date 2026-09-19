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
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Displayer(
              index: 1,
              template: MotionTemplate.flipY, // 👈 خانم به سمت چپ باز می‌شود
              child:
                  _buildGenderOption(context, 'female', Icons.female_rounded),
            ),
            SizedBox(width: context.m),
            Displayer(
              index: 1, // 👈 ایندکس یکسان برای همزمانی
              template:
                  MotionTemplate.flipYReverse, // 👈 آقا به سمت راست باز می‌شود
              child: _buildGenderOption(context, 'male', Icons.male_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(
      BuildContext context, String gender, IconData icon) {
    final bool isSelected = selectedGender == gender;
    final theme = Theme.of(context);
    final Color contentColor =
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return Buttoner(
      text: "",
      template: ButtonTemplate.squarePrimary,
      isSelected: isSelected,
      onTap: () => onGenderSelected(gender),
      customWidth: context.hX5l,
      customHeight: context.vX4l,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Iconer(
            icon: icon,
            template: IconTemplate.large,
            customColor: contentColor,
          ),
          SizedBox(height: context.x2s),
          TextFielder(
            text: SetupText.getString(currentLang, 'gender_$gender'),
            template: TextTemplate.button,
            customStyle: TextStyle(
              color: contentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
