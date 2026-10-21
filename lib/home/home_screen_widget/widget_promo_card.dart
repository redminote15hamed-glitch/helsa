// lib/home/home_screen_widget/widget_promo_card.dart
// پیش‌نمایش ویجت + دکمه اضافه به صفحهٔ اصلی
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class WidgetPromoCard extends StatefulWidget {
  final String language;

  const WidgetPromoCard({super.key, required this.language});

  @override
  State<WidgetPromoCard> createState() => _WidgetPromoCardState();
}

class _WidgetPromoCardState extends State<WidgetPromoCard> {
  static const _channel = MethodChannel('helsa/widget');
  late final int _demoSteps;
  late final int _demoCal;
  late final int _demoMin;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _demoSteps = 400 + r.nextInt(4600); // 400..4999
    _demoCal = 80 + r.nextInt(320);
    _demoMin = 5 + r.nextInt(55);
  }

  Future<void> _addWidget() async {
    if (_busy) return;
    if (kIsWeb || !Platform.isAndroid) {
      _toast(HomeText.getString(widget.language, 'widget_android_only'));
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _channel.invokeMethod<bool>('pinWidget') ?? false;
      if (!mounted) return;
      if (ok) {
        _toast(HomeText.getString(widget.language, 'widget_pin_ok'));
      } else {
        _toast(HomeText.getString(widget.language, 'widget_pin_manual'));
      }
    } catch (_) {
      if (mounted) {
        _toast(HomeText.getString(widget.language, 'widget_pin_manual'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0C1210) : const Color(0xFFF4F7F5);
    final label = isDark ? Colors.white54 : Colors.black54;
    final lang = widget.language;

    final stepsL = HomeText.getString(lang, 'steps');
    final calL = HomeText.getString(lang, 'calories');
    final timeL = HomeText.getString(lang, 'active');
    final addL = HomeText.getString(lang, 'widget_add');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.hX2s, vertical: context.vX2s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // پیش‌نمایش ویجت
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _cell(
                  icon: Icons.directions_walk_rounded,
                  color: ColorPalette.mintPrimary,
                  value: '$_demoSteps',
                  label: stepsL,
                  labelColor: label,
                ),
                _divider(label),
                _cell(
                  icon: Icons.local_fire_department_rounded,
                  color: ColorPalette.calorieBurn,
                  value: '$_demoCal',
                  label: calL,
                  labelColor: label,
                ),
                _divider(label),
                _cell(
                  icon: Icons.timer_outlined,
                  color: ColorPalette.skyBlue,
                  value: '$_demoMin',
                  label: timeL,
                  labelColor: label,
                ),
              ],
            ),
          ),
          SizedBox(height: context.vX2s),
          // دکمه + اضافه کردن ویجت
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _busy ? null : _addWidget,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorPalette.mintPrimary.withValues(alpha: 0.15),
                        border: Border.all(color: ColorPalette.mintPrimary, width: 1.5),
                      ),
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add, color: ColorPalette.mintPrimary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      addL,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(Color c) => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: c.withValues(alpha: 0.35),
      );

  Widget _cell({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color labelColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
        ],
      ),
    );
  }
}
