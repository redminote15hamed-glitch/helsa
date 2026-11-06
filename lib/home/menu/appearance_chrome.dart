import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

/// Back arrow for Appearance (RTL-aware).
class AppearanceBackButton extends StatelessWidget {
  const AppearanceBackButton({
    super.key,
    required this.isRtl,
    required this.onBack,
  });

  final bool isRtl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onBack,
      icon: Icon(
        isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
        color: cs.onSurface,
      ),
    );
  }
}

/// Tick (check) — only when theme selection is dirty.
class AppearanceTickButton extends StatelessWidget {
  const AppearanceTickButton({
    super.key,
    required this.dirty,
    required this.onSave,
  });

  final bool dirty;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!dirty) return const SizedBox(width: 48);
    return IconButton(
      onPressed: onSave,
      icon: Icon(Icons.check_rounded, color: cs.primary, size: 28),
    );
  }
}

/// Top bar: back + title + tick.
class AppearanceTopBar extends StatelessWidget {
  const AppearanceTopBar({
    super.key,
    required this.lang,
    required this.dirty,
    required this.isRtl,
    required this.onBack,
    required this.onSave,
  });

  final String lang;
  final bool dirty;
  final bool isRtl;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final back = AppearanceBackButton(isRtl: isRtl, onBack: onBack);
    final save = AppearanceTickButton(dirty: dirty, onSave: onSave);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hS,
        vertical: context.vX2s,
      ),
      child: Row(
        children: [
          if (!isRtl) back else save,
          Expanded(
            child: Text(
              HomeText.getString(lang, 'menu_appearance'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.l,
                color: cs.onSurface,
              ),
            ),
          ),
          if (!isRtl) save else back,
        ],
      ),
    );
  }
}

/// Bottom Continue / Apply when theme is dirty.
class AppearanceApplyBar extends StatelessWidget {
  const AppearanceApplyBar({
    super.key,
    required this.lang,
    required this.visible,
    required this.onApply,
  });

  final String lang;
  final bool visible;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: visible
          ? Padding(
              key: const ValueKey('apply'),
              padding: EdgeInsets.symmetric(horizontal: context.hM * 1.5),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.vS * 0.75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    HomeText.getString(lang, 'appearance_continue'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.m,
                    ),
                  ),
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('gap'),
              height: context.vS * 1.6,
            ),
    );
  }
}
