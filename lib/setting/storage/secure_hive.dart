// lib/setting/storage/secure_hive.dart
// AES-256 Hive encryption. Key lives in platform secure storage only.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Central encrypted Hive access for Helsa.
///
/// - Key: 256-bit, generated once, stored in Android Keystore /
///   iOS Keychain via [FlutterSecureStorage] (never in Hive, never in prefs).
/// - Boxes: opened with [HiveAesCipher] (AES-256).
/// - Migration: existing plaintext boxes are copied into a new encrypted box
///   once, then the plain file is deleted.
class SecureHive {
  SecureHive._();

  static const String _keyStorageId = 'helsa_hive_aes_key_v1';

  /// Compatible with flutter_secure_storage 9.x and 10.x+
  /// (encryptedSharedPreferences was removed in v10 — encryption is default).
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Uint8List? _keyBytes;
  static HiveAesCipher? _cipher;
  static Future<void>? _ready;

  /// Call once before any box open (also implied by [openBox]).
  static Future<void> ensureReady() {
    return _ready ??= _init();
  }

  static Future<void> _init() async {
    try {
      final existing = await _secure.read(key: _keyStorageId);
      if (existing != null && existing.isNotEmpty) {
        final decoded = base64Decode(existing);
        if (decoded.length == 32) {
          _keyBytes = Uint8List.fromList(decoded);
        }
      }
    } catch (e, st) {
      debugPrint('SecureHive key read failed: $e\n$st');
    }

    if (_keyBytes == null) {
      final generated = Hive.generateSecureKey(); // 32 bytes
      _keyBytes = Uint8List.fromList(generated);
      try {
        await _secure.write(
          key: _keyStorageId,
          value: base64Encode(_keyBytes!),
        );
      } catch (e, st) {
        debugPrint('SecureHive key write failed: $e\n$st');
        // Still use in-memory key this session so app can run.
      }
    }

    _cipher = HiveAesCipher(_keyBytes!);
  }

  static HiveAesCipher get _c {
    final c = _cipher;
    if (c == null) {
      throw StateError('SecureHive.ensureReady() required');
    }
    return c;
  }

  /// Open (or create) an AES-encrypted box. Migrates plain data if needed.
  static Future<Box<dynamic>> openBox(String name) async {
    await ensureReady();
    final cipher = _c;

    // Prefer encrypted open.
    try {
      final box = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: cipher,
      );
      // Touch once — wrong cipher often surfaces on first read/write.
      if (box.isNotEmpty) {
        box.keys.first;
      }
      return box;
    } catch (e) {
      debugPrint('SecureHive encrypted open "$name": $e — try migrate');
    }

    // Plaintext leftover from older builds → migrate once.
    if (await Hive.boxExists(name)) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box<dynamic>(name).close();
        }
      } catch (_) {}

      try {
        final plain = await Hive.openBox<dynamic>(name);
        final snapshot = Map<dynamic, dynamic>.from(plain.toMap());
        await plain.close();
        await Hive.deleteBoxFromDisk(name);

        final encrypted = await Hive.openBox<dynamic>(
          name,
          encryptionCipher: cipher,
        );
        if (snapshot.isNotEmpty) {
          await encrypted.putAll(snapshot);
        }
        debugPrint(
          'SecureHive migrated "$name" (${snapshot.length} keys) → encrypted',
        );
        return encrypted;
      } catch (e, st) {
        debugPrint('SecureHive migrate "$name" failed: $e\n$st');
        try {
          if (Hive.isBoxOpen(name)) {
            await Hive.box<dynamic>(name).close();
          }
          await Hive.deleteBoxFromDisk(name);
        } catch (_) {}
      }
    }

    return Hive.openBox<dynamic>(name, encryptionCipher: cipher);
  }
}
