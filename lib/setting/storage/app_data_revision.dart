// lib/setting/storage/app_data_revision.dart
// Global bump after profile/data deletes so UI reloads empty state everywhere.
import 'package:flutter/foundation.dart';

/// Incremented whenever user data is cleared or should force a UI refresh.
class AppDataRevision {
  AppDataRevision._();

  static final ValueNotifier<int> listenable = ValueNotifier<int>(0);

  static int get value => listenable.value;

  /// Call after any store clear / privacy delete / profile wipe.
  static void bump() {
    listenable.value = listenable.value + 1;
  }
}
