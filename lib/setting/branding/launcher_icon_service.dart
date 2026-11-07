import 'package:flutter/services.dart';

/// Switches the Android launcher icon to match the selected theme palette.
/// Requires activity-aliases in AndroidManifest + mipmap icons on disk.
class LauncherIconService {
  LauncherIconService._();

  static const MethodChannel _channel =
      MethodChannel('helsa/launcher_icon');

  /// [paletteId] e.g. mint, ocean, forest, sunrise, lavender, slate
  static Future<bool> applyForPalette(String paletteId) async {
    final key = paletteId.trim().toLowerCase();
    if (key.isEmpty) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setIcon', {
        'paletteId': key,
      });
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      // Not on Android / plugin not registered yet
      return false;
    }
  }
}
