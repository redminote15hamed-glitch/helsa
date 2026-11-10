// lib/setting/backup/backup_payload.dart
// Collect / restore all Helsa Hive boxes + optional avatar bytes.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:helsa/setting/storage/secure_hive.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/settings_store.dart';
import 'package:helsa/setting/storage/steps_store.dart';
import 'package:helsa/setting/storage/streak_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

class BackupPayload {
  BackupPayload._();

  static const int formatVersion = 1;
  static const String magic = 'HELSA_BACKUP';

  static const List<String> boxNames = [
    'helsa_meta',
    'helsa_settings',
    'helsa_identity',
    'helsa_gender',
    'helsa_age',
    'helsa_body',
    'helsa_activity',
    'helsa_diet',
    'helsa_restrictions',
    'helsa_favorites',
    'helsa_sleep',
    'helsa_steps_daily',
    'helsa_streak',
    'helsa_theme',
  ];

  /// Build a JSON-serializable map of the whole app state.
  static Future<Map<String, dynamic>> exportMap() async {
    await SecureHive.ensureReady();
    final boxes = <String, Map<String, dynamic>>{};
    for (final name in boxNames) {
      try {
        final box = await SecureHive.openBox(name);
        final map = <String, dynamic>{};
        for (final key in box.keys) {
          map['$key'] = _encodeValue(box.get(key));
        }
        boxes[name] = map;
      } catch (e, st) {
        debugPrint('Backup export box $name: $e\n$st');
        boxes[name] = {};
      }
    }

    String? avatarB64;
    try {
      final path = IdentityStore.avatarPath;
      if (path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          // Cap ~2MB
          if (bytes.length <= 2 * 1024 * 1024) {
            avatarB64 = base64Encode(bytes);
          }
        }
      }
    } catch (e, st) {
      debugPrint('Backup avatar: $e\n$st');
    }

    return {
      'magic': magic,
      'version': formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'boxes': boxes,
      if (avatarB64 != null) 'avatarJpgBase64': avatarB64,
    };
  }

  static dynamic _encodeValue(dynamic v) {
    if (v == null || v is num || v is bool || v is String) return v;
    if (v is List) return v.map(_encodeValue).toList();
    if (v is Map) {
      return v.map((k, val) => MapEntry('$k', _encodeValue(val)));
    }
    return v.toString();
  }

  static Uint8List encodePlainBytes(Map<String, dynamic> map) {
    final json = jsonEncode(map);
    final raw = utf8.encode(json);
    return Uint8List.fromList(gzipEncode(raw));
  }

  static Map<String, dynamic> decodePlainBytes(Uint8List gzipped) {
    final raw = gzipDecode(gzipped);
    final map = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
    if (map['magic'] != magic) {
      throw StateError('backup_corrupt');
    }
    return map;
  }

  static Uint8List gzipEncode(List<int> data) {
    return Uint8List.fromList(GZipCodec().encode(data));
  }

  static List<int> gzipDecode(List<int> data) {
    return GZipCodec().decode(data);
  }

  /// Replace local stores with [map] from a backup.
  static Future<void> importMap(Map<String, dynamic> map) async {
    await SecureHive.ensureReady();
    final boxes = map['boxes'];
    if (boxes is! Map) throw StateError('backup_corrupt');

    for (final name in boxNames) {
      try {
        final box = await SecureHive.openBox(name);
        await box.clear();
        final data = boxes[name];
        if (data is Map) {
          for (final e in data.entries) {
            await box.put(e.key, e.value);
          }
        }
      } catch (e, st) {
        debugPrint('Backup import box $name: $e\n$st');
      }
    }

    // Avatar file
    final b64 = map['avatarJpgBase64']?.toString();
    if (b64 != null && b64.isNotEmpty) {
      try {
        final bytes = base64Decode(b64);
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}${Platform.pathSeparator}avatars');
        if (!await folder.exists()) await folder.create(recursive: true);
        final dest = '${folder.path}${Platform.pathSeparator}avatar.jpg';
        await File(dest).writeAsBytes(bytes, flush: true);
        await IdentityStore.open();
        await IdentityStore.saveAvatarFile(dest);
      } catch (e, st) {
        debugPrint('Backup import avatar: $e\n$st');
      }
    }

    // Re-open notifiers
    try {
      await MetaStore.open();
      await SettingsStore.open();
      await ThemeStore.open();
      await StepsStore.open();
      await StreakStore.open();
      StepTracker.instance.profileChanged();
    } catch (e, st) {
      debugPrint('Backup post-import: $e\n$st');
    }
  }
}
