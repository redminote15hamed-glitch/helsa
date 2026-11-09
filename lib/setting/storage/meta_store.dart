// lib/setting/storage/meta_store.dart
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:helsa/setting/storage/secure_hive.dart';

class MetaStore {
  MetaStore._();

  static const String boxName = 'helsa_meta';
  static Box<dynamic>? _box;

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> open() async {
    _box ??= await SecureHive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('MetaStore.open() required');
    }
    return b;
  }

  static bool get isSetupDone =>
      _b.get('setupDone', defaultValue: false) == true;

  /// True after the user finishes the permissions screen.
  /// Migration: older installs that already completed setup (and used Home)
  /// never had this flag — treat them as done so we don't trap them.
  static bool get isPermissionsDone {
    if (!_b.containsKey('permissionsDone')) {
      return isSetupDone; // legacy users already past onboarding
    }
    return _b.get('permissionsDone') == true;
  }

  /// Last setup step index (0..10) so process death can resume onboarding.
  static int get setupStep {
    final v = _b.get('setupStep');
    if (v is int) return v.clamp(0, 20);
    if (v is num) return v.toInt().clamp(0, 20);
    return 0;
  }

  static String get language {
    final v = _b.get('language')?.toString() ?? 'en';
    final c = v.toLowerCase();
    if (c.startsWith('fa')) return 'fa';
    if (c.startsWith('fr')) return 'fr';
    return 'en';
  }

  static Future<void> setLanguage(String lang) async {
    final c = lang.toLowerCase();
    final normalized =
        c.startsWith('fa') ? 'fa' : (c.startsWith('fr') ? 'fr' : 'en');
    await _b.put('language', normalized);
    revision.value++;
  }

  static Future<void> setSetupDone(bool value) async {
    await _b.put('setupDone', value);
    if (value) {
      await _b.put('savedAt', DateTime.now().toIso8601String());
    }
  }

  static Future<void> setPermissionsDone(bool value) async {
    await _b.put('permissionsDone', value);
  }

  static Future<void> setSetupStep(int step) async {
    await _b.put('setupStep', step.clamp(0, 20));
  }

  /// Marks profile saved but permissions still required.
  static Future<void> markAwaitingPermissions() async {
    await _b.put('setupDone', true);
    await _b.put('permissionsDone', false);
    await _b.put('savedAt', DateTime.now().toIso8601String());
  }

  static String? get savedAt => _b.get('savedAt')?.toString();

  static bool get widgetPromoDismissed =>
      _b.get('widgetPromoDismissed', defaultValue: false) == true;

  static Future<void> setWidgetPromoDismissed(bool value) =>
      _b.put('widgetPromoDismissed', value);

  // ── Draft fields for mid-setup resume ──────────────────────────
  static Future<void> saveSetupDraft({
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
    required int step,
  }) async {
    await setLanguage(language);
    await _b.put('setupStep', step);
    await _b.put('draft_firstName', firstName);
    await _b.put('draft_lastName', lastName);
    await _b.put('draft_gender', gender);
    await _b.put('draft_age', age);
    await _b.put('draft_height', height);
    await _b.put('draft_weight', weight);
    await _b.put('draft_waist', waist);
    await _b.put('draft_activity', activityLevel);
    await _b.put('draft_diet', diet);
    await _b.put('draft_restrictions', restrictions);
    await _b.put('draft_favorites', favorites);
    await _b.put('draft_sleep', sleepTime);
    await _b.put('draft_wake', wakeTime);
  }

  static Map<String, dynamic> readSetupDraft() {
    return {
      'firstName': _b.get('draft_firstName')?.toString() ?? '',
      'lastName': _b.get('draft_lastName')?.toString() ?? '',
      'gender': _b.get('draft_gender')?.toString(),
      'age': _b.get('draft_age') is int ? _b.get('draft_age') as int : null,
      'height': (_b.get('draft_height') as num?)?.toDouble(),
      'weight': (_b.get('draft_weight') as num?)?.toDouble(),
      'waist': (_b.get('draft_waist') as num?)?.toDouble(),
      'activityLevel':
          _b.get('draft_activity') is int ? _b.get('draft_activity') as int : null,
      'diet': _b.get('draft_diet') is int ? _b.get('draft_diet') as int : null,
      'restrictions':
          (_b.get('draft_restrictions') as List?)?.cast<int>() ?? <int>[],
      'favorites':
          (_b.get('draft_favorites') as List?)?.cast<int>() ?? <int>[],
      'sleepTime': _b.get('draft_sleep')?.toString(),
      'wakeTime': _b.get('draft_wake')?.toString(),
      'step': setupStep,
      'language': language,
    };
  }

  static Future<void> clearSetupDraft() async {
    for (final k in [
      'setupStep',
      'draft_firstName',
      'draft_lastName',
      'draft_gender',
      'draft_age',
      'draft_height',
      'draft_weight',
      'draft_waist',
      'draft_activity',
      'draft_diet',
      'draft_restrictions',
      'draft_favorites',
      'draft_sleep',
      'draft_wake',
    ]) {
      await _b.delete(k);
    }
  }

  static Future<void> clear() => _b.clear();
}
