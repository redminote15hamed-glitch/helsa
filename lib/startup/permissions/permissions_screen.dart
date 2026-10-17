// lib/startup/permissions/permissions_screen.dart
// بعد از Review — قبل از Home. تم متفاوت، بدون SetupHeader.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:helsa/home/home_screen.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';

class PermissionsScreen extends StatefulWidget {
  final String language;

  const PermissionsScreen({super.key, required this.language});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _activity = false;
  bool _notification = false;
  bool _battery = false;
  bool _checking = true;

  String get _lang {
    final c = widget.language.toLowerCase();
    if (c.startsWith('fa')) return 'fa';
    if (c.startsWith('fr')) return 'fr';
    return 'en';
  }

  String _t(String key) {
    const m = {
      'fa': {
        'title': 'دسترسی‌ها',
        'subtitle': 'برای کار درست قدم‌شمار و اعلان‌ها، این دسترسی‌ها لازم است.',
        'activity': 'فعالیت بدنی',
        'activity_desc': 'شمارش قدم و تشخیص پیاده‌روی',
        'notification': 'اعلان‌ها',
        'notification_desc': 'نمایش زنده تعداد قدم',
        'battery': 'بهینه‌سازی باتری',
        'battery_desc': 'جلوگیری از توقف شمارش در پس‌زمینه',
        'autostart': 'شروع خودکار',
        'autostart_desc': 'اجازه اجرا پس از روشن شدن گوشی (در تنظیمات گوشی)',
        'allow': 'اجازه',
        'settings': 'تنظیمات',
        'start': 'شروع',
        'done': 'انجام شد',
      },
      'en': {
        'title': 'Permissions',
        'subtitle':
            'These permissions are needed for step counting and notifications.',
        'activity': 'Physical activity',
        'activity_desc': 'Step count and walking detection',
        'notification': 'Notifications',
        'notification_desc': 'Live step updates',
        'battery': 'Battery optimization',
        'battery_desc': 'Keep counting in the background',
        'autostart': 'Auto-start',
        'autostart_desc': 'Allow launch after reboot (device settings)',
        'allow': 'Allow',
        'settings': 'Settings',
        'start': 'Start',
        'done': 'Done',
      },
      'fr': {
        'title': 'Autorisations',
        'subtitle':
            'Ces autorisations sont nécessaires pour le compteur et les notifications.',
        'activity': 'Activité physique',
        'activity_desc': 'Pas et détection de marche',
        'notification': 'Notifications',
        'notification_desc': 'Mise à jour en direct des pas',
        'battery': 'Optimisation batterie',
        'battery_desc': 'Continuer en arrière-plan',
        'autostart': 'Démarrage auto',
        'autostart_desc': 'Lancer après redémarrage (réglages)',
        'allow': 'Autoriser',
        'settings': 'Réglages',
        'start': 'Démarrer',
        'done': 'Fait',
      },
    };
    return m[_lang]?[key] ?? m['en']![key]!;
  }

  /// برای Start: فعالیت + اعلان کافی است؛ باتری و autostart توصیه‌ای‌اند
  bool get _canStart => _activity && _notification;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (kIsWeb) {
      setState(() {
        _activity = true;
        _notification = true;
        _battery = true;
        _checking = false;
      });
      return;
    }
    final ar = await Permission.activityRecognition.status;
    final sensors = await Permission.sensors.status;
    final notif = await Permission.notification.status;
    final bat = await Permission.ignoreBatteryOptimizations.status;
    if (!mounted) return;
    setState(() {
      _activity = ar.isGranted || sensors.isGranted;
      _notification = notif.isGranted || notif.isLimited;
      _battery = bat.isGranted;
      _checking = false;
    });
  }

  Future<void> _requestActivity() async {
    var s = await Permission.activityRecognition.request();
    if (!s.isGranted) {
      s = await Permission.sensors.request();
    }
    if (s.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _refresh();
  }

  Future<void> _requestNotification() async {
    final s = await Permission.notification.request();
    if (s.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _refresh();
  }

  Future<void> _requestBattery() async {
    final s = await Permission.ignoreBatteryOptimizations.request();
    if (!s.isGranted) {
      await openAppSettings();
    }
    await _refresh();
  }

  Future<void> _openAutoStartSettings() async {
    // OEM-specific autostart قابل اجبار نیست → تنظیمات اپ / باتری
    await openAppSettings();
    await _refresh();
  }

  Future<void> _onStart() async {
    if (!_canStart) return;
    try {
      await MetaStore.setSetupDone(true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // تم متفاوت از setup: ته‌آبی/یشمی، نه فقط سبز setup
    final bg = isDark ? const Color(0xFF0A1628) : const Color(0xFFEEF4FF);
    final card = isDark ? const Color(0xFF132238) : Colors.white;
    final accent = ColorPalette.skyBlue;
    final accent2 = ColorPalette.mintAccent;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.hM,
            vertical: context.vS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: context.vS),
              // زنگوله تأکید با رنگ‌های متفاوت
              Center(
                child: Container(
                  width: context.baseScale * 4.2,
                  height: context.baseScale * 4.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.25),
                        accent2.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: context.baseScale * 2.1,
                    color: accent,
                  ),
                ),
              ),
              SizedBox(height: context.vS),
              Text(
                _t('title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.l,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: context.vX3s),
              Text(
                _t('subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.m * 0.9,
                  color: (isDark ? Colors.white : const Color(0xFF0F172A))
                      .withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: context.vM),
              Expanded(
                child: _checking
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        children: [
                          _PermTile(
                            cardColor: card,
                            accent: accent,
                            icon: Icons.directions_walk_rounded,
                            title: _t('activity'),
                            subtitle: _t('activity_desc'),
                            granted: _activity,
                            actionLabel: _t('allow'),
                            doneLabel: _t('done'),
                            onAction: _requestActivity,
                          ),
                          SizedBox(height: context.vX2s),
                          _PermTile(
                            cardColor: card,
                            accent: accent,
                            icon: Icons.notifications_outlined,
                            title: _t('notification'),
                            subtitle: _t('notification_desc'),
                            granted: _notification,
                            actionLabel: _t('allow'),
                            doneLabel: _t('done'),
                            onAction: _requestNotification,
                          ),
                          SizedBox(height: context.vX2s),
                          _PermTile(
                            cardColor: card,
                            accent: ColorPalette.calorieBurn,
                            icon: Icons.battery_charging_full_rounded,
                            title: _t('battery'),
                            subtitle: _t('battery_desc'),
                            granted: _battery,
                            actionLabel: _t('allow'),
                            doneLabel: _t('done'),
                            onAction: _requestBattery,
                          ),
                          if (!kIsWeb && Platform.isAndroid) ...[
                            SizedBox(height: context.vX2s),
                            _PermTile(
                              cardColor: card,
                              accent: accent2,
                              icon: Icons.rocket_launch_outlined,
                              title: _t('autostart'),
                              subtitle: _t('autostart_desc'),
                              granted: false, // فقط از تنظیمات OEM
                              alwaysShowSettings: true,
                              actionLabel: _t('settings'),
                              doneLabel: _t('done'),
                              onAction: _openAutoStartSettings,
                            ),
                          ],
                        ],
                      ),
              ),
              SizedBox(height: context.vS),
              FilledButton(
                onPressed: _canStart ? _onStart : null,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: accent.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: context.vS),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _t('start'),
                  style: TextStyle(
                    fontSize: context.m,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: context.vX2s),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  final Color cardColor;
  final Color accent;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final bool alwaysShowSettings;
  final String actionLabel;
  final String doneLabel;
  final VoidCallback onAction;

  const _PermTile({
    required this.cardColor,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.actionLabel,
    required this.doneLabel,
    required this.onAction,
    this.alwaysShowSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    final showCheck = granted && !alwaysShowSettings;
    return Container(
      padding: EdgeInsets.all(context.m),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: showCheck
              ? ColorPalette.mintPrimary.withValues(alpha: 0.45)
              : accent.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          SizedBox(width: context.hS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.m * 0.95,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: context.s * 0.9,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.hX3s),
          if (showCheck)
            Icon(Icons.check_circle_rounded,
                color: ColorPalette.mintPrimary, size: 28)
          else
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
