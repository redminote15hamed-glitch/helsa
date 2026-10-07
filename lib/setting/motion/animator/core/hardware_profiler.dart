import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'speeds.dart';
import 'theme.dart';

enum DeviceTier { low, medium, high }

abstract class HardwareProfiler {
  static bool _isLowEndOverride = false;
  static ThemePackage currentTheme = ThemePackage.standard;
  static DeviceTier? _cachedTier;

  static int? _cpuCores;
  static int? _ramMB;
  static int? _androidSdk;

  /// فضای خالی به گیگ (فقط برای لاگ / دیباگ)
  static double? _freeStorageGB;

  /// نسبت فضای خالی به کل (۰.۰ تا ۱.۰) — ملاک اصلی ذخیره‌سازی
  static double? _freeStorageRatio;

  static bool _initialized = false;

  static void setLowEndMode(bool enable) {
    _isLowEndOverride = enable;
    _cachedTier = null;
  }

  static void setTheme(ThemePackage theme) => currentTheme = theme;

  /// Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final plugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _androidSdk = info.version.sdkInt;
        _ramMB = info.physicalRamSize;
        // freeDiskSize / totalDiskSize در نسخه‌های جدید device_info_plus
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

    // fallback: disk_space_plus (درصد از free/total)
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

  /// Priority: Refresh Rate → CPU → Free Storage % → RAM → Android version
  static DeviceTier getDeviceTier() {
    if (_isLowEndOverride) return DeviceTier.low;
    if (_cachedTier != null) return _cachedTier!;

    int score = 0;

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

    // —— فضای خالی بر حسب درصد (نه گیگ مطلق) ——
    // مثال: دیسک ۱۲۵۶GB با ۶۰GB خالی ≈ ۴.۸٪ → ضعیف
    if (_freeStorageRatio != null) {
      final r = _freeStorageRatio!;
      if (r < 0.10) {
        // کمتر از ۱۰٪ خالی
        score += 3;
      } else if (r < 0.25) {
        // کمتر از ۲۵٪ خالی
        score += 2;
      } else if (r < 0.35) {
        // کمتر از ۳۵٪ خالی
        score += 1;
      }
      // ≥ ۳۵٪ خالی → بدون مشکل، امتیاز ذخیره‌سازی صفر
    } else if (_freeStorageGB != null) {
      // فقط اگر درصد در دسترس نبود، حداقل مطلق خیلی کم
      if (_freeStorageGB! < 2) {
        score += 2;
      } else if (_freeStorageGB! < 5) {
        score += 1;
      }
    }

    if (_ramMB != null) {
      if (_ramMB! <= 4096) {
        score += 2;
      } else if (_ramMB! <= 6144) {
        score += 1;
      } else if (_ramMB! >= 8192) {
        score -= 1;
      }
    }

    if (_androidSdk != null && _androidSdk! <= 28) {
      score += 1;
    }

    if (score >= 4) {
      _cachedTier = DeviceTier.low;
    } else if (score <= 0) {
      _cachedTier = DeviceTier.high;
    } else {
      _cachedTier = DeviceTier.medium;
    }

    return _cachedTier!;
  }

  static bool isLowEndDevice() => getDeviceTier() == DeviceTier.low;

  /// برای دیباگ
  static double? get freeStorageRatio => _freeStorageRatio;
  static double? get freeStorageGB => _freeStorageGB;

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
