import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textboxer.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class NameSetup extends StatelessWidget {
  final String currentLang;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;

  // 👇 اضافه شده
  final FocusNode firstNameFocus;
  final FocusNode lastNameFocus;

  final VoidCallback onTextChanged;

  const NameSetup({
    super.key,
    required this.currentLang,
    required this.firstNameController,
    required this.lastNameController,

    // 👇 اضافه شده
    required this.firstNameFocus,
    required this.lastNameFocus,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Displayer(
          index: 2,
          template: MotionTemplate.bottomSlide,
          child: TextBoxer(
            controller: firstNameController,

            // 👇 فوکوس نام
            focusNode: firstNameFocus,

            hintText: SetupText.getString(
              currentLang,
              'hint_first_name',
            ),

            template: TextBoxTemplate.singleLine,

            // دکمه Next روی کیبورد
            textInputAction: TextInputAction.next,

            onChanged: (val) => onTextChanged(),

            // 👇 با زدن Next مستقیم برو روی نام خانوادگی
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(lastNameFocus);
            },
          ),
        ),
        SizedBox(height: context.vX4s),
        Displayer(
          index: 3,
          template: MotionTemplate.bottomSlide,
          child: TextBoxer(
            controller: lastNameController,

            // 👇 فوکوس نام خانوادگی
            focusNode: lastNameFocus,

            hintText: SetupText.getString(
              currentLang,
              'hint_last_name',
            ),

            template: TextBoxTemplate.singleLine,

            // دکمه Done روی کیبورد
            textInputAction: TextInputAction.done,

            onChanged: (val) => onTextChanged(),

            // 👇 بستن کیبورد
            onSubmitted: (_) {
              lastNameFocus.unfocus();
            },
          ),
        ),
      ],
    );
  }
}
