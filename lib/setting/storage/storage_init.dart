// lib/setting/storage/storage_init.dart
import 'package:hive_flutter/hive_flutter.dart';
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

/// Open all boxes once at app start (main / splash).
class StorageInit {
  StorageInit._();

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      MetaStore.open(),
      IdentityStore.open(),
      GenderStore.open(),
      AgeStore.open(),
      BodyStore.open(),
      ActivityStore.open(),
      DietStore.open(),
      RestrictionStore.open(),
      FavoriteStore.open(),
      SleepStore.open(),
    ]);
  }

  /// Called when user taps Start on summary.
  static Future<void> saveFullSetup({
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
    await MetaStore.setLanguage(language);
    await IdentityStore.save(firstName: firstName, lastName: lastName);
    await GenderStore.save(gender);
    await AgeStore.save(age);
    await BodyStore.save(height: height, weight: weight, waist: waist);
    await ActivityStore.save(activityLevel);
    await DietStore.save(diet);
    await RestrictionStore.save(restrictions);
    await FavoriteStore.save(favorites);
    await SleepStore.save(sleepTime: sleepTime, wakeTime: wakeTime);
    await MetaStore.setSetupDone(true);
  }

  static Future<void> clearAll() async {
    await MetaStore.clear();
    await IdentityStore.clear();
    await GenderStore.clear();
    await AgeStore.clear();
    await BodyStore.clear();
    await ActivityStore.clear();
    await DietStore.clear();
    await RestrictionStore.clear();
    await FavoriteStore.clear();
    await SleepStore.clear();
  }
}
