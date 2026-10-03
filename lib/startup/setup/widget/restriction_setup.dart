// lib/startup/setup/widget/restriction_setup.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// حساسیت غذایی — ابر برچسب داخل قاب مربعی
class RestrictionSetup extends StatelessWidget {
  final String currentLang;
  final List<int> selectedRestrictions;
  final ValueChanged<List<int>> onChanged;

  const RestrictionSetup({
    super.key,
    required this.currentLang,
    required this.selectedRestrictions,
    required this.onChanged,
  });

  static const int kNone = 0;

  static const List<Map<String, dynamic>> items = [
    {'id': 0, 'icon': Icons.block_rounded, 'title': 'restrict_none'},
    {'id': 1, 'icon': Icons.local_drink_rounded, 'title': 'restrict_dairy'},
    {'id': 2, 'icon': Icons.egg_outlined, 'title': 'restrict_eggs'},
    {'id': 3, 'icon': Icons.spa_rounded, 'title': 'restrict_nuts'},
    {'id': 4, 'icon': Icons.crisis_alert_rounded, 'title': 'restrict_peanuts'},
    {'id': 5, 'icon': Icons.bakery_dining_rounded, 'title': 'restrict_gluten'},
    {'id': 6, 'icon': Icons.grain_rounded, 'title': 'restrict_wheat'},
    {'id': 7, 'icon': Icons.set_meal_rounded, 'title': 'restrict_seafood'},
    {'id': 8, 'icon': Icons.phishing_rounded, 'title': 'restrict_fish'},
    {'id': 9, 'icon': Icons.water_rounded, 'title': 'restrict_shellfish'},
    {'id': 10, 'icon': Icons.grass_rounded, 'title': 'restrict_soy'},
    {'id': 11, 'icon': Icons.brightness_1_rounded, 'title': 'restrict_sesame'},
    {'id': 12, 'icon': Icons.science_rounded, 'title': 'restrict_mustard'},
    {'id': 13, 'icon': Icons.eco_rounded, 'title': 'restrict_celery'},
    {'id': 14, 'icon': Icons.bubble_chart_rounded, 'title': 'restrict_sulfites'},
    {'id': 15, 'icon': Icons.local_florist_rounded, 'title': 'restrict_lupin'},
    {'id': 16, 'icon': Icons.agriculture_rounded, 'title': 'restrict_corn'},
    {'id': 17, 'icon': Icons.hive_rounded, 'title': 'restrict_honey'},
  ];

  void _toggle(int id) {
    final List<int> next = List<int>.from(selectedRestrictions);

    if (id == kNone) {
      onChanged([kNone]);
      return;
    }

    next.remove(kNone);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double gapSubtitle = context.vS;
    final double framePad = context.s;
    final double chipGapH = context.hX3s;
    final double chipGapV = context.vX3s;
    final double radiusFrame = context.m;
    final double radiusChip = context.s;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Displayer(
          index: 1,
          template: MotionTemplate.bottomSlide,
          child: TextFielder(
            text: SetupText.getString(currentLang, 'restriction_subtitle'),
            template: TextTemplate.body,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
              fontSize: context.baseScale * 0.95,
            ),
          ),
        ),
        SizedBox(height: gapSubtitle),
        Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = constraints.maxWidth;
              // قاب مربعی: ضلع = عرض در دسترس (با سقف ارتفاع صفحه)
              double side = maxW;
              if (constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0 &&
                  side > constraints.maxHeight) {
                side = constraints.maxHeight;
              }
              // روی دسکتاپ خیلی بزرگ نشود
              final double cap = context.vX5l + context.vX2l;
              if (side > cap) side = cap;

              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: Container(
                    padding: EdgeInsets.all(framePad),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(radiusFrame),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: context.baseScale * 0.06,
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Wrap(
                        spacing: chipGapH,
                        runSpacing: chipGapV,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final item in items)
                            _TagChip(
                              icon: item['icon'] as IconData,
                              label: SetupText.getString(
                                currentLang,
                                item['title'] as String,
                              ),
                              selected: selectedRestrictions
                                  .contains(item['id'] as int),
                              onTap: () => _toggle(item['id'] as int),
                              radius: radiusChip,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double radius;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withValues(alpha: 0.65);
    final Color fg = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.25);

    final double padH = context.hXs;
    final double padV = context.vX4s;
    final double iconGap = context.hX4s;
    final double borderW = context.baseScale * 0.07;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: borderW),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Iconer(
                icon: icon,
                template: IconTemplate.small,
                customColor: fg,
              ),
              SizedBox(width: iconGap),
              TextFielder(
                text: label,
                template: TextTemplate.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                customStyle: TextStyle(
                  fontSize: context.s,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
