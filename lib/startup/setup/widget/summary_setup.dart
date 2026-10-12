// lib/startup/setup/widget/summary_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';
import 'package:helsa/startup/setup/widget/restriction_setup.dart';
import 'package:helsa/startup/setup/widget/favorite_food_setup.dart';

/// Final review of onboarding choices before starting the app.
class SummarySetup extends StatelessWidget {
  final String currentLang;
  final String firstName;
  final String lastName;
  final String? gender;
  final int? age;
  final double? height;
  final double? weight;
  final double? waist;
  final int? activityLevel;
  final int? diet;
  final List<int> restrictions;
  final List<int> favorites;
  final String? sleepTime;
  final String? wakeTime;

  const SummarySetup({
    super.key,
    required this.currentLang,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.waist,
    required this.activityLevel,
    required this.diet,
    required this.restrictions,
    required this.favorites,
    required this.sleepTime,
    required this.wakeTime,
  });

  String _dash(String? v) =>
      (v == null || v.trim().isEmpty) ? '—' : v.trim();

  String _genderLabel() {
    if (gender == null) return '—';
    if (gender == 'female' || gender == 'f') {
      return SetupText.getString(currentLang, 'gender_female');
    }
    if (gender == 'male' || gender == 'm') {
      return SetupText.getString(currentLang, 'gender_male');
    }
    return gender!;
  }

  String _activityLabel() {
    const keys = [
      'activity_sedentary',
      'activity_light_very',
      'activity_light',
      'activity_moderate',
      'activity_active',
    ];
    if (activityLevel == null ||
        activityLevel! < 0 ||
        activityLevel! >= keys.length) {
      return '—';
    }
    return SetupText.getString(currentLang, keys[activityLevel!]);
  }

  String _dietLabel() {
    const keys = [
      'diet_omnivore',
      'diet_vegetarian',
      'diet_vegan',
      'diet_keto',
      'diet_low_carb',
    ];
    if (diet == null || diet! < 0 || diet! >= keys.length) return '—';
    return SetupText.getString(currentLang, keys[diet!]);
  }

  String _labelsFromMaps(
    List<int> ids,
    List<Map<String, dynamic>> source,
  ) {
    if (ids.isEmpty) return '—';
    final labels = <String>[];
    for (final id in ids) {
      for (final m in source) {
        if (m['id'] == id) {
          labels.add(
            SetupText.getString(currentLang, m['title'] as String),
          );
          break;
        }
      }
    }
    if (labels.isEmpty) return '—';
    if (labels.length <= 3) return labels.join(' · ');
    return '${labels.take(3).join(' · ')} +${labels.length - 3}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = '${firstName.trim()} ${lastName.trim()}'.trim();

    final rows = <_SummaryRowData>[
      _SummaryRowData(
        Icons.person_rounded,
        'summary_name',
        _dash(name.isEmpty ? null : name),
      ),
      _SummaryRowData(
        Icons.wc_rounded,
        'summary_gender',
        _genderLabel(),
      ),
      _SummaryRowData(
        Icons.cake_rounded,
        'summary_age',
        age != null ? '$age' : '—',
      ),
      _SummaryRowData(
        Icons.height_rounded,
        'summary_height',
        height != null ? '${height!.toStringAsFixed(0)} cm' : '—',
      ),
      _SummaryRowData(
        Icons.monitor_weight_rounded,
        'summary_weight',
        weight != null ? '${weight!.toStringAsFixed(1)} kg' : '—',
      ),
      _SummaryRowData(
        Icons.straighten_rounded,
        'summary_waist',
        waist != null ? '${waist!.toStringAsFixed(0)} cm' : '—',
      ),
      _SummaryRowData(
        Icons.fitness_center_rounded,
        'summary_activity',
        _activityLabel(),
      ),
      _SummaryRowData(
        Icons.restaurant_menu_rounded,
        'summary_diet',
        _dietLabel(),
      ),
      _SummaryRowData(
        Icons.health_and_safety_rounded,
        'summary_restrictions',
        _labelsFromMaps(restrictions, RestrictionSetup.items),
      ),
      _SummaryRowData(
        Icons.favorite_rounded,
        'summary_favorites',
        _labelsFromMaps(favorites, FavoriteFoodSetup.items),
      ),
      _SummaryRowData(
        Icons.bedtime_rounded,
        'summary_sleep',
        sleepTime != null && wakeTime != null
            ? '$sleepTime → $wakeTime'
            : '—',
      ),
    ];

    return Displayer(
      index: 2,
      template: MotionTemplate.bottomSlide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFielder(
            text: SetupText.getString(currentLang, 'summary_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              fontSize: context.baseScale * 0.95,
            ),
          ),
          SizedBox(height: context.vS),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(context.m),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: context.baseScale * 0.06,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  _SummaryTile(data: rows[i], currentLang: currentLang),
                  if (i < rows.length - 1)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.08),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRowData {
  final IconData icon;
  final String labelKey;
  final String value;

  const _SummaryRowData(this.icon, this.labelKey, this.value);
}

class _SummaryTile extends StatelessWidget {
  final _SummaryRowData data;
  final String currentLang;

  const _SummaryTile({
    required this.data,
    required this.currentLang,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hS,
        vertical: context.vX2s,
      ),
      child: Row(
        children: [
          Iconer(
            icon: data.icon,
            template: IconTemplate.small,
            customColor: theme.colorScheme.primary,
            useGradient: false,
          ),
          SizedBox(width: context.hX2s),
          Expanded(
            flex: 2,
            child: TextFielder(
              text: SetupText.getString(currentLang, data.labelKey),
              template: TextTemplate.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              customStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontSize: context.s,
              ),
            ),
          ),
          SizedBox(width: context.hX3s),
          Expanded(
            flex: 3,
            child: TextFielder(
              text: data.value,
              template: TextTemplate.body,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              customStyle: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: context.m * 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
