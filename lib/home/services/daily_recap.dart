// lib/home/services/daily_recap.dart
// گزارش روز قبل — فقط یک‌بار بعد از عوض شدن روز
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';

class DailyRecap {
  DailyRecap._();

  /// اگر گزارش آماده‌باشد نشان می‌دهد و مصرف می‌کند
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

    final goalLine = goal != null && goal > 0
        ? '${((steps / goal) * 100).clamp(0, 999).toStringAsFixed(0)}% ${HomeText.getString(language, 'recap_goal')}'
        : null;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(HomeText.getString(language, 'recap_title'))),
            ],
          ),
          content: steps <= 0
              ? Text(HomeText.getString(language, 'recap_empty'))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(ctx, Icons.directions_walk, '$steps ${HomeText.getString(language, 'recap_steps')}'),
                    const SizedBox(height: 10),
                    _line(ctx, Icons.local_fire_department, '${cal.toStringAsFixed(0)} ${HomeText.getString(language, 'recap_cal')}'),
                    const SizedBox(height: 10),
                    _line(ctx, Icons.timer_outlined, '$mins ${HomeText.getString(language, 'recap_active')}'),
                    if (goalLine != null) ...[
                      const SizedBox(height: 10),
                      _line(ctx, Icons.flag_outlined, goalLine),
                    ],
                  ],
                ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(HomeText.getString(language, 'recap_ok')),
            ),
          ],
        );
      },
    );
  }

  static Widget _line(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}
