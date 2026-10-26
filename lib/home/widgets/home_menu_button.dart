// lib/home/widgets/home_menu_button.dart
// Hamburger (start side by language). Opens empty top dropdown via Animator.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/circle_inkwell.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

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
      builder: (ctx) => _MenuOverlay(
        key: ValueKey(_panelKey),
        closing: _closing,
        onBarrierTap: _close,
        onExitDone: () {
          _removeOverlay(immediate: true);
        },
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

class _MenuOverlay extends StatelessWidget {
  final bool closing;
  final VoidCallback onBarrierTap;
  final VoidCallback onExitDone;

  const _MenuOverlay({
    super.key,
    required this.closing,
    required this.onBarrierTap,
    required this.onExitDone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final panel = Material(
      color: cs.surface.withValues(alpha: 0.97),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        width: double.infinity,
        // Empty for now — content comes later
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.hM,
            top + context.vS,
            context.hM,
            context.vM,
          ),
          child: const SizedBox(height: 8),
        ),
      ),
    );

    final animated = closing
        ? panel.exSlideUp(s: AS.fast, y: 48, onComplete: onExitDone)
        : panel.enSlideDown(s: AS.balanced, y: 48);

    // Dim + slight blur so focus stays on the menu panel
    final barrier = closing
        ? const SizedBox.expand()
        : GestureDetector(
            onTap: onBarrierTap,
            behavior: HitTestBehavior.opaque,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),
          );

    return Stack(
      children: [
        Positioned.fill(child: barrier),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: animated,
        ),
      ],
    );
  }
}
