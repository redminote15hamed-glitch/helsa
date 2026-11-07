import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

/// Theme description card + Light/Dark mode pills.
class AppearanceThemeInfoCard extends StatelessWidget {
  const AppearanceThemeInfoCard({
    required this.palette,
    required this.night,
    required this.lang,
    required this.side,
    required this.onDay,
    required this.onNight,
  });

  final HelsaPalette palette;
  final bool night;
  final String lang;
  final double side;
  final VoidCallback onDay;
  final VoidCallback onNight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = HomeText.getString(lang, 'palette_${palette.id}');
    final desc = HomeText.getString(lang, 'palette_${palette.id}_desc');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: AppearanceModePill(
              selected: !night,
              icon: Icons.wb_sunny_rounded,
              label: HomeText.getString(lang, 'appearance_light'),
              lightStyle: true,
              onTap: onDay,
            ),
          ),
          SizedBox(width: context.hS),
          Container(
            width: side,
            height: side * 1.08,
            padding: EdgeInsets.symmetric(
              horizontal: context.hS,
              vertical: context.vXs,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    cs.primary.withValues(alpha: night ? 0.22 : 0.18),
                    cs.surface.withValues(alpha: night ? 0.55 : 0.92),
                  ),
                  Color.alphaBlend(
                    cs.primary.withValues(alpha: night ? 0.12 : 0.10),
                    cs.surface.withValues(alpha: night ? 0.40 : 0.85),
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(palette.icon, size: 20, color: cs.primary),
                SizedBox(height: context.vX3s * 0.6),
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.hXs * 0.6,
                        vertical: context.vX3s * 0.5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            cs.surface.withValues(alpha: night ? 0.50 : 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.18),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final fs = (box.maxHeight / 9.2)
                              .clamp(11.0, context.m * 1.05);
                          final isRtl = lang == 'fa' ||
                              Directionality.of(context) ==
                                  TextDirection.rtl;
                          return Text(
                            desc,
                            textAlign: TextAlign.center,
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: fs,
                              height: 1.38,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.92),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.vX3s * 0.5),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  textDirection: (lang == 'fa')
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: context.m,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.hS),
          Directionality(
            textDirection: TextDirection.ltr,
            child: AppearanceModePill(
              selected: night,
              icon: Icons.nightlight_round,
              label: HomeText.getString(lang, 'appearance_dark'),
              lightStyle: false,
              onTap: onNight,
            ),
          ),
        ],
      ),
    );
  }
}

class AppearanceModePill extends StatelessWidget {
  const AppearanceModePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.lightStyle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final bool lightStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = lightStyle
        ? (selected ? const Color(0xFFFFF6E8) : const Color(0xFFE8E4DE))
        : (selected ? const Color(0xFF243044) : const Color(0xFF1A222E));
    final fg = lightStyle
        ? (selected ? const Color(0xFFE8913A) : const Color(0xFF8A837C))
        : (selected ? const Color(0xFFF0F4FA) : const Color(0xFF7A8494));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 11 : 8,
          vertical: selected ? 12 : 9,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? fg.withValues(alpha: 0.55) : Colors.transparent,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: fg.withValues(alpha: lightStyle ? 0.28 : 0.38),
                    blurRadius: selected && !lightStyle ? 14 : 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 18 : 15, color: fg),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: selected ? context.xs : context.xs * 0.92,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



/// Bottom Continue / Apply button shown when theme is dirty.
