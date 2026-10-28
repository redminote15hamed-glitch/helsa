// lib/home/services/daily_recap.dart
// گزارش روز قبل — TextFielder + جهت درست عدد/متن
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';

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
    final mins = (activeMs / 60000).floor();
    double cal = steps * 0.04;
    try {
      final w = BodyStore.weight ?? 70.0;
      cal = steps * 0.04 * (w / 70.0);
    } catch (_) {}

    final goalPct = (goal != null && goal > 0)
        ? ((steps / goal) * 100).clamp(0, 999).toStringAsFixed(0)
        : null;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
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
                Icon(Icons.auto_awesome, color: cs.primary),
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
                        ctx,
                        language,
                        Icons.directions_walk,
                        value: '$steps',
                        label: HomeText.getString(language, 'recap_steps'),
                      ),
                      const SizedBox(height: 10),
                      _metricLine(
                        ctx,
                        language,
                        Icons.local_fire_department,
                        value: cal.toStringAsFixed(0),
                        label: HomeText.getString(language, 'recap_cal'),
                      ),
                      const SizedBox(height: 10),
                      _metricLine(
                        ctx,
                        language,
                        Icons.timer_outlined,
                        value: '$mins',
                        label: HomeText.getString(language, 'recap_active'),
                      ),
                      if (goalPct != null) ...[
                        const SizedBox(height: 10),
                        _metricLine(
                          ctx,
                          language,
                          Icons.flag_outlined,
                          value: '$goalPct%',
                          label: HomeText.getString(language, 'recap_goal'),
                        ),
                      ],
                    ],
                  ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
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

  /// عدد و برچسب جدا تا در RTL جابه‌جا نشوند.
  static Widget _metricLine(
    BuildContext context,
    String language,
    IconData icon, {
    required String value,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
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
