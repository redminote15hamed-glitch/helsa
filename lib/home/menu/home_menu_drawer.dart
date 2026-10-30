// lib/home/menu/home_menu_drawer.dart
// Full-height narrow side drawer: profile + streak + menu rows + version.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_streak_capsule.dart';
import 'package:helsa/home/menu/menu_support_sheet.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class HomeMenuDrawerOverlay extends StatelessWidget {
  final String language;
  final String fullName;
  final String genderTitle;
  final ValueNotifier<bool> closingListenable;
  final VoidCallback onBarrierTap;
  final VoidCallback onExitDone;

  /// App version shown at bottom (matches pubspec 1.0.0+2).
  static const String appVersion = '1.0.0';

  const HomeMenuDrawerOverlay({
    super.key,
    required this.language,
    required this.fullName,
    required this.genderTitle,
    required this.closingListenable,
    required this.onBarrierTap,
    required this.onExitDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final drawerW = (size.width * 0.35).clamp(140.0, 190.0);
    final drawerBg = isDark ? const Color(0xFF1A2332) : const Color(0xFFF7F9FC);

    return ValueListenableBuilder<bool>(
      valueListenable: closingListenable,
      builder: (context, closing, _) {
        final panel = Material(
          color: drawerBg,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          borderRadius: isRtl
              ? const BorderRadius.horizontal(left: Radius.circular(18))
              : const BorderRadius.horizontal(right: Radius.circular(18)),
          child: SizedBox(
            width: drawerW,
            height: size.height,
            child: Column(
              children: [
                SizedBox(height: top + context.vS),
                // Small avatar
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          ColorPalette.mintPrimary.withValues(alpha: 0.18),
                      child: Icon(
                        Icons.person_rounded,
                        size: 26,
                        color: ColorPalette.mintPrimary,
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: isRtl ? null : -2,
                      left: isRtl ? -2 : null,
                      child: Material(
                        color: cs.surface,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.vX2s),
                if (genderTitle.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.hX2s),
                    child: TextFielder(
                      text: genderTitle,
                      languageCode: language,
                      template: TextTemplate.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.hX2s),
                  child: TextFielder(
                    text: fullName,
                    languageCode: language,
                    template: TextTemplate.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    customStyle: TextStyle(fontSize: context.m),
                  ),
                ),
                SizedBox(height: context.vS),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.hX2s),
                  child: MenuStreakCapsule(language: language),
                ),
                SizedBox(height: context.vS),
                // Menu rows (top → bottom)
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: context.hX3s),
                    children: [
                      _MenuRow(
                        icon: Icons.widgets_rounded,
                        label: HomeText.getString(language, 'menu_widget'),
                        language: language,
                        onTap: () {}, // later
                      ),
                      _MenuRow(
                        icon: Icons.settings_rounded,
                        label: HomeText.getString(language, 'menu_settings'),
                        language: language,
                        onTap: () {}, // later
                      ),
                      _MenuRow(
                        icon: Icons.format_paint_rounded,
                        label: HomeText.getString(language, 'menu_appearance'),
                        language: language,
                        onTap: () {}, // later
                      ),
                      _MenuRow(
                        icon: Icons.support_agent_rounded,
                        label: HomeText.getString(language, 'menu_support'),
                        language: language,
                        onTap: () {
                          MenuSupportSheet.show(context, language: language);
                        },
                      ),
                    ],
                  ),
                ),
                // Version
                Padding(
                  padding: EdgeInsets.only(bottom: bottom + context.vS),
                  child: TextFielder(
                    text: 'Helsa v$appVersion',
                    languageCode: language,
                    template: TextTemplate.caption,
                    textAlign: TextAlign.center,
                    customStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      fontSize: context.s * 0.95,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final animated = closing
            ? panel.exSlideEnd(
                context,
                s: AS.fast,
                x: drawerW * 0.4,
                onComplete: onExitDone,
              )
            : panel.enSlideStart(
                context,
                s: AS.balanced,
                x: drawerW * 0.4,
              );

        final barrier = closing
            ? const SizedBox.expand()
            : GestureDetector(
                onTap: onBarrierTap,
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: ColoredBox(
                    color:
                        Colors.black.withValues(alpha: isDark ? 0.45 : 0.32),
                  ),
                ),
              );

        return Stack(
          children: [
            Positioned.fill(child: barrier),
            Positioned(
              top: 0,
              bottom: 0,
              right: isRtl ? 0 : null,
              left: isRtl ? null : 0,
              child: animated,
            ),
          ],
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String language;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.language,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.vX2s,
            horizontal: context.hX3s,
          ),
          child: Row(
            children: [
              Iconer(
                icon: icon,
                template: IconTemplate.small,
                customColor: cs.onSurface.withValues(alpha: 0.85),
                useGradient: false,
              ),
              SizedBox(width: context.hX2s),
              Expanded(
                child: TextFielder(
                  text: label,
                  languageCode: language,
                  template: TextTemplate.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  customStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    fontSize: context.s,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
