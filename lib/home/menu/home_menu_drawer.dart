// lib/home/menu/home_menu_drawer.dart
// Narrow side drawer — gradient header, grouped dock-style items, streak bar.
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_streak_capsule.dart';
import 'package:helsa/home/menu/menu_support_sheet.dart';
import 'package:helsa/home/menu/menu_profile_page.dart';
import 'package:helsa/home/menu/menu_avatar_picker.dart';
import 'package:helsa/home/menu/helsa_avatar.dart';
import 'package:helsa/home/menu/menu_widget_page.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/home/menu/menu_coming_soon_page.dart';
import 'package:helsa/home/menu/menu_appearance_page.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';

enum _MenuPulse { none, profile, widget, support }

class HomeMenuDrawerOverlay extends StatefulWidget {
  final String language;
  final String fullName;
  final String genderTitle;
  final ValueNotifier<bool> closingListenable;
  final VoidCallback onBarrierTap;
  final VoidCallback onExitDone;

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
      duration: const Duration(milliseconds: 900),
    );
  }

  Future<void> _reloadHeader() async {
    try {
      await GenderStore.open();
      await IdentityStore.open();
    } catch (_) {}
    if (!mounted) return;
    final lang = widget.language;
    final g = (GenderStore.gender ?? '').toLowerCase();
    String title;
    if (g.startsWith('f') || g.contains('female') || g.contains('زن') || g.contains('خانم')) {
      title = HomeText.getString(lang, 'menu_title_female');
    } else if (g.startsWith('m') || g.contains('male') || g.contains('مرد') || g.contains('آقا')) {
      title = HomeText.getString(lang, 'menu_title_male');
    } else {
      title = _genderTitle;
    }
    final name = IdentityStore.fullName;
    setState(() {
      _genderTitle = title;
      if (name.isNotEmpty) _fullName = name;
    });
  }

  void _pulseTarget(_MenuPulse t) {
    _target = t;
    _pulse.forward(from: 0);
  }

  /// Avatar is floating → close drawer first so it is not covered.
  Future<void> _openAvatar() async {
    widget.onBarrierTap();
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;
    final theme = Theme.of(context);
    final changed = await MenuAvatarPicker.show(
      context,
      language: widget.language,
      theme: theme,
    );
    if (!mounted) return;
    if (changed) await _reloadHeader();
  }

  Future<void> _openFromRow(
    BuildContext rowContext, {
    required WidgetBuilder builder,
  }) {
    final origin = MenuExpandHost.rectOf(rowContext);
    final theme = Theme.of(context);
    return MenuExpandHost.open<void>(
      context: context,
      origin: origin,
      theme: theme,
      builder: builder,
    );
  }

  Future<void> _openProfile(BuildContext rowCtx) async {
    final theme = Theme.of(context);
    await MenuProfilePage.show(
      context,
      language: widget.language,
      theme: theme,
      origin: MenuExpandHost.rectOf(rowCtx),
      onSaved: () {
        _reloadHeader();
      },
    );
    if (mounted) {
      await _reloadHeader();
      _pulseTarget(_MenuPulse.profile);
    }
  }

  Future<void> _openWidget(BuildContext rowCtx) async {
    final theme = Theme.of(context);
    await MenuWidgetPage.show(
      context,
      language: widget.language,
      theme: theme,
      origin: MenuExpandHost.rectOf(rowCtx),
    );
    if (mounted) _pulseTarget(_MenuPulse.widget);
  }

  /// Support stays a floating bottom sheet with single-phase Genie.
  /// Close the drawer first so the sheet is not covered by the open menu.
  Future<void> _openSupport(BuildContext rowCtx) async {
    widget.onBarrierTap(); // auto-close drawer (same as avatar / barrier)
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await MenuSupportSheet.show(
      context,
      language: widget.language,
    );
    if (mounted) _pulseTarget(_MenuPulse.support);
  }

  Future<void> _openComingSoon(BuildContext rowCtx, String titleKey) {
    return _openFromRow(
      rowCtx,
      builder: (ctx) => MenuComingSoonPage(
        language: widget.language,
        titleKey: titleKey,
      ),
    );
  }

  Future<void> _openAppearance(BuildContext rowCtx) {
    return _openFromRow(
      rowCtx,
      builder: (ctx) => MenuAppearancePage(language: widget.language),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
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

    // Narrower panel (~34%)
    final drawerW = (size.width * 0.34).clamp(148.0, 200.0);
    final edgeRadius = isRtl
        ? const BorderRadius.horizontal(left: Radius.circular(28))
        : const BorderRadius.horizontal(right: Radius.circular(28));

    return ValueListenableBuilder<bool>(
      valueListenable: closingListenable,
      builder: (context, closing, _) {
        final panel = Material(
          color: Colors.transparent,
          elevation: 18,
          shadowColor: Colors.black.withValues(alpha: 0.45),
          borderRadius: edgeRadius,
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: drawerW,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Soft depth gradient background
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.alphaBlend(
                          cs.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                          cs.surface,
                        ),
                        cs.surface,
                        Color.alphaBlend(
                          cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.03),
                          cs.surface,
                        ),
                      ],
                    ),
                  ),
                ),
                // Primary edge highlight
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: isRtl ? null : 0,
                  left: isRtl ? 0 : null,
                  width: 2.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ColorPalette.mintPrimary.withValues(alpha: 0.15),
                          ColorPalette.mintPrimary.withValues(alpha: 0.85),
                          ColorPalette.mintPrimary.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient profile header band
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        context.hS,
                        top + context.vS,
                        context.hS,
                        context.vX2s,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  ColorPalette.mintPrimary
                                      .withValues(alpha: 0.28),
                                  ColorPalette.skyBlue
                                      .withValues(alpha: 0.12),
                                  Colors.transparent,
                                ]
                              : [
                                  ColorPalette.mintPrimary
                                      .withValues(alpha: 0.18),
                                  ColorPalette.skyBlue
                                      .withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                        ),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _openAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        ColorPalette.mintPrimary,
                                        ColorPalette.skyBlue,
                                        ColorPalette.calorieBurn,
                                        ColorPalette.mintPrimary,
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: cs.surface,
                                    ),
                                    child: HelsaAvatar.fromStore(
                                      radius: context.s * 1.7,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Material(
                                    color: cs.surface,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _openAvatar,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.edit_rounded,
                                          size: context.s * 0.85,
                                          color: ColorPalette.mintPrimary,
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
                            TextFielder(
                              text: genderTitle,
                              languageCode: language,
                              template: TextTemplate.caption,
                              textAlign: TextAlign.center,
                              customStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.55),
                                fontSize: context.s * 0.9,
                              ),
                            ),
                          TextFielder(
                            text: fullName.isEmpty ? '—' : fullName,
                            languageCode: language,
                            template: TextTemplate.caption,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            customStyle: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              fontSize: context.m,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable groups
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          context.hX2s,
                          context.vS,
                          context.hX2s,
                          context.vS,
                        ),
                        children: [
                          _GroupCard(
                            isDark: isDark,
                            children: [
                              _DockItem(
                                icon: Icons.person_outline_rounded,
                                label: HomeText.getString(
                                    language, 'menu_profile'),
                                language: language,
                                tint: ColorPalette.mintPrimary,
                                pulse: _pulse,
                                pulseKind: _target == _MenuPulse.profile
                                    ? _PulseKind.profile
                                    : _PulseKind.none,
                                onTap: _openProfile,
                              ),
                            ],
                          ),
                          SizedBox(height: context.vS),
                          _GroupCard(
                            isDark: isDark,
                            children: [
                              _DockItem(
                                icon: Icons.widgets_rounded,
                                label: HomeText.getString(
                                    language, 'menu_widget'),
                                language: language,
                                tint: ColorPalette.skyBlue,
                                pulse: _pulse,
                                pulseKind: _target == _MenuPulse.widget
                                    ? _PulseKind.widget
                                    : _PulseKind.none,
                                onTap: _openWidget,
                              ),
                            ],
                          ),
                          SizedBox(height: context.vS),
                          _GroupCard(
                            isDark: isDark,
                            children: [
                              _DockItem(
                                icon: Icons.settings_rounded,
                                label: HomeText.getString(
                                    language, 'menu_settings'),
                                language: language,
                                tint: ColorPalette.calorieBurn,
                                pulse: _pulse,
                                pulseKind: _PulseKind.none,
                                onTap: (ctx) =>
                                    _openComingSoon(ctx, 'menu_settings'),
                              ),
                              _DockItem(
                                icon: Icons.format_paint_rounded,
                                label: HomeText.getString(
                                    language, 'menu_appearance'),
                                language: language,
                                tint: const Color(0xFF9B7BFF),
                                pulse: _pulse,
                                pulseKind: _PulseKind.none,
                                onTap: (ctx) => _openAppearance(ctx),
                              ),
                            ],
                          ),
                          SizedBox(height: context.vS),
                          _GroupCard(
                            isDark: isDark,
                            children: [
                              _DockItem(
                                icon: Icons.support_agent_rounded,
                                label: HomeText.getString(
                                    language, 'menu_support'),
                                language: language,
                                tint: ColorPalette.mintPrimary,
                                pulse: _pulse,
                                pulseKind: _target == _MenuPulse.support
                                    ? _PulseKind.support
                                    : _PulseKind.none,
                                onTap: _openSupport,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sticky bottom: streak + version
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        context.hX2s,
                        context.vS,
                        context.hX2s,
                        bottom + context.vS,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.55),
                        border: Border(
                          top: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          MenuStreakCapsule(language: language),
                          SizedBox(height: context.vX2s),
                          TextFielder(
                            text: HomeText.versionLabel(
                              language,
                              HomeMenuDrawerOverlay.appVersion,
                            ),
                            languageCode: language,
                            template: TextTemplate.caption,
                            textAlign: TextAlign.center,
                            customStyle: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontSize: context.s * 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _GroupCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;

  const _GroupCard({required this.isDark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

enum _PulseKind { none, profile, widget, support }

/// Dock-style item: icon in soft tint circle + label below/ beside.
class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String language;
  final Color tint;
  final void Function(BuildContext rowContext) onTap;
  final Animation<double> pulse;
  final _PulseKind pulseKind;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.language,
    required this.tint,
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
        onTap: () => onTap(context),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.vS * 1.15,
            horizontal: context.hX2s,
          ),
          child: Row(
            children: [
              _AliveIcon(
                icon: icon,
                tint: tint,
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

class _AliveIcon extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Animation<double> pulse;
  final _PulseKind kind;

  const _AliveIcon({
    required this.icon,
    required this.tint,
    required this.pulse,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final base = Container(
      width: context.s * 2.2,
      height: context.s * 2.2,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: context.s * 1.15, color: tint),
    );

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        if (kind == _PulseKind.none || pulse.value <= 0) {
          return child!;
        }
        final t = pulse.value;
        final env = math.sin(t * math.pi);
        late double scale;
        late double angle;
        late double dy;
        switch (kind) {
          case _PulseKind.profile:
            scale = 1.0 + 0.10 * env;
            angle = 0;
            dy = -2.2 * env;
            break;
          case _PulseKind.widget:
            scale = 1.0 + 0.08 * env;
            angle = 0.08 * env * math.sin(t * math.pi * 2);
            dy = 0;
            break;
          case _PulseKind.support:
            scale = 1.0 + 0.07 * env;
            angle = 0;
            dy = 1.5 * env * math.sin(t * math.pi * 3);
            break;
          case _PulseKind.none:
            scale = 1;
            angle = 0;
            dy = 0;
        }
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: base,
    );
  }
}
