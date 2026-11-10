// lib/setting/backup/backup_crypto.dart
// Password-based AES-256-CBC for Helsa backup blobs (PBKDF2-HMAC-SHA256).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class BackupCrypto {
  BackupCrypto._();

  static const int _iterations = 100000;
  static const int _saltLen = 16;
  static const int _ivLen = 16;

  /// PBKDF2-HMAC-SHA256 → 32-byte key.
  static Uint8List deriveKey(String password, Uint8List salt) {
    final pass = utf8.encode(password);
    final hmac = Hmac(sha256, pass);
    // INT(1) big-endian for first block
    final block = Uint8List.fromList([...salt, 0, 0, 0, 1]);
    var u = Uint8List.fromList(hmac.convert(block).bytes);
    final result = Uint8List.fromList(u);
    for (var i = 1; i < _iterations; i++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result; // 32 bytes
  }

  static Uint8List _randomBytes(int n) {
    final r = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => r.nextInt(256)));
  }

  /// salt || iv || ciphertext
  static Uint8List encrypt(Uint8List plain, String password) {
    final salt = _randomBytes(_saltLen);
    final iv = _randomBytes(_ivLen);
    final key = deriveKey(password, salt);
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plain, iv: enc.IV(iv));
    return Uint8List.fromList([...salt, ...iv, ...encrypted.bytes]);
  }

  static Uint8List decrypt(Uint8List blob, String password) {
    if (blob.length < _saltLen + _ivLen + 16) {
      throw StateError('backup_corrupt');
    }
    final salt = Uint8List.fromList(blob.sublist(0, _saltLen));
    final iv = Uint8List.fromList(blob.sublist(_saltLen, _saltLen + _ivLen));
    final cipher =
        Uint8List.fromList(blob.sublist(_saltLen + _ivLen));
    final key = deriveKey(password, salt);
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
    try {
      final decrypted =
          encrypter.decryptBytes(enc.Encrypted(cipher), iv: enc.IV(iv));
      return Uint8List.fromList(decrypted);
    } catch (_) {
      throw StateError('backup_bad_password');
    }
  }
}
