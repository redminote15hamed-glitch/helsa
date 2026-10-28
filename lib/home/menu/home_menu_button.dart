// lib/home/menu/home_menu_button.dart
// Hamburger that opens the side menu overlay.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/home_menu_drawer.dart';
import 'package:helsa/setting/kit/circle_inkwell.dart';
import 'package:helsa/setting/kit/iconer.dart';
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
  final ValueNotifier<bool> _closing = ValueNotifier(false);
  bool _open = false;
  int _panelKey = 0;
  Timer? _forceCloseTimer;

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

  String _genderTitle(String lang) {
    String? raw;
    try {
      raw = GenderStore.gender?.toLowerCase().trim();
    } catch (_) {}
    if (raw == null || raw.isEmpty) return '';

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
            raw == 'm');

    if (female) return HomeText.getString(lang, 'menu_title_female');
    if (male) return HomeText.getString(lang, 'menu_title_male');
    return '';
  }

  @override
  void dispose() {
    _forceCloseTimer?.cancel();
    _removeOverlay(immediate: true);
    _closing.dispose();
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
    if (_entry != null) {
      _removeOverlay(immediate: true);
    }
    _open = true;
    _closing.value = false;
    _panelKey++;
    _entry = OverlayEntry(
      builder: (ctx) => HomeMenuDrawerOverlay(
        key: ValueKey(_panelKey),
        language: _lang,
        fullName: _fullName,
        genderTitle: _genderTitle(_lang),
        closingListenable: _closing,
        onBarrierTap: _close,
        onExitDone: () => _removeOverlay(immediate: true),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    if (mounted) setState(() {});
  }

  void _close() {
    if (_entry == null || _closing.value) return;
    _closing.value = true;
    _open = false;
    _entry!.markNeedsBuild();
    if (mounted) setState(() {});

    _forceCloseTimer?.cancel();
    _forceCloseTimer = Timer(const Duration(milliseconds: 900), () {
      if (_entry != null) _removeOverlay(immediate: true);
    });
  }

  void _removeOverlay({bool immediate = false}) {
    _forceCloseTimer?.cancel();
    _forceCloseTimer = null;
    _entry?.remove();
    _entry = null;
    _open = false;
    _closing.value = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CircleInkWell(
      icon: _open ? Icons.close_rounded : Icons.menu_rounded,
      iconTemplate: IconTemplate.large,
      onTap: _toggle,
    );
  }
}
