import 'package:flutter/material.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Placeholder for the restriction/allergy step.
/// The actual selection widget will be implemented later.
class RestrictionSetupPlaceholder extends StatelessWidget {
  final String currentLang;

  const RestrictionSetupPlaceholder({super.key, required this.currentLang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        SetupText.getString(currentLang, 'restriction_subtitle')
            .replaceAll('\n', '\n'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}
