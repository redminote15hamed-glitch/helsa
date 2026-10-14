// lib/setting/storage/profile_store.dart
import 'package:hive_flutter/hive_flutter.dart';

/// Local profile storage (Hive).
/// Call [ProfileStore.init] once in main() before runApp.
class ProfileStore {
  ProfileStore._();

  static const String boxName = 'helsa_profile';
  static const String keyProfile = 'profile';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(boxName);
  }

  static Box<dynamic> get box {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('ProfileStore.init() must be called before use.');
    }
    return b;
  }

  static bool get isSetupDone {
    final map = box.get(keyProfile);
    if (map is Map) {
      return map['setupDone'] == true;
    }
    return false;
  }

  static Map<String, dynamic>? get profile {
    final map = box.get(keyProfile);
    if (map is Map) {
      return Map<String, dynamic>.from(map);
    }
    return null;
  }

  static Future<void> saveProfile({
    required String language,
    required String firstName,
    required String lastName,
    required String? gender,
    required int? age,
    required double? height,
    required double? weight,
    required double? waist,
    required int? activityLevel,
    required int? diet,
    required List<int> restrictions,
    required List<int> favorites,
    required String? sleepTime,
    required String? wakeTime,
  }) async {
    final data = <String, dynamic>{
      'setupDone': true,
      'language': language,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'waist': waist,
      'activityLevel': activityLevel,
      'diet': diet,
      'restrictions': List<int>.from(restrictions),
      'favorites': List<int>.from(favorites),
      'sleepTime': sleepTime,
      'wakeTime': wakeTime,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await box.put(keyProfile, data);
  }

  /// For debug / reset onboarding
  static Future<void> clear() async {
    await box.delete(keyProfile);
  }
}
