// lib/setting/storage/age_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class AgeStore {
  AgeStore._();
  static const String boxName = 'helsa_age';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('AgeStore.open() required');
    }
    return b;
  }

  static int? get age {
    final v = _b.get('age');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static Future<void> save(int? value) => _b.put('age', value);

  static Future<void> clear() => _b.clear();
}
