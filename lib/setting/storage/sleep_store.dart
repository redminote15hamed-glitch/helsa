// lib/setting/storage/sleep_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class SleepStore {
  SleepStore._();
  static const String boxName = 'helsa_sleep';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('SleepStore.open() required');
    }
    return b;
  }

  static String? get sleepTime => _b.get('sleepTime')?.toString();
  static String? get wakeTime => _b.get('wakeTime')?.toString();

  static Future<void> save({
    String? sleepTime,
    String? wakeTime,
  }) async {
    await _b.put('sleepTime', sleepTime);
    await _b.put('wakeTime', wakeTime);
  }

  static Future<void> clear() => _b.clear();
}
