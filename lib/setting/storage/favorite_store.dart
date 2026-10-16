// lib/setting/storage/favorite_store.dart
import 'package:hive_flutter/hive_flutter.dart';

class FavoriteStore {
  FavoriteStore._();
  static const String boxName = 'helsa_favorites';
  static Box<dynamic>? _box;

  static Future<void> open() async {
    _box ??= await Hive.openBox(boxName);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null || !b.isOpen) {
      throw StateError('FavoriteStore.open() required');
    }
    return b;
  }

  static List<int> get list {
    final v = _b.get('list');
    if (v is List) {
      return v.map((e) => (e as num).toInt()).toList();
    }
    return const [];
  }

  static Future<void> save(List<int> value) =>
      _b.put('list', List<int>.from(value));

  static Future<void> clear() => _b.clear();
}
