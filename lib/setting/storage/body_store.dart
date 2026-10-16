// lib/setting/storage/body_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class BodyStore {
  BodyStore._();
  static const String boxName = 'helsa_body';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('BodyStore.open() required');
    }
    return b;
  }

  static double? get height {
    final v = _b.get('height');
    return v is num ? v.toDouble() : null;
  }

  static double? get weight {
    final v = _b.get('weight');
    return v is num ? v.toDouble() : null;
  }

  static double? get waist {
    final v = _b.get('waist');
    return v is num ? v.toDouble() : null;
  }

  static Future<void> save({
    double? height,
    double? weight,
    double? waist,
  }) async {
    await _b.put('height', height);
    await _b.put('weight', weight);
    await _b.put('waist', waist);
  }

  static Future<void> clear() => _b.clear();
}
