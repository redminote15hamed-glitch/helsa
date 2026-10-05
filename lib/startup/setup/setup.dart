import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/device_modifier.dart';
import 'package:helsa/startup/setup/widget/language_select.dart';
import 'package:helsa/startup/setup/widget/name_setup.dart';
import 'package:helsa/startup/setup/widget/gender_setup.dart';
import 'package:helsa/startup/setup/widget/age_setup.dart';
import 'package:helsa/startup/setup/widget/physical_setup.dart';
import 'package:helsa/startup/setup/widget/activity_setup.dart';
import 'package:helsa/startup/setup/widget/diet_setup.dart';
import 'package:helsa/startup/setup/widget/restriction_setup.dart';
import 'package:helsa/startup/setup/widget/sleep_setup.dart';
import 'device/m_v.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  /// فقط این عدد را عوض کن وقتی استپ جدید (مثل حساسیت غذایی) اضافه شد
  static const int kTotalSetupSteps = 9; // + restriction

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

  void _onSkipRestrictions() {
    // نادیده گرفتن انتخاب‌ها و رفتن به استپ بعد
    setState(() {
      _selectedRestrictions.clear();
      if (_currentStep < kTotalSetupSteps - 1) {
        _currentStep++;
      }
    });
  }

  Future<void> _onContinuePressed() async {
    FocusScope.of(context).unfocus();

    if (_currentStep == 1) {
      await Future.delayed(const Duration(milliseconds: 280));
    }
    if (!mounted) return;

    if (_currentStep < kTotalSetupSteps - 1) {
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
    switch (_currentStep) {
      case 0:
        return _hasUserSelected;
      case 1:
        return _isNameFilled;
      case 2:
        return _selectedGender != null;
      case 3:
        return _selectedAge != null;
      case 4:
        return _selectedHeight != null &&
            _selectedWeight != null &&
            _selectedWaist != null;
      case 5:
        return _selectedActivityLevel != null;
      case 6:
        return _selectedDiet != null;
      case 7:
        return _selectedRestrictions.isNotEmpty;
      case 8:
        return _selectedSleepTime != null && _selectedWakeTime != null;
      default:
        return false;
    }
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
          onAgeSelected: (age) => setState(() => _selectedAge = age),
        );

      case 4:
        return PhysicalSetup(
          key: const ValueKey(4),
          currentLang: lang,
          height: _selectedHeight,
          weight: _selectedWeight,
          waist: _selectedWaist,
          onHeightChanged: (v) => setState(() => _selectedHeight = v),
          onWeightChanged: (v) => setState(() => _selectedWeight = v),
          onWaistChanged: (v) => setState(() => _selectedWaist = v),
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
        return RestrictionSetup(
          key: const ValueKey(7),
          currentLang: lang,
          selectedRestrictions: List<int>.from(_selectedRestrictions),
          onChanged: (list) => setState(() {
            _selectedRestrictions
              ..clear()
              ..addAll(list);
          }),
        );

      case 8:
        return SleepWakeSetup(
          key: const ValueKey(8),
          currentLang: lang,
          selectedSleepTime: _selectedSleepTime,
          selectedWakeTime: _selectedWakeTime,
          onSleepTimeSelected: (time) {
            setState(() => _selectedSleepTime = time);
          },
          onWakeTimeSelected: (time) {
            setState(() => _selectedWakeTime = time);
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
        resizeToAvoidBottomInset: false,
        body: DeviceModifier(
          defaultVertical: SetupMobileVertical(
            currentStep: _currentStep,
            totalSteps: kTotalSetupSteps,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            showSkip: _currentStep == 7,
            onSkip: _currentStep == 7 ? _onSkipRestrictions : null,
            buildStepContent: _buildStepContent,
          ),
          mobileVertical: SetupMobileVertical(
            currentStep: _currentStep,
            totalSteps: kTotalSetupSteps,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            showSkip: _currentStep == 7,
            onSkip: _currentStep == 7 ? _onSkipRestrictions : null,
            buildStepContent: _buildStepContent,
          ),
          defaultHorizontal: SetupMobileVertical(
            currentStep: _currentStep,
            totalSteps: kTotalSetupSteps,
            currentLang: currentLang,
            isStepValid: _isStepValid,
            onBackPressed: _handleBack,
            onContinuePressed: _onContinuePressed,
            showSkip: _currentStep == 7,
            onSkip: _currentStep == 7 ? _onSkipRestrictions : null,
            buildStepContent: _buildStepContent,
          ),
        ),
      ),
    );
  }
}
