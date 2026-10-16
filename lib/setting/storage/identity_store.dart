// lib/setting/storage/identity_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class IdentityStore {
  IdentityStore._();
  static const String boxName = 'helsa_identity';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('IdentityStore.open() required');
    }
    return b;
  }

  static String get firstName => _b.get('firstName')?.toString() ?? '';
  static String get lastName => _b.get('lastName')?.toString() ?? '';
  static String get fullName {
    final n = '$firstName $lastName'.trim();
    return n;
  }

  static Future<void> save({
    required String firstName,
    required String lastName,
  }) async {
    await _b.put('firstName', firstName.trim());
    await _b.put('lastName', lastName.trim());
  }

  static Future<void> clear() => _b.clear();
}
