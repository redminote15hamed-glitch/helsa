// lib/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:helsa/home/widgets/hex_activity_card.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/home/services/walking_notification.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/profile_store.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StepTracker _tracker = StepTracker.instance;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onUpdate);
    _tracker.init();
    WalkingNotification.instance.init();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tracker.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.profile;
    final name = [
      profile?['firstName']?.toString() ?? '',
      profile?['lastName']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).join(' ');
    final lang = profile?['language']?.toString() ?? 'en';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.hM,
            vertical: context.vS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFielder(
                text: name.isEmpty ? 'Helsa' : name,
                template: TextTemplate.title,
              ),
              SizedBox(height: context.vS),
              HexActivityCard(
                language: lang,
                steps: _tracker.steps,
                stepsGoal: _tracker.stepsGoal,
                calories: _tracker.calories,
                caloriesGoal: _tracker.caloriesGoal,
                activeMinutes: _tracker.activeMinutes,
                activeMinutesGoal: _tracker.activeMinutesGoal,
                activeTimeText:
                    '${_tracker.activeTimeLabel} / ${_tracker.activeMinutesGoal} ${lang.startsWith('fa') ? 'دقیقه' : 'min'}',
              ),
              if (!_tracker.permissionGranted) ...[
                SizedBox(height: context.vS),
                TextFielder(
                  text: _permText(lang),
                  template: TextTemplate.caption,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  child: Text(_settingsText(lang)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _permText(String lang) {
    if (lang.startsWith('fa')) {
      return 'برای شمارش واقعی قدم، دسترسی فعالیت بدنی را فعال کنید.';
    }
    if (lang.startsWith('fr')) {
      return 'Autorisez l’activité physique pour le compteur de pas.';
    }
    return 'Allow physical activity access for real step counting.';
  }

  String _settingsText(String lang) {
    if (lang.startsWith('fa')) return 'تنظیمات';
    if (lang.startsWith('fr')) return 'Réglages';
    return 'Settings';
  }
}
