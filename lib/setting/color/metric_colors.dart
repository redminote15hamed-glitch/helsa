import 'package:material_ui/material_ui.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/storage/theme_store.dart';

/// Single source for steps / calories / active colors.
/// Prefer [of] with a [BuildContext] under the active theme.
class MetricColors {
  const MetricColors({
    required this.steps,
    required this.calories,
    required this.active,
  });

  final Color steps;
  final Color calories;
  final Color active;

  /// From current [ThemeStore] palette (works outside Material subtree).
  static MetricColors get current {
    final p = ThemeStore.palette;
    final night = ThemeStore.night.value;
    return MetricColors(
      steps: p.steps(night),
      calories: p.cal(night),
      active: p.time(night),
    );
  }

  /// From palette + night (preview on Appearance page).
  static MetricColors fromPalette(HelsaPalette p, {required bool night}) {
    return MetricColors(
      steps: p.steps(night),
      calories: p.cal(night),
      active: p.time(night),
    );
  }

  /// Same as [current] when ThemeStore is the source of truth for the app.
  static MetricColors of(BuildContext context) => current;
}
