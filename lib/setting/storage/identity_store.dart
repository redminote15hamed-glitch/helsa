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

  /// preset id (e.g. "mint") or empty when custom file is used
  static String get avatarPreset => _b.get('avatarPreset')?.toString() ?? 'mint';

  /// absolute path to gallery image; empty if using preset
  static String get avatarPath => _b.get('avatarPath')?.toString() ?? '';

  static bool get hasCustomAvatar => avatarPath.isNotEmpty;

  static Future<void> save({
    required String firstName,
    required String lastName,
  }) async {
    await _b.put('firstName', firstName.trim());
    await _b.put('lastName', lastName.trim());
  }

  static Future<void> saveAvatarPreset(String presetId) async {
    await _b.put('avatarPreset', presetId);
    await _b.put('avatarPath', '');
  }

  static Future<void> saveAvatarFile(String absolutePath) async {
    await _b.put('avatarPath', absolutePath);
    await _b.put('avatarPreset', '');
  }

  static Future<void> clearAvatar() async {
    await _b.put('avatarPath', '');
    await _b.put('avatarPreset', 'mint');
  }

  static Future<void> clear() => _b.clear();
}
