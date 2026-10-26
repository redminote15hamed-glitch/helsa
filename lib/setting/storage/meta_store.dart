// lib/setting/storage/meta_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class MetaStore {
  MetaStore._();
  static const String boxName = 'helsa_meta';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('MetaStore.open() required');
    }
    return b;
  }

  static bool get isSetupDone => _b.get('setupDone', defaultValue: false) == true;

  static String get language {
    final v = _b.get('language')?.toString() ?? 'en';
    final c = v.toLowerCase();
    if (c.startsWith('fa')) return 'fa';
    if (c.startsWith('fr')) return 'fr';
    return 'en';
  }

  static Future<void> setLanguage(String lang) => _b.put('language', lang);

  static Future<void> setSetupDone(bool value) async {
    await _b.put('setupDone', value);
    if (value) {
      await _b.put('savedAt', DateTime.now().toIso8601String());
    }
  }

  static String? get savedAt => _b.get('savedAt')?.toString();

  /// User closed the home-screen widget promo banner — do not show again.
  static bool get widgetPromoDismissed =>
      _b.get('widgetPromoDismissed', defaultValue: false) == true;

  static Future<void> setWidgetPromoDismissed(bool value) =>
      _b.put('widgetPromoDismissed', value);

  static Future<void> clear() => _b.clear();
}
