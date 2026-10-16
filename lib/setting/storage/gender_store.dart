// lib/setting/storage/gender_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class GenderStore {
  GenderStore._();
  static const String boxName = 'helsa_gender';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('GenderStore.open() required');
    }
    return b;
  }

  static String? get gender => _b.get('gender')?.toString();

  static Future<void> save(String? value) => _b.put('gender', value);

  static Future<void> clear() => _b.clear();
}
