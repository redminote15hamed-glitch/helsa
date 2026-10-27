// lib/home/widgets/home_menu_button.dart
// Side drawer from start edge — profile header only (avatar, title, name).
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/circle_inkwell.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/meta_store.dart';

class HomeMenuButton extends StatefulWidget {
  const HomeMenuButton({super.key});

  @override
  State<HomeMenuButton> createState() => _HomeMenuButtonState();
}

class _HomeMenuButtonState extends State<HomeMenuButton> {
  OverlayEntry? _entry;
  bool _open = false;
  int _panelKey = 0;
  bool _closing = false;

  String get _lang {
    try {
      return MetaStore.language;
    } catch (_) {
      return 'en';
    }
  }

  String get _fullName {
    try {
      final n = IdentityStore.fullName.trim();
      return n.isEmpty ? 'Helsa' : n;
    } catch (_) {
      return 'Helsa';
    }
  }

  /// Maps stored gender to localized title: بانو / آقای …
  String _genderTitle(String lang) {
    String? raw;
    try {
      raw = GenderStore.gender?.toLowerCase().trim();
    } catch (_) {}
    if (raw == null || raw.isEmpty) return '';

    final female = raw.contains('f') ||
        raw.contains('woman') ||
        raw.contains('female') ||
        raw.contains('زن') ||
        raw.contains('خانم') ||
        raw.contains('femme');
    final male = raw.contains('m') && !female ||
        raw.contains('man') ||
        raw.contains('male') ||
        raw.contains('مرد') ||
        raw.contains('آقا') ||
        raw.contains('homme');

    if (female) return HomeText.getString(lang, 'menu_title_female');
    if (male) return HomeText.getString(lang, 'menu_title_male');
    return '';
  }

  @override
  void dispose() {
    _removeOverlay(immediate: true);
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    if (_entry != null) return;
    _open = true;
    _closing = false;
    _panelKey++;
    _entry = OverlayEntry(
      builder: (ctx) => _DrawerOverlay(
        key: ValueKey(_panelKey),
        language: _lang,
        fullName: _fullName,
        genderTitle: _genderTitle(_lang),
        closing: _closing,
        onBarrierTap: _close,
        onExitDone: () => _removeOverlay(immediate: true),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    setState(() {});
  }

  void _close() {
    if (_entry == null || _closing) return;
    _closing = true;
    _open = false;
    _entry!.markNeedsBuild();
    setState(() {});
  }

  void _removeOverlay({bool immediate = false}) {
    _entry?.remove();
    _entry = null;
    _open = false;
    _closing = false;
    if (!immediate && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CircleInkWell(
      icon: _open ? Icons.close_rounded : Icons.menu_rounded,
      iconTemplate: IconTemplate.medium,
      onTap: _toggle,
    );
  }
}

class _DrawerOverlay extends StatelessWidget {
  final String language;
  final String fullName;
  final String genderTitle;
  final bool closing;
  final VoidCallback onBarrierTap;
  final VoidCallback onExitDone;

  const _DrawerOverlay({
    super.key,
    required this.language,
    required this.fullName,
    required this.genderTitle,
    required this.closing,
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

    final drawerW = (size.width * 0.78).clamp(260.0, 340.0);
    final drawerBg = isDark ? const Color(0xFF1A2332) : const Color(0xFFF7F9FC);

    final drawer = Material(
      color: drawerBg,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      borderRadius: isRtl
          ? const BorderRadius.horizontal(left: Radius.circular(20))
          : const BorderRadius.horizontal(right: Radius.circular(20)),
      child: SizedBox(
        width: drawerW,
        height: size.height,
        child: Column(
          children: [
            SizedBox(height: top + context.vM),

            // Avatar + small pencil
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      ColorPalette.mintPrimary.withValues(alpha: 0.18),
                  child: Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: ColorPalette.mintPrimary,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: isRtl ? null : 2,
                  left: isRtl ? 2 : null,
                  child: Material(
                    color: cs.surface,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        // edit profile — later
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: context.vS),

            // Gender title: بانو / آقای
            if (genderTitle.isNotEmpty)
              Text(
                genderTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),

            if (genderTitle.isNotEmpty) SizedBox(height: context.vX3s),

            // Full name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hM),
              child: Text(
                fullName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: EdgeInsets.only(bottom: bottom + context.vS),
              child: Text(
                'Helsa',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final animated = closing
        ? drawer.exSlideEnd(
            context,
            s: AS.fast,
            x: drawerW * 0.35,
            onComplete: onExitDone,
          )
        : drawer.enSlideStart(
            context,
            s: AS.balanced,
            x: drawerW * 0.35,
          );

    final barrier = closing
        ? const SizedBox.expand()
        : GestureDetector(
            onTap: onBarrierTap,
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.35),
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
  }
}
