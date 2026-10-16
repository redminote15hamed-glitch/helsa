// lib/setting/storage/diet_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class DietStore {
  DietStore._();
  static const String boxName = 'helsa_diet';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('DietStore.open() required');
    }
    return b;
  }

  static int? get diet {
    final v = _b.get('diet');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static Future<void> save(int? value) => _b.put('diet', value);

  static Future<void> clear() => _b.clear();
}
