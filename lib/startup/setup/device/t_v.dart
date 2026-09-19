// فایل: lib/startup/language/device/t_v.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/workspace_area.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class SetupTabletVertical extends StatefulWidget {
  const SetupTabletVertical({super.key});

  @override
  State<SetupTabletVertical> createState() => _SetupTabletVerticalState();
}

class _SetupTabletVerticalState extends State<SetupTabletVertical> {
  String _selectedLang = 'fa';
  bool _hasUserSelected = false;

  void _selectLanguage(String langCode) {
    setState(() {
      _selectedLang = langCode;
      _hasUserSelected = true;
    });
  }

  void _onContinuePressed() {
    if (!_hasUserSelected) return;
  }

  @override
  Widget build(BuildContext context) {
    final String currentLang = _selectedLang;

    return WorkspaceArea(
      isScrollable: true,
      child: Center(
        child: SizedBox(
          width: 420.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Iconer(
                icon: Icons.language_rounded,
                template: IconTemplate.giant,
              ),
              SizedBox(height: context.vXs),
              TextFielder(
                text: SetupText.getString(currentLang, 'title'),
                template: TextTemplate.title,
                textAlign: TextAlign.center,
              ),
              TextFielder(
                text: SetupText.getString(currentLang, 'subtitle'),
                template: TextTemplate.body,
                textAlign: TextAlign.center,
                customStyle: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
              SizedBox(height: context.vX2l),
              Buttoner(
                text: SetupText.getString(currentLang, 'btn_fr'),
                template: ButtonTemplate.primary,
                isSelected: _selectedLang == 'fr' && _hasUserSelected,
                onTap: () => _selectLanguage('fr'),
              ),
              SizedBox(height: context.vX4s),
              Buttoner(
                text: SetupText.getString(currentLang, 'btn_fa'),
                template: ButtonTemplate.primary,
                isSelected: _selectedLang == 'fa' && _hasUserSelected,
                onTap: () => _selectLanguage('fa'),
              ),
              SizedBox(height: context.vX4s),
              Buttoner(
                text: SetupText.getString(currentLang, 'btn_en'),
                template: ButtonTemplate.primary,
                isSelected: _selectedLang == 'en' && _hasUserSelected,
                onTap: () => _selectLanguage('en'),
              ),
              SizedBox(height: context.vXl),
              Buttoner(
                text: SetupText.getString(currentLang, 'continue'),
                template: ButtonTemplate.flatOnSurface,
                onTap: _hasUserSelected ? _onContinuePressed : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
