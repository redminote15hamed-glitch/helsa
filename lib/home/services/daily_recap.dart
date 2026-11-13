// lib/home/services/daily_recap.dart
// Previous-day recap dialog.
import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/home/services/goal_calculator.dart';

class DailyRecap {
  DailyRecap._();

  static Future<void> maybeShow(BuildContext context, String language) async {
    Map<String, dynamic>? data;
    try {
      data = StepsStore.consumePendingRecap();
    } catch (_) {
      return;
    }
    if (data == null || !context.mounted) return;

    final steps = data['steps'] as int? ?? 0;
    final activeMs = data['activeMs'] as int? ?? 0;
    final goal = data['goalSteps'] as int?;
    final minutes = (activeMs / 60000).floor();
    final estimatedMovementCalories = steps * GoalCalculator.kcalPerStep();

    final goalPercent = (goal != null && goal > 0)
        ? ((steps / goal) * 100).clamp(0, 999).toStringAsFixed(0)
        : null;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final isRtl = language.toLowerCase().startsWith('fa') ||
            language.toLowerCase().startsWith('ar');

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFielder(
                    text: HomeText.getString(language, 'recap_title'),
                    languageCode: language,
                    template: TextTemplate.title,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            content: steps <= 0
                ? TextFielder(
                    text: HomeText.getString(language, 'recap_empty'),
                    languageCode: language,
                    template: TextTemplate.body,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _metricLine(
                        dialogContext,
                        language,
                        Icons.directions_walk,
                        value: '$steps',
                        label: HomeText.getString(language, 'recap_steps'),
                      ),
                      const SizedBox(height: 10),
                      _metricLine(
                        dialogContext,
                        language,
                        Icons.local_fire_department,
                        value: estimatedMovementCalories.toStringAsFixed(0),
                        label: HomeText.getString(language, 'recap_cal'),
                      ),
                      const SizedBox(height: 10),
                      _metricLine(
                        dialogContext,
                        language,
                        Icons.timer_outlined,
                        value: '$minutes',
                        label: HomeText.getString(language, 'recap_active'),
                      ),
                      if (goalPercent != null) ...[
                        const SizedBox(height: 10),
                        _metricLine(
                          dialogContext,
                          language,
                          Icons.flag_outlined,
                          value: '$goalPercent%',
                          label: HomeText.getString(language, 'recap_goal'),
                        ),
                      ],
                    ],
                  ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: TextFielder(
                  text: HomeText.getString(language, 'recap_ok'),
                  languageCode: language,
                  template: TextTemplate.button,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _metricLine(
    BuildContext context,
    String language,
    IconData icon, {
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              TextFielder(
                text: value,
                languageCode: language,
                template: TextTemplate.body,
                customStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: TextFielder(
                  text: label,
                  languageCode: language,
                  template: TextTemplate.body,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
