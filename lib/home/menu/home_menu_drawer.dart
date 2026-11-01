// lib/home/menu/home_menu_drawer.dart
// Full-height narrow side drawer: profile + streak + menu rows + version.
// Soft "alive" icon pulse when returning from profile / widget / support.
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_streak_capsule.dart';
import 'package:helsa/home/menu/menu_support_sheet.dart';
import 'package:helsa/home/menu/menu_profile_page.dart';
import 'package:helsa/home/menu/menu_widget_page.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

enum _MenuPulse { none, profile, widget, support }

class HomeMenuDrawerOverlay extends StatefulWidget {
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
  State<HomeMenuDrawerOverlay> createState() => _HomeMenuDrawerOverlayState();
}

class _HomeMenuDrawerOverlayState extends State<HomeMenuDrawerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _MenuPulse _target = _MenuPulse.none;

  late String _fullName;
  late String _genderTitle;

  @override
  void initState() {
    super.initState();
    _fullName = widget.fullName;
    _genderTitle = widget.genderTitle;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _target = _MenuPulse.none);
        }
      });
  }

  void _reloadHeader() {
    String name = 'Helsa';
    try {
      final n = IdentityStore.fullName.trim();
      if (n.isNotEmpty) name = n;
    } catch (_) {}

    String title = '';
    try {
      final raw = GenderStore.gender?.toLowerCase().trim() ?? '';
      final female = raw.contains('woman') ||
          raw.contains('female') ||
          raw.contains('زن') ||
          raw.contains('خانم') ||
          raw.contains('femme') ||
          raw == 'f';
      final male = !female &&
          (raw.contains('man') ||
              raw.contains('male') ||
              raw.contains('مرد') ||
              raw.contains('آقا') ||
              raw.contains('homme') ||
              raw == 'm' ||
              raw == 'male');
      if (female) {
        title = HomeText.getString(widget.language, 'menu_title_female');
      } else if (male) {
        title = HomeText.getString(widget.language, 'menu_title_male');
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _fullName = name;
      _genderTitle = title;
    });

    // Goals depend on body/activity/age/gender — refresh listeners.
    try {
      StepTracker.instance.profileChanged();
    } catch (_) {}
  }

  Future<void> _openProfile() {
    return _openThenPulse(
      () => MenuProfilePage.show(
        context,
        language: widget.language,
        onSaved: _reloadHeader,
      ),
      _MenuPulse.profile,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _openThenPulse(
    Future<void> Function() open,
    _MenuPulse which,
  ) async {
    await open();
    if (!mounted) return;
    setState(() => _target = which);
    _pulse
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    final fullName = _fullName;
    final genderTitle = _genderTitle;
    final closingListenable = widget.closingListenable;
    final onBarrierTap = widget.onBarrierTap;
    final onExitDone = widget.onExitDone;

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final drawerW = (size.width * 0.42).clamp(160.0, 220.0);
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
                GestureDetector(
                  onTap: _openProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
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
                            onTap: _openProfile,
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
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.only(top: context.vX2s),
                    itemCount: 5,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: ColorPalette.mintPrimary.withValues(alpha: 0.55),
                    ),
                    itemBuilder: (context, i) {
                      switch (i) {
                        case 0:
                          return _MenuRow(
                            icon: Icons.person_outline_rounded,
                            label:
                                HomeText.getString(language, 'menu_profile'),
                            language: language,
                            pulse: _pulse,
                            pulseKind: _target == _MenuPulse.profile
                                ? _PulseKind.profile
                                : _PulseKind.none,
                            onTap: _openProfile,
                          );
                        case 1:
                          return _MenuRow(
                            icon: Icons.widgets_rounded,
                            label: HomeText.getString(language, 'menu_widget'),
                            language: language,
                            pulse: _pulse,
                            pulseKind: _target == _MenuPulse.widget
                                ? _PulseKind.widget
                                : _PulseKind.none,
                            onTap: () {
                              _openThenPulse(
                                () => MenuWidgetPage.show(
                                  context,
                                  language: language,
                                ),
                                _MenuPulse.widget,
                              );
                            },
                          );
                        case 2:
                          return _MenuRow(
                            icon: Icons.settings_rounded,
                            label:
                                HomeText.getString(language, 'menu_settings'),
                            language: language,
                            pulse: _pulse,
                            pulseKind: _PulseKind.none,
                            onTap: () {},
                          );
                        case 3:
                          return _MenuRow(
                            icon: Icons.format_paint_rounded,
                            label: HomeText.getString(
                                language, 'menu_appearance'),
                            language: language,
                            pulse: _pulse,
                            pulseKind: _PulseKind.none,
                            onTap: () {},
                          );
                        default:
                          return _MenuRow(
                            icon: Icons.support_agent_rounded,
                            label:
                                HomeText.getString(language, 'menu_support'),
                            language: language,
                            pulse: _pulse,
                            pulseKind: _target == _MenuPulse.support
                                ? _PulseKind.support
                                : _PulseKind.none,
                            onTap: () {
                              _openThenPulse(
                                () => MenuSupportSheet.show(
                                  context,
                                  language: language,
                                ),
                                _MenuPulse.support,
                              );
                            },
                          );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.hX2s,
                    context.vX2s,
                    context.hX2s,
                    context.vX2s,
                  ),
                  child: MenuStreakCapsule(language: language),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: bottom + context.vS),
                  child: TextFielder(
                    text: HomeText.versionLabel(
                      language,
                      HomeMenuDrawerOverlay.appVersion,
                    ),
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
                s: AS.balanced,
                x: drawerW * 0.35,
                onComplete: onExitDone,
              )
            : panel.enSlideStart(
                context,
                s: AS.slow,
                x: drawerW * 0.35,
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

enum _PulseKind { none, profile, widget, support }

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String language;
  final VoidCallback onTap;
  final Animation<double> pulse;
  final _PulseKind pulseKind;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.language,
    required this.onTap,
    required this.pulse,
    required this.pulseKind,
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
            vertical: context.vS,
            horizontal: context.hX2s,
          ),
          child: Row(
            children: [
              _AliveIcon(
                icon: icon,
                color: cs.onSurface.withValues(alpha: 0.85),
                pulse: pulse,
                kind: pulseKind,
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

/// Soft, natural motion — not a dry jolt.
class _AliveIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Animation<double> pulse;
  final _PulseKind kind;

  const _AliveIcon({
    required this.icon,
    required this.color,
    required this.pulse,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        if (kind == _PulseKind.none || pulse.value <= 0) {
          return child!;
        }
        final t = pulse.value; // 0 → 1
        // Envelope: rises mid-way, settles by the end (no hard stop).
        final env = math.sin(t * math.pi); // 0→1→0 soft
        final decay = 1.0 - Curves.easeIn.transform(t);

        late double scale;
        late double angle;
        late double dy;

        switch (kind) {
          case _PulseKind.profile:
            // Soft settle: slight lift then land.
            scale = 1.0 + 0.10 * env * Curves.easeOut.transform(1 - t * 0.3);
            angle = 0;
            dy = -2.2 * env;
            break;
          case _PulseKind.widget:
            // Tiny multi-shape wobble (like tiles settling).
            scale = 1.0 + 0.08 * env;
            angle = 0.10 * math.sin(t * math.pi * 2.2) * decay;
            dy = -1.2 * env;
            break;
          case _PulseKind.support:
            // Gentle headset nod / sway.
            scale = 1.0 + 0.06 * env;
            angle = 0.14 * math.sin(t * math.pi * 1.6) * decay;
            dy = 0;
            break;
          case _PulseKind.none:
            scale = 1;
            angle = 0;
            dy = 0;
            break;
        }

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Iconer(
        icon: icon,
        template: IconTemplate.small,
        customColor: color,
        useGradient: false,
      ),
    );
  }
}
