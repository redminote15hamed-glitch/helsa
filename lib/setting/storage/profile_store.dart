// lib/setting/storage/profile_store.dart
// Facade: keeps old API, uses separate Hive boxes under the hood.
import 'package:helsa/setting/storage/storage_init.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/diet_store.dart';
import 'package:helsa/setting/storage/restriction_store.dart';
import 'package:helsa/setting/storage/favorite_store.dart';
import 'package:helsa/setting/storage/sleep_store.dart';

class ProfileStore {
  ProfileStore._();

  static Future<void> init() => StorageInit.init();

  static bool get isSetupDone => MetaStore.isSetupDone;

  static Map<String, dynamic>? get profile {
    if (!MetaStore.isSetupDone) return null;
    return {
      'setupDone': true,
      'language': MetaStore.language,
      'firstName': IdentityStore.firstName,
      'lastName': IdentityStore.lastName,
      'gender': GenderStore.gender,
      'age': AgeStore.age,
      'height': BodyStore.height,
      'weight': BodyStore.weight,
      'waist': BodyStore.waist,
      'activityLevel': ActivityStore.activityLevel,
      'diet': DietStore.diet,
      'restrictions': RestrictionStore.list,
      'favorites': FavoriteStore.list,
      'sleepTime': SleepStore.sleepTime,
      'wakeTime': SleepStore.wakeTime,
      'savedAt': MetaStore.savedAt,
    };
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
  }) =>
      StorageInit.saveFullSetup(
        language: language,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        waist: waist,
        activityLevel: activityLevel,
        diet: diet,
        restrictions: restrictions,
        favorites: favorites,
        sleepTime: sleepTime,
        wakeTime: wakeTime,
      );

  static Future<void> clear() => StorageInit.clearAll();
}
