// lib/home/menu/menu_widget_page.dart
// Widget hub: Genie open from menu → preview cards + pin to launcher.
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/home_screen_widget/home_widget_bridge.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class MenuWidgetPage {
  MenuWidgetPage._();

  static Future<void> show(
    BuildContext context, {
    required String language,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'widgets',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, a, b) {
        return _WidgetHost(
          language: language,
          theme: Theme.of(context),
        );
      },
    );
  }
}

class _WidgetHost extends StatefulWidget {
  final String language;
  final ThemeData theme;

  const _WidgetHost({required this.language, required this.theme});

  @override
  State<_WidgetHost> createState() => _WidgetHostState();
}

class _WidgetHostState extends State<_WidgetHost> {
  bool _closing = false;
  int _genieKey = 0;
  Timer? _forcePop;

  void _requestClose() {
    if (_closing) return;
    setState(() {
      _closing = true;
      _genieKey++;
    });
    _forcePop?.cancel();
    _forcePop = Timer(const Duration(milliseconds: 1100), _onExitDone);
  }

  void _onExitDone() {
    _forcePop?.cancel();
    _forcePop = null;
    if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  void dispose() {
    _forcePop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const edge = GenieEdge.start;

    final page = _WidgetEditor(
      language: widget.language,
      theme: widget.theme,
      onRequestClose: _requestClose,
    );

    final genieChild = KeyedSubtree(
      key: ValueKey(_closing ? 'ex-$_genieKey' : 'en-$_genieKey'),
      child: _closing
          ? page.exGenieReal(
              context,
              s: AS.balanced,
              edge: edge,
              strips: 40,
              onComplete: _onExitDone,
            )
          : page.enGenieReal(
              context,
              s: AS.slow,
              edge: edge,
              strips: 40,
            ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _requestClose,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned.fill(child: genieChild),
        ],
      ),
    );
  }
}

class _WidgetEditor extends StatefulWidget {
  final String language;
  final ThemeData theme;
  final VoidCallback onRequestClose;

  const _WidgetEditor({
    required this.language,
    required this.theme,
    required this.onRequestClose,
  });

  @override
  State<_WidgetEditor> createState() => _WidgetEditorState();
}

class _WidgetEditorState extends State<_WidgetEditor> {
  static const _channel = MethodChannel('helsa/widget');
  bool _busyMain = false;
  bool _busySteps = false;

  String get _lang => widget.language;

  Future<void> _pin({required bool stepsOnly}) async {
    if (kIsWeb || !Platform.isAndroid) {
      _toast(HomeText.getString(_lang, 'widget_android_only'), error: true);
      return;
    }
    setState(() {
      if (stepsOnly) {
        _busySteps = true;
      } else {
        _busyMain = true;
      }
    });
    try {
      await HomeWidgetBridge.instance.push(force: true);
      final ok = await _channel.invokeMethod<bool>(
            'pinWidget',
            <String, dynamic>{'stepsOnly': stepsOnly},
          ) ??
          false;
      if (!mounted) return;
      if (ok) {
        _toast(HomeText.getString(_lang, 'widget_pin_ok'), error: false);
      } else {
        _toast(HomeText.getString(_lang, 'widget_pin_manual'), error: true);
      }
    } catch (_) {
      if (mounted) {
        try {
          final ok = await _channel.invokeMethod<bool>('pinWidget') ?? false;
          if (!mounted) return;
          _toast(
            HomeText.getString(
              _lang,
              ok ? 'widget_pin_ok' : 'widget_pin_manual',
            ),
            error: !ok,
          );
        } catch (_) {
          if (mounted) {
            _toast(HomeText.getString(_lang, 'widget_pin_error'), error: true);
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyMain = false;
          _busySteps = false;
        });
      }
    }
  }

  void _toast(String msg, {required bool error}) {
    SnackBarer.show(
      context,
      message: msg,
      template: error ? SnackbarTemplate.caution : SnackbarTemplate.neutral,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final t = StepTracker.instance;

    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.hX2s,
                top + context.vX2s,
                context.hX2s,
                context.vX2s,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onRequestClose,
                    icon: Icon(Icons.close_rounded, color: cs.onSurface),
                  ),
                  Expanded(
                    child: TextFielder(
                      text: HomeText.getString(_lang, 'menu_widget'),
                      languageCode: _lang,
                      template: TextTemplate.subtitle,
                      textAlign: TextAlign.center,
                      customStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.hS,
                  context.vS,
                  context.hS,
                  bottom + context.vXl,
                ),
                children: [
                  TextFielder(
                    text: HomeText.getString(_lang, 'widget_hub_intro'),
                    languageCode: _lang,
                    template: TextTemplate.body,
                    textAlign: TextAlign.center,
                    customStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: context.vS),
                  _PreviewCard(
                    title: HomeText.getString(_lang, 'widget_hub_main_title'),
                    subtitle:
                        HomeText.getString(_lang, 'widget_hub_main_desc'),
                    busy: _busyMain,
                    addLabel: HomeText.getString(_lang, 'widget_add'),
                    onAdd: () => _pin(stepsOnly: false),
                    child: _MainPreview(
                      language: _lang,
                      steps: t.steps,
                      stepsGoal: t.stepsGoal,
                      cal: t.calories.round(),
                      calGoal: t.caloriesGoal.round(),
                      mins: t.activeMinutes,
                      minsGoal: t.activeMinutesGoal,
                    ),
                  ),
                  SizedBox(height: context.vS),
                  _PreviewCard(
                    title: HomeText.getString(_lang, 'widget_hub_steps_title'),
                    subtitle:
                        HomeText.getString(_lang, 'widget_hub_steps_desc'),
                    busy: _busySteps,
                    addLabel: HomeText.getString(_lang, 'widget_add'),
                    onAdd: () => _pin(stepsOnly: true),
                    child: _StepsPreview(
                      language: _lang,
                      steps: t.steps,
                      stepsGoal: t.stepsGoal,
                    ),
                  ),
                  SizedBox(height: context.vS),
                  TextFielder(
                    text: HomeText.getString(_lang, 'widget_hub_hint'),
                    languageCode: _lang,
                    template: TextTemplate.caption,
                    textAlign: TextAlign.center,
                    customStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool busy;
  final String addLabel;
  final VoidCallback onAdd;

  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.busy,
    required this.addLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(context.hS),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ColorPalette.mintPrimary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.3,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: context.vX2s),
          child,
          SizedBox(height: context.vX2s),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: busy ? null : onAdd,
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  decoration: BoxDecoration(
                    color: ColorPalette.mintPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 11,
                    ),
                    child: busy
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
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainPreview extends StatelessWidget {
  final String language;
  final int steps, stepsGoal, cal, calGoal, mins, minsGoal;

  const _MainPreview({
    required this.language,
    required this.steps,
    required this.stepsGoal,
    required this.cal,
    required this.calGoal,
    required this.mins,
    required this.minsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121820) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricCol(
              color: ColorPalette.mintPrimary,
              icon: Icons.directions_walk_rounded,
              label: HomeText.getString(language, 'steps'),
              value: '$steps',
              goal: '$stepsGoal',
            ),
          ),
          Expanded(
            child: _MetricCol(
              color: ColorPalette.calorieBurn,
              icon: Icons.local_fire_department_rounded,
              label: HomeText.getString(language, 'kcal'),
              value: '$cal',
              goal: '$calGoal',
            ),
          ),
          Expanded(
            child: _MetricCol(
              color: ColorPalette.skyBlue,
              icon: Icons.timer_outlined,
              label: HomeText.getString(language, 'minutes'),
              value: '$mins',
              goal: '$minsGoal',
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsPreview extends StatelessWidget {
  final String language;
  final int steps, stepsGoal;

  const _StepsPreview({
    required this.language,
    required this.steps,
    required this.stepsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct =
        stepsGoal <= 0 ? 0.0 : (steps / stepsGoal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121820) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk_rounded,
                  color: ColorPalette.mintPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                HomeText.getString(language, 'steps'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ColorPalette.mintPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$steps',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor:
                  ColorPalette.mintPrimary.withValues(alpha: 0.18),
              color: ColorPalette.mintPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$steps / $stepsGoal',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String goal;

  const _MetricCol({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          '/ $goal',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
