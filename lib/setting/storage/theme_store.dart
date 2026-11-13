// lib/setting/storage/theme_store.dart
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/setting/storage/secure_hive.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/branding/launcher_icon_service.dart';

/// Palette + day/night brightness, persisted and broadcast app-wide.
class ThemeStore {
  ThemeStore._();

  static const String boxName = 'helsa_theme';
  static const String _keyPalette = 'paletteId';
  static const String _keyNight = 'night'; // bool as int 0/1

  static Box<dynamic>? _box;

  static final ValueNotifier<String> paletteId = ValueNotifier<String>('mint');
  static final ValueNotifier<bool> night = ValueNotifier<bool>(false);

  /// Bumps on every apply so MaterialApp + Home rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static String _savedPalette = 'mint';
  static bool _savedNight = false;

  static Future<void> open() async {
    _box ??= await SecureHive.openBox(boxName);
    final p = (_box!.get(_keyPalette) ?? 'mint').toString();
    final n = (_box!.get(_keyNight) == true || _box!.get(_keyNight) == 1);
    paletteId.value = HelsaPalette.byId(p).id;
    night.value = n;
    _savedPalette = paletteId.value;
    _savedNight = night.value;
    revision.value++;
    // Defer icon sync — applying activity-alias during cold start can kill the
    // process on some OEMs. Only runs if icon is already wrong.
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      unawaited(LauncherIconService.applyForPalette(paletteId.value));
    });
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('ThemeStore.open() required');
    }
    return b;
  }

  static HelsaPalette get palette => HelsaPalette.byId(paletteId.value);

  static bool get isDirty =>
      paletteId.value != _savedPalette || night.value != _savedNight;

  static ThemeData themeData() {
    return AppTheme.fromPalette(palette, night: night.value);
  }

  /// Preview only — does not persist until [save].
  static void preview({String? id, bool? isNight}) {
    if (id != null) paletteId.value = HelsaPalette.byId(id).id;
    if (isNight != null) night.value = isNight;
    revision.value++;
  }

  static Future<void> save() async {
    await _b.put(_keyPalette, paletteId.value);
    await _b.put(_keyNight, night.value);
    _savedPalette = paletteId.value;
    _savedNight = night.value;
    revision.value++;
    // Icon is applied by the appearance page *after* save + close.
    // Avoid double-apply here (setComponentEnabledSetting is process-sensitive).
  }

  static void revert() {
    paletteId.value = _savedPalette;
    night.value = _savedNight;
    revision.value++;
  }
}
