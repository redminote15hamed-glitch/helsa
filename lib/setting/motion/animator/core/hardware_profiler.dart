import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'speeds.dart';
import 'theme.dart';

enum DeviceTier { low, medium, high }

abstract class HardwareProfiler {
  static bool _isLowEndOverride = false;

  /// TEMP debug: set true to force 3D on all devices.
  static bool forceHighEnd = false;
  static ThemePackage currentTheme = ThemePackage.standard;
  static DeviceTier? _cachedTier;

  static int? _cpuCores;
  static int? _ramMB;
  static int? _androidSdk;

  static double? _freeStorageGB;
  static double? _freeStorageRatio;

  static bool _initialized = false;

  static void setLowEndMode(bool enable) {
    _isLowEndOverride = enable;
    _cachedTier = null;
  }

  static void setTheme(ThemePackage theme) => currentTheme = theme;

  static bool get isInitialized => _initialized;

  /// Call once at app startup (before runApp is best).
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _androidSdk = info.version.sdkInt;
        // physicalRamSize is in MB in device_info_plus
        var ram = info.physicalRamSize;
        // guard: some devices/plugins report bytes
        if (ram > 100000) {
          ram = ram ~/ (1024 * 1024);
        }
        _ramMB = ram;

        try {
          final free = info.freeDiskSize;
          final total = info.totalDiskSize;
          if (free > 0) {
            _freeStorageGB = free / (1024 * 1024 * 1024);
          }
          if (free > 0 && total > 0) {
            _freeStorageRatio = free / total;
          }
        } catch (_) {}
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        try {
          final free = info.freeDiskSize;
          final total = info.totalDiskSize;
          if (free > 0) {
            _freeStorageGB = free / (1024 * 1024 * 1024);
          }
          if (free > 0 && total > 0) {
            _freeStorageRatio = free / total;
          }
        } catch (_) {}
        _cpuCores = null;
        _ramMB = null;
      }
    } catch (_) {}

    if (_freeStorageRatio == null) {
      try {
        final disk = DiskSpacePlus();
        final freeMB = await disk.getFreeDiskSpace;
        final totalMB = await disk.getTotalDiskSpace;
        if (freeMB != null && freeMB > 0) {
          _freeStorageGB = freeMB / 1024;
        }
        if (freeMB != null &&
            totalMB != null &&
            freeMB > 0 &&
            totalMB > 0) {
          _freeStorageRatio = freeMB / totalMB;
        }
      } catch (_) {}
    }

    _cachedTier = null;
  }

  /// Priority: RAM (strong) → Refresh → Storage% → CPU → Android version
  static DeviceTier getDeviceTier() {
    if (forceHighEnd) return DeviceTier.high;
    if (_isLowEndOverride) return DeviceTier.low;

    // وب / دسکتاپ: بدون رم اندروید → high (مکعب برای تست)
    final bool desktopLike = kIsWeb ||
        (!Platform.isAndroid && !Platform.isIOS);
    if (!_initialized) {
      return desktopLike ? DeviceTier.high : DeviceTier.low;
    }

    if (_cachedTier != null) return _cachedTier!;

    int score = 0;

    // —— RAM: قوی‌ترین سیگنال برای گوشی قدیمی مثل A10s (۲–۳GB) ——
    if (_ramMB != null) {
      if (_ramMB! <= 3072) {
        // A10 / A10s class
        score += 4;
      } else if (_ramMB! <= 4096) {
        score += 3;
      } else if (_ramMB! <= 6144) {
        score += 1;
      } else if (_ramMB! >= 8192) {
        score -= 1;
      }
    }

    final rate = PlatformDispatcher.instance.views.first.display.refreshRate;
    if (rate > 0 && rate < 50) {
      score += 3;
    } else if (rate >= 90) {
      score -= 1;
    }

    if (_cpuCores != null) {
      if (_cpuCores! <= 4) {
        score += 2;
      } else if (_cpuCores! >= 8) {
        score -= 1;
      }
    }

    if (_freeStorageRatio != null) {
      final r = _freeStorageRatio!;
      if (r < 0.10) {
        score += 3;
      } else if (r < 0.25) {
        score += 2;
      } else if (r < 0.35) {
        score += 1;
      }
    } else if (_freeStorageGB != null) {
      if (_freeStorageGB! < 2) {
        score += 2;
      } else if (_freeStorageGB! < 5) {
        score += 1;
      }
    }

    // Android 9 (SDK 28) و قدیمی‌تر — مثل دستگاه تو
    if (_androidSdk != null) {
      if (_androidSdk! <= 28) {
        score += 2; // Android 9 و پایین
      } else if (_androidSdk! <= 29) {
        score += 1; // Android 10
      }
    }

    // آستانه low: score >= 3
    // وب/دسکتاپ بدون داده رم → قوی فرض کن
    if (_ramMB == null && _androidSdk == null && desktopLike) {
      _cachedTier = DeviceTier.high;
      return _cachedTier!;
    }

    if (score >= 3) {
      _cachedTier = DeviceTier.low;
    } else if (score <= 0) {
      _cachedTier = DeviceTier.high;
    } else {
      _cachedTier = DeviceTier.medium;
    }

    return _cachedTier!;
  }

  static bool isLowEndDevice() => getDeviceTier() == DeviceTier.low;

  static double? get freeStorageRatio => _freeStorageRatio;
  static double? get freeStorageGB => _freeStorageGB;
  static int? get ramMB => _ramMB;
  static DeviceTier get debugTier => getDeviceTier();

  static Duration getOptimizedSpeed(
    Duration intended, {
    required bool ignoreHW,
    BuildContext? context,
  }) {
    if (ignoreHW) return intended;

    if (context != null && MediaQuery.disableAnimationsOf(context)) {
      return AS.veryFast;
    }

    switch (getDeviceTier()) {
      case DeviceTier.low:
        return AS.speedy;
      case DeviceTier.medium:
        if (intended > AS.balanced) return AS.balanced;
        return intended;
      case DeviceTier.high:
        return intended;
    }
  }

  static bool shouldAllowHeavyEffects({
    required bool ignoreHW,
    BuildContext? context,
  }) {
    if (ignoreHW) return true;

    if (context != null && MediaQuery.disableAnimationsOf(context)) {
      return false;
    }

    final config = AnimatorThemeConfig.of(currentTheme);
    if (!config.enableBlur) return false;

    return getDeviceTier() != DeviceTier.low;
  }
}
