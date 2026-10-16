// lib/setting/storage/activity_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class ActivityStore {
  ActivityStore._();
  static const String boxName = 'helsa_activity';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('ActivityStore.open() required');
    }
    return b;
  }

  static int? get activityLevel {
    final v = _b.get('activityLevel');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static Future<void> save(int? value) => _b.put('activityLevel', value);

  static Future<void> clear() => _b.clear();
}
