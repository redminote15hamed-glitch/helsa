import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/startup/setup/widget/language_select.dart';
import 'package:helsa/startup/setup/widget/name_setup.dart';
import 'package:helsa/startup/setup/widget/gender_setup.dart';
import 'package:helsa/startup/setup/widget/age_setup.dart';
import 'package:helsa/startup/setup/widget/physical_setup.dart';
import 'package:helsa/startup/setup/widget/activity_setup.dart';
import 'package:helsa/startup/setup/widget/diet_setup.dart';
import 'package:helsa/startup/setup/widget/sleep_setup.dart';
import 'device/m_v.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String _selectedLang = 'fa';
  bool _hasUserSelected = false;
  int _currentStep = 0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();

  bool _isNameFilled = false;

  String? _selectedGender;
  int? _selectedAge;
  double? _selectedHeight;
  double? _selectedWeight;
  double? _selectedWaist;
  int? _selectedActivityLevel;
  int? _selectedDiet;
  final List<int> _selectedRestrictions = [];

  // متغیرهای مربوط به ساعت خواب و بیداری
  String? _selectedSleepTime;
  String? _selectedWakeTime;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  void _validateNameFields() {
    final bool currentlyFilled =
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;

    if (_isNameFilled != currentlyFilled) {
      setState(() => _isNameFilled = currentlyFilled);
    }
  }

  void _onContinuePressed() {
    if (_currentStep < 7) {
      setState(() => _currentStep++);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _isStepValid {
    return _currentStep == 0
        ? _hasUserSelected
        : _currentStep == 1
            ? _isNameFilled
            : _currentStep == 2
                ? (_selectedGender != null)
                : _currentStep == 3
                    ? (_selectedAge != null)
                    : _currentStep == 4
                        ? (_selectedHeight != null &&
                            _selectedWeight != null &&
                            _selectedWaist != null)
                        : _currentStep == 5
                            ? (_selectedActivityLevel != null)
                            : _currentStep == 6
                                ? (_selectedDiet != null)
                                : _currentStep == 7
                                    ? (_selectedSleepTime != null &&
                                        _selectedWakeTime != null)
                                    : false;
  }

  Widget _buildStepContent(String lang) {
    switch (_currentStep) {
      case 0:
        return LanguageSelect(
          key: const ValueKey(0),
          currentLang: lang,
          selectedLang: _selectedLang,
          hasUserSelected: _hasUserSelected,
          onLanguageSelected: (l) => setState(() {
            _selectedLang = l;
            _hasUserSelected = true;
          }),
        );

      case 1:
        return NameSetup(
          key: const ValueKey(1),
          currentLang: lang,
          firstNameController: _firstNameController,
          lastNameController: _lastNameController,
          firstNameFocus: _firstNameFocus,
          lastNameFocus: _lastNameFocus,
          onTextChanged: _validateNameFields,
        );

      case 2:
        return GenderSetup(
          key: const ValueKey(2),
          currentLang: lang,
          selectedGender: _selectedGender,
          onGenderSelected: (g) => setState(() => _selectedGender = g),
        );

      case 3:
        return AgeSetup(
          key: const ValueKey(3),
          currentLang: lang,
          selectedAge: _selectedAge,
          onAgeSelected: (a) => setState(() => _selectedAge = a),
        );

      case 4:
        return PhysicalSetup(
          key: const ValueKey(4),
          currentLang: lang,
          height: _selectedHeight,
          weight: _selectedWeight,
          waist: _selectedWaist,
          onHeightChanged: (value) => setState(() => _selectedHeight = value),
          onWeightChanged: (value) => setState(() => _selectedWeight = value),
          onWaistChanged: (value) => setState(() => _selectedWaist = value),
        );

      case 5:
        return ActivitySetup(
          key: const ValueKey(5),
          currentLang: lang,
          selectedLevel: _selectedActivityLevel,
          onActivitySelected: (index) =>
              setState(() => _selectedActivityLevel = index),
        );

      case 6:
        return DietSetup(
          key: const ValueKey(6),
          currentLang: lang,
          selectedDiet: _selectedDiet,
          onDietSelected: (index) => setState(() => _selectedDiet = index),
        );

      case 7:
        return SleepWakeSetup(
          key: const ValueKey(7),
          currentLang: lang,
          selectedSleepTime: _selectedSleepTime,
          selectedWakeTime: _selectedWakeTime,
          onSleepTimeSelected: (time) {
            setState(() {
              _selectedSleepTime = time;
            });
          },
          onWakeTimeSelected: (time) {
            setState(() {
              _selectedWakeTime = time;
            });
          },
        );

      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentLang = _selectedLang;

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: DeviceModifier(
          defaultVertical: SetupMobileVertical(
            currentStep: _currentStep,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            buildStepContent: _buildStepContent,
          ),
          mobileVertical: SetupMobileVertical(
            currentStep: _currentStep,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            buildStepContent: _buildStepContent,
          ),
          defaultHorizontal: SetupMobileVertical(
            currentStep: _currentStep,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            buildStepContent: _buildStepContent,
          ),
        ),
      ),
    );
  }
}
