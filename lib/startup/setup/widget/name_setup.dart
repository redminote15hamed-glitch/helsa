import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textboxer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class NameSetup extends StatelessWidget {
  final String currentLang;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;
  final VoidCallback onTextChanged;

  const NameSetup({
    super.key,
    required this.currentLang,
    required this.firstNameController,
    required this.lastNameController,
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    final double gapFields = context.vX2s;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Displayer(
          index: 2,
          template: MotionTemplate.bottomSlide,
          child: TextBoxer(
            controller: firstNameController,
            focusNode: firstNameFocus,
            hintText: SetupText.getString(currentLang, 'hint_first_name'),
            template: TextBoxTemplate.singleLine,
            textInputAction: TextInputAction.next,
            onChanged: (val) => onTextChanged(),
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(lastNameFocus);
            },
          ),
        ),
        SizedBox(height: gapFields),
        Displayer(
          index: 3,
          template: MotionTemplate.bottomSlide,
          child: TextBoxer(
            controller: lastNameController,
            focusNode: lastNameFocus,
            hintText: SetupText.getString(currentLang, 'hint_last_name'),
            template: TextBoxTemplate.singleLine,
            textInputAction: TextInputAction.done,
            onChanged: (val) => onTextChanged(),
            onSubmitted: (_) {
              lastNameFocus.unfocus();
            },
          ),
        ),
      ],
    );
  }
}
