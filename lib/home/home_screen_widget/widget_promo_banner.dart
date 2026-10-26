// lib/home/home_screen_widget/widget_promo_banner.dart
// Dismissible alert: add home-screen widget. X hides forever (MetaStore).
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';

class WidgetPromoBanner extends StatefulWidget {
  final String language;

  const WidgetPromoBanner({super.key, required this.language});

  @override
  State<WidgetPromoBanner> createState() => _WidgetPromoBannerState();
}

class _WidgetPromoBannerState extends State<WidgetPromoBanner> {
  static const _channel = MethodChannel('helsa/widget');
  bool _busy = false;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    try {
      _visible = !MetaStore.widgetPromoDismissed;
    } catch (_) {
      _visible = true;
    }
  }

  Future<void> _dismiss() async {
    try {
      await MetaStore.setWidgetPromoDismissed(true);
    } catch (_) {}
    if (mounted) setState(() => _visible = false);
  }

  Future<void> _addWidget() async {
    if (_busy) return;
    if (kIsWeb || !Platform.isAndroid) {
      _banner(
        HomeText.getString(widget.language, 'widget_android_only'),
        error: true,
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await _channel.invokeMethod<bool>('pinWidget') ?? false;
      if (!mounted) return;
      if (ok) {
        _banner(
          HomeText.getString(widget.language, 'widget_pin_ok'),
          error: false,
        );
        // Pin requested successfully — hide promo permanently
        await _dismiss();
      } else {
        _banner(
          HomeText.getString(widget.language, 'widget_pin_manual'),
          error: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _banner(
          HomeText.getString(widget.language, 'widget_pin_error'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _banner(String msg, {required bool error}) {
    SnackBarer.show(
      context,
      message: msg,
      template: error ? SnackbarTemplate.caution : SnackbarTemplate.neutral,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.language;
    final message = HomeText.getString(lang, 'widget_promo_msg');
    final addLabel = HomeText.getString(lang, 'widget_add_short');

    final bg = isDark
        ? ColorPalette.mintPrimary.withValues(alpha: 0.14)
        : ColorPalette.mintPrimary.withValues(alpha: 0.10);
    final border = ColorPalette.mintPrimary.withValues(alpha: 0.35);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.hX2s,
        context.vX2s,
        context.hX2s,
        context.vX2s,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            context.hX2s,
            context.vX2s,
            context.hX3s,
            context.vX2s,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.widgets_outlined,
                    size: 20,
                    color: ColorPalette.mintPrimary,
                  ),
                  SizedBox(width: context.hX3s),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  SizedBox(width: context.hX3s),
                  InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.vX2s),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _busy ? null : _addWidget,
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: ColorPalette.mintPrimary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 10,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                addLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
