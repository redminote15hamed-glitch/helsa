// lib/home/menu/menu_appearance_page.dart
// Local preview only until check/continue. Orbit rotates fully. Hearts are indicators.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/theme_store.dart';

class MenuAppearancePage extends StatefulWidget {
  final String language;
  const MenuAppearancePage({super.key, required this.language});

  @override
  State<MenuAppearancePage> createState() => _MenuAppearancePageState();
}

class _MenuAppearancePageState extends State<MenuAppearancePage>
    with TickerProviderStateMixin {
  late int _index;
  late bool _night;
  late final AnimationController _spin;
  late final AnimationController _genie;
  Animation<double>? _spinAnim;
  double _rotation = 0; // radians

  String get _lang => widget.language;
  List<HelsaPalette> get _all => HelsaPalette.all;
  HelsaPalette get _current => _all[_index];

  bool get _dirty =>
      _current.id != ThemeStore.paletteId.value ||
      _night != ThemeStore.night.value;

  static double _angleForIndex(int index, int n) =>
      -math.pi / 2 - (index / n) * 2 * math.pi;

  @override
  void initState() {
    super.initState();
    final id = ThemeStore.paletteId.value;
    _index = _all.indexWhere((p) => p.id == id);
    if (_index < 0) _index = 0;
    _night = ThemeStore.night.value;
    _rotation = _angleForIndex(_index, _all.length);

    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..addListener(() {
        if (_spinAnim != null) {
          setState(() => _rotation = _spinAnim!.value);
        }
      });

    _genie = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..value = 1;
  }

  @override
  void dispose() {
    _spin.dispose();
    _genie.dispose();
    super.dispose();
  }

  Future<void> _selectIndex(int i) async {
    if (i == _index && _spin.isAnimating == false) {
      // still refresh genie lightly
      return;
    }
    final n = _all.length;
    final start = _rotation;
    // shortest path toward target angle for this index
    var target = _angleForIndex(i, n);
    // normalize delta to [-pi, pi] range for smoothness across wraps
    var delta = target - start;
    while (delta > math.pi) {
      target -= 2 * math.pi;
      delta = target - start;
    }
    while (delta < -math.pi) {
      target += 2 * math.pi;
      delta = target - start;
    }

    setState(() => _index = i);
    _genie.value = 0;
    _spinAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _spin, curve: Curves.easeInOutCubic),
    );
    await _spin.forward(from: 0);
    _rotation = target;
    await _genie.forward(from: 0);
    if (mounted) setState(() {});
  }

  void _setNight(bool v) {
    if (_night == v) return;
    setState(() => _night = v);
  }

  Future<void> _saveAndClose() async {
    ThemeStore.preview(id: _current.id, isNight: _night);
    await ThemeStore.save();
    if (mounted) MenuExpandScope.close(context);
  }

  void _back() {
    // Do NOT touch global theme — preview was local only.
    MenuExpandScope.close(context);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    // LOCAL theme only for this page — does not change MaterialApp.
    final localTheme = AppTheme.fromPalette(_current, night: _night);
    final scheme = localTheme.colorScheme;

    return Theme(
      data: localTheme,
      child: Material(
        color: scheme.surface,
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
                    onPressed: _back,
                    icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                  ),
                  Expanded(
                    child: TextFielder(
                      text: HomeText.getString(_lang, 'menu_appearance'),
                      languageCode: _lang,
                      template: TextTemplate.subtitle,
                      textAlign: TextAlign.center,
                      customStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        fontSize: context.m,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: _dirty
                        ? IconButton(
                            onPressed: _saveAndClose,
                            icon: Icon(Icons.check_rounded, color: scheme.primary),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Orbit
            SizedBox(
              height: context.s * 12,
              child: _OrbitRing(
                palettes: _all,
                selectedIndex: _index,
                rotation: _rotation,
                onSelect: _selectIndex,
              ),
            ),

            // Genie card + day/night on sides
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.hX2s),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _genie,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(parent: _genie, curve: Curves.easeOutBack),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Light capsule — left
                      _DayNightCapsule(
                        language: _lang,
                        isNight: false,
                        selected: !_night,
                        onTap: () => _setNight(false),
                      ),
                      SizedBox(width: context.hX2s),
                      // Card
                      Expanded(
                        child: _ThemeGenieCard(
                          language: _lang,
                          palette: _current,
                          night: _night,
                        ),
                      ),
                      SizedBox(width: context.hX2s),
                      // Dark capsule — right
                      _DayNightCapsule(
                        language: _lang,
                        isNight: true,
                        selected: _night,
                        onTap: () => _setNight(true),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: context.vS),

            // Morph preview — hearts are indicators only
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.hS),
                child: _MorphPreview(
                  language: _lang,
                  palette: _current,
                  night: _night,
                  selectedIndex: _index,
                ),
              ),
            ),

            if (_dirty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  context.hS,
                  context.vX2s,
                  context.hS,
                  bottom + context.vS,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: context.s * 3.2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _saveAndClose,
                    child: TextFielder(
                      text: HomeText.getString(_lang, 'appearance_continue'),
                      languageCode: _lang,
                      template: TextTemplate.caption,
                      textAlign: TextAlign.center,
                      customStyle: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: context.s,
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: bottom + context.vS),
          ],
        ),
      ),
    );
  }
}

// ─── Orbit with full soft rotation ───────────────────────────────────

class _OrbitRing extends StatelessWidget {
  final List<HelsaPalette> palettes;
  final int selectedIndex;
  final double rotation;
  final ValueChanged<int> onSelect;

  const _OrbitRing({
    required this.palettes,
    required this.selectedIndex,
    required this.rotation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
        final radius = size * 0.36;
        final n = palettes.length;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(n, (i) {
            final ang = rotation + (i / n) * 2 * math.pi;
            final selected = i == selectedIndex;
            final scale = selected ? 1.32 : 0.9;
            final bubble = context.s * 2.7 * scale;
            final dx = center.dx + radius * math.cos(ang) - bubble / 2;
            final dy = center.dy + radius * math.sin(ang) - bubble / 2;
            final p = palettes[i];
            final glow = p.swatch;

            return Positioned(
              left: dx,
              top: dy,
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  width: bubble,
                  height: bubble,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: glow.withValues(alpha: selected ? 0.28 : 0.12),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: glow.withValues(alpha: 0.7),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    border: Border.all(
                      color: selected ? glow : glow.withValues(alpha: 0.35),
                      width: selected ? 2.4 : 1,
                    ),
                  ),
                  child: Icon(
                    p.icon,
                    color: selected ? glow : glow.withValues(alpha: 0.8),
                    size: context.s * (selected ? 1.4 : 1.1),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Genie card (no day/night inside — those sit left/right) ──────────

class _ThemeGenieCard extends StatelessWidget {
  final String language;
  final HelsaPalette palette;
  final bool night;

  const _ThemeGenieCard({
    required this.language,
    required this.palette,
    required this.night,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = palette.scheme(night);
    final name = HomeText.getString(language, 'palette_${palette.id}');
    final desc = HomeText.getString(language, 'palette_${palette.id}_desc');

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.hX2s,
        context.vS,
        context.hX2s,
        context.vS,
      ),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: night ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(palette.icon, color: scheme.primary, size: context.s * 2.1),
          SizedBox(height: context.vX2s),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.hX2s,
              vertical: context.vS * 0.9,
            ),
            decoration: BoxDecoration(
              color: night
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextFielder(
              text: desc,
              languageCode: language,
              template: TextTemplate.caption,
              textAlign: TextAlign.center,
              customStyle: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.85),
                height: 1.35,
                fontSize: context.s * 0.86,
              ),
            ),
          ),
          SizedBox(height: context.vX2s),
          TextFielder(
            text: name,
            languageCode: language,
            template: TextTemplate.caption,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              fontSize: context.s,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayNightCapsule extends StatelessWidget {
  final String language;
  final bool isNight;
  final bool selected;
  final VoidCallback onTap;

  const _DayNightCapsule({
    required this.language,
    required this.isNight,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = HomeText.getString(
      language,
      isNight ? 'appearance_dark' : 'appearance_light',
    );
    final bg = isNight
        ? (selected ? const Color(0xFF1E293B) : const Color(0xFF0F172A))
        : (selected ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9));
    final fg = isNight
        ? (selected ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8))
        : (selected ? const Color(0xFF9A3412) : const Color(0xFF64748B));
    final scale = selected ? 1.08 : 0.92;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(scale, scale, 1),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: context.hX2s * 0.7,
          vertical: context.vS,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (isNight ? Colors.white : Colors.orange)
                        .withValues(alpha: 0.22),
                    blurRadius: 12,
                  ),
                ]
              : null,
          border: Border.all(
            color: selected
                ? (isNight ? const Color(0xFF94A3B8) : const Color(0xFFFDBA74))
                : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: context.s * 1.15,
              color: fg,
            ),
            SizedBox(height: context.vX2s * 0.4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: context.s * 0.72,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Morph preview: exact home apple path + heart indicators ─────────

class _MorphPreview extends StatelessWidget {
  final String language;
  final HelsaPalette palette;
  final bool night;
  final int selectedIndex;

  const _MorphPreview({
    required this.language,
    required this.palette,
    required this.night,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final steps = palette.steps(night);
    final cal = palette.cal(night);
    final time = palette.time(night);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HomeStyleApple(
                  color: steps,
                  fill: 0.62,
                  label: HomeText.getString(language, 'appearance_preview_steps'),
                ),
                _HomeStyleApple(
                  color: cal,
                  fill: 0.38,
                  label: HomeText.getString(language, 'appearance_preview_cal'),
                ),
                _HomeStyleApple(
                  color: time,
                  fill: 0.55,
                  label: HomeText.getString(language, 'appearance_preview_time'),
                ),
              ],
            ),
          ),
        ),
        // Hearts — indicators only (not tappable)
        IgnorePointer(
          child: Container(
            margin: EdgeInsets.only(bottom: context.vS),
            padding: EdgeInsets.symmetric(
              horizontal: context.hS,
              vertical: context.vX2s,
            ),
            decoration: BoxDecoration(
              color: night
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: night
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < HelsaPalette.all.length; i++)
                  _HeartSwatch(
                    color: HelsaPalette.all[i].swatch,
                    selected: i == selectedIndex,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  const _HeartSwatch({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    final s = context.s * (selected ? 1.55 : 1.2);
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _HeartPainter(color: color, selected: selected),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color color;
  final bool selected;
  _HeartPainter({required this.color, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.88)
      ..cubicTo(w * 0.1, h * 0.55, w * 0.0, h * 0.25, w * 0.25, h * 0.15)
      ..cubicTo(w * 0.4, h * 0.05, w * 0.5, h * 0.2, w * 0.5, h * 0.32)
      ..cubicTo(w * 0.5, h * 0.2, w * 0.6, h * 0.05, w * 0.75, h * 0.15)
      ..cubicTo(w * 1.0, h * 0.25, w * 0.9, h * 0.55, w * 0.5, h * 0.88)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeartPainter old) =>
      old.color != color || old.selected != selected;
}

/// Same geometry as home `_ApplePainter` body/stem/leaf paths.
class _HomeStyleApple extends StatelessWidget {
  final Color color;
  final double fill;
  final String label;

  const _HomeStyleApple({
    required this.color,
    required this.fill,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final size = context.s * 4.4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: context.s * 0.75,
          ),
        ),
        SizedBox(height: context.vX2s * 0.5),
        SizedBox(
          width: size,
          height: size * 1.05,
          child: CustomPaint(
            painter: _HomeApplePainter(color: color, progress: fill),
          ),
        ),
        SizedBox(height: context.vX2s * 0.35),
        Text(
          '${(fill * 100).round()}%',
          style: TextStyle(
            color: color.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
            fontSize: context.s * 0.8,
          ),
        ),
      ],
    );
  }
}

class _HomeApplePainter extends CustomPainter {
  final Color color;
  final double progress;
  _HomeApplePainter({required this.color, required this.progress});

  Path _bodyPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    return Path()
      ..moveTo(x(0.50), y(0.22))
      ..cubicTo(x(0.62), y(0.12), x(0.92), y(0.18), x(0.94), y(0.42))
      ..cubicTo(x(0.96), y(0.62), x(0.82), y(0.86), x(0.62), y(0.94))
      ..cubicTo(x(0.55), y(0.98), x(0.45), y(0.98), x(0.38), y(0.94))
      ..cubicTo(x(0.18), y(0.86), x(0.04), y(0.62), x(0.06), y(0.42))
      ..cubicTo(x(0.08), y(0.18), x(0.38), y(0.12), x(0.50), y(0.22))
      ..close();
  }

  Path _stemPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    return Path()
      ..moveTo(x(0.48), y(0.22))
      ..quadraticBezierTo(x(0.46), y(0.12), x(0.50), y(0.04))
      ..quadraticBezierTo(x(0.54), y(0.12), x(0.52), y(0.22))
      ..close();
  }

  Path _leafPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    return Path()
      ..moveTo(x(0.52), y(0.12))
      ..cubicTo(x(0.62), y(0.02), x(0.78), y(0.06), x(0.80), y(0.16))
      ..cubicTo(x(0.78), y(0.24), x(0.62), y(0.22), x(0.52), y(0.14))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final body = _bodyPath(size);
    final stem = _stemPath(size);
    final leaf = _leafPath(size);
    final strokeW = (size.width * 0.048).clamp(2.0, 4.5);
    final b = body.getBounds();
    final emptyOpacity = 0.22;

    final glassShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: emptyOpacity * 0.55),
        color.withValues(alpha: emptyOpacity),
        color.withValues(alpha: emptyOpacity * 0.7),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(b);
    canvas.drawPath(
      body,
      Paint()
        ..shader = glassShader
        ..style = PaintingStyle.fill,
    );

    if (progress > 0.001) {
      canvas.save();
      canvas.clipPath(body);
      final fillH = b.height * progress.clamp(0.0, 1.0);
      final fillTop = b.bottom - fillH;
      canvas.drawRect(
        Rect.fromLTRB(b.left - 2, fillTop, b.right + 2, b.bottom + 2),
        Paint()..color = color,
      );
      canvas.restore();
    }

    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );
    canvas.drawPath(stem, Paint()..color = color);
    canvas.drawPath(leaf, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HomeApplePainter old) =>
      old.color != color || old.progress != progress;
}
