import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/metric_colors.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';

/// Appearance — local preview until tick / continue; then saves + closes.
class MenuAppearancePage extends StatefulWidget {
  const MenuAppearancePage({super.key, this.language});

  final String? language;

  @override
  State<MenuAppearancePage> createState() => _MenuAppearancePageState();
}

class _MenuAppearancePageState extends State<MenuAppearancePage>
    with TickerProviderStateMixin {
  late String _paletteId;
  late bool _night;
  late final String _savedPaletteId;
  late final bool _savedNight;

  late final AnimationController _orbitCtrl;
  late final AnimationController _ringPulse;
  late final AnimationController _wave;
  double _orbitAngle = 0;

  String get _lang => widget.language ?? MetaStore.language;

  bool get _dirty =>
      _paletteId != _savedPaletteId || _night != _savedNight;

  List<HelsaPalette> get _palettes => HelsaPalette.all;

  int get _selectedIndex {
    final i = _palettes.indexWhere((p) => p.id == _paletteId);
    return i < 0 ? 0 : i;
  }

  HelsaPalette get _selected => HelsaPalette.byId(_paletteId);

  @override
  void initState() {
    super.initState();
    _paletteId = ThemeStore.paletteId.value;
    _night = ThemeStore.night.value;
    _savedPaletteId = _paletteId;
    _savedNight = _night;
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _orbitAngle = _angleForIndex(_selectedIndex);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _ringPulse.dispose();
    _wave.dispose();
    super.dispose();
  }

  double _angleForIndex(int index) {
    final n = _palettes.length;
    return -math.pi / 2 - (index * 2 * math.pi / n);
  }

  Future<void> _rotateTo(int index) async {
    final target = _angleForIndex(index);
    final start = _orbitAngle;
    var delta = target - start;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    _orbitCtrl.reset();
    final anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _orbitCtrl, curve: Curves.easeInOutCubic),
    );
    void listener() {
      setState(() => _orbitAngle = start + delta * anim.value);
    }

    anim.addListener(listener);
    await _orbitCtrl.forward();
    anim.removeListener(listener);
    setState(() => _orbitAngle = target);
  }

  void _onSelectPalette(int index) {
    final p = _palettes[index];
    if (p.id == _paletteId) return;
    setState(() => _paletteId = p.id);
    _rotateTo(index);
  }

  Future<void> _saveAndClose() async {
    ThemeStore.paletteId.value = _paletteId;
    ThemeStore.night.value = _night;
    try {
      await ThemeStore.save();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = AppTheme.fromPalette(_selected, night: _night);
    final pad = context.hM;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final metrics = MetricColors.fromPalette(_selected, night: _night);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Theme(
      data: localTheme,
      child: Builder(
        builder: (context) {
          final cs = Theme.of(context).colorScheme;

          return Scaffold(
            backgroundColor: cs.surface,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    lang: _lang,
                    dirty: _dirty,
                    isRtl: isRtl,
                    onBack: _back,
                    onSave: _dirty ? _saveAndClose : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final h = constraints.maxHeight;
                        final w = constraints.maxWidth;

                        // Balanced vertical budget (room for Apply)
                        final appleSize = (w * 0.18).clamp(58.0, 78.0);
                        final orbitSize = (math.min(w, h) * 0.42)
                            .clamp(168.0, 220.0);
                        final cardSide =
                            (w * 0.52).clamp(168.0, 220.0);

                        return Column(
                          children: [
                            SizedBox(height: context.vX3s),
                            // 1–4: real apple shapes + liquid wave
                            AnimatedBuilder(
                              animation: _wave,
                              builder: (context, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _PreviewApple(
                                      label: HomeText.getString(
                                          _lang, 'appearance_preview_steps'),
                                      color: metrics.steps,
                                      fill: 0.62,
                                      size: appleSize,
                                      wave: _wave.value,
                                    ),
                                    SizedBox(width: w * 0.055),
                                    _PreviewApple(
                                      label: HomeText.getString(
                                          _lang, 'appearance_preview_cal'),
                                      color: metrics.calories,
                                      fill: 0.38,
                                      size: appleSize,
                                      wave: _wave.value + 0.33,
                                    ),
                                    SizedBox(width: w * 0.055),
                                    _PreviewApple(
                                      label: HomeText.getString(
                                          _lang, 'appearance_preview_time'),
                                      color: metrics.active,
                                      fill: 0.55,
                                      size: appleSize,
                                      wave: _wave.value + 0.66,
                                    ),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: context.vS * 0.55),
                            // 17: hearts dock clearly separated
                            _HeartDock(
                              colors: [
                                cs.primary,
                                cs.secondary,
                                cs.tertiary,
                                Color.lerp(cs.primary, cs.secondary, 0.5)!,
                                Color.lerp(cs.tertiary, cs.primary, 0.4)!,
                              ],
                              width: w * 0.58,
                            ),
                            SizedBox(height: context.vS * 0.7),
                            // Card block (smaller, glass, not edge-to-edge)
                            _ThemeInfoCard(
                              palette: _selected,
                              night: _night,
                              lang: _lang,
                              side: cardSide,
                              onDay: () => setState(() => _night = false),
                              onNight: () => setState(() => _night = true),
                            ),
                            SizedBox(height: context.vS * 0.85),
                            // Orbit with dual rings + closer nodes
                            SizedBox(
                              height: orbitSize,
                              width: orbitSize,
                              child: AnimatedBuilder(
                                animation: _ringPulse,
                                builder: (context, _) {
                                  return _OrbitRing(
                                    palettes: _palettes,
                                    selectedIndex: _selectedIndex,
                                    angle: _orbitAngle,
                                    pulse: _ringPulse.value,
                                    accent: cs.primary,
                                    onSelect: _onSelectPalette,
                                  );
                                },
                              ),
                            ),
                            const Spacer(flex: 1),
                            // 8: Apply always has reserved room when dirty
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _dirty
                                  ? Padding(
                                      key: const ValueKey('apply'),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: pad * 1.5,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: _saveAndClose,
                                          style: FilledButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: context.vS * 0.8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            HomeText.getString(
                                                _lang, 'appearance_continue'),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: context.m,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      key: const ValueKey('gap'),
                                      height: context.vS * 2.2,
                                    ),
                            ),
                            SizedBox(
                              height: bottomInset > 0
                                  ? bottomInset * 0.2
                                  : context.vX3s,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.lang,
    required this.dirty,
    required this.isRtl,
    required this.onBack,
    required this.onSave,
  });

  final String lang;
  final bool dirty;
  final bool isRtl;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 18: RTL — back on start (right in RTL)
    final back = IconButton(
      onPressed: onBack,
      icon: Icon(
        isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
        color: cs.onSurface,
      ),
    );
    final save = dirty
        ? IconButton(
            onPressed: onSave,
            icon: Icon(Icons.check_rounded, color: cs.primary, size: 28),
          )
        : const SizedBox(width: 48);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hS,
        vertical: context.vX2s,
      ),
      child: Row(
        children: [
          if (!isRtl) back else save,
          Expanded(
            child: Text(
              HomeText.getString(lang, 'menu_appearance'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.l,
                color: cs.onSurface,
              ),
            ),
          ),
          if (!isRtl) save else back,
        ],
      ),
    );
  }
}

class _PreviewApple extends StatelessWidget {
  const _PreviewApple({
    required this.label,
    required this.color,
    required this.fill,
    required this.size,
    required this.wave,
  });

  final String label;
  final Color color;
  final double fill;
  final double size;
  final double wave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.s,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: context.vX3s),
        CustomPaint(
          size: Size(size, size * 1.12),
          painter: _ApplePainter(
            color: color,
            fill: fill,
            wavePhase: wave * math.pi * 2,
          ),
        ),
        SizedBox(height: context.vX3s),
        Text(
          '${(fill * 100).round()}%',
          style: TextStyle(
            fontSize: context.xs,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

/// Same silhouette family as home AppleActivityCard painter.
class _ApplePainter extends CustomPainter {
  _ApplePainter({
    required this.color,
    required this.fill,
    required this.wavePhase,
  });

  final Color color;
  final double fill;
  final double wavePhase;

  Path _bodyPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.50), y(0.22));
    path.cubicTo(x(0.62), y(0.12), x(0.92), y(0.18), x(0.94), y(0.42));
    path.cubicTo(x(0.96), y(0.62), x(0.82), y(0.86), x(0.62), y(0.94));
    path.cubicTo(x(0.55), y(0.98), x(0.45), y(0.98), x(0.38), y(0.94));
    path.cubicTo(x(0.18), y(0.86), x(0.04), y(0.62), x(0.06), y(0.42));
    path.cubicTo(x(0.08), y(0.18), x(0.38), y(0.12), x(0.50), y(0.22));
    path.close();
    return path;
  }

  Path _stemPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.48), y(0.22));
    path.quadraticBezierTo(x(0.46), y(0.12), x(0.50), y(0.04));
    path.quadraticBezierTo(x(0.54), y(0.12), x(0.52), y(0.22));
    path.close();
    return path;
  }

  Path _leafPath(Size size) {
    double x(double n) => n * size.width;
    double y(double n) => n * size.height;
    final path = Path();
    path.moveTo(x(0.52), y(0.12));
    path.cubicTo(x(0.62), y(0.02), x(0.78), y(0.06), x(0.80), y(0.16));
    path.cubicTo(x(0.78), y(0.24), x(0.62), y(0.22), x(0.52), y(0.14));
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final body = _bodyPath(size);
    final stem = _stemPath(size);
    final leaf = _leafPath(size);
    final b = body.getBounds();
    final strokeW = (size.width * 0.048).clamp(1.8, 2.8);

    // Glass empty
    final glass = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.12),
        color.withValues(alpha: 0.28),
        color.withValues(alpha: 0.18),
      ],
    ).createShader(b);
    canvas.drawPath(
      body,
      Paint()
        ..shader = glass
        ..style = PaintingStyle.fill,
    );

    // Liquid with soft wave
    if (fill > 0.001) {
      canvas.save();
      canvas.clipPath(body);
      final fillH = b.height * fill.clamp(0.0, 1.0);
      final top = b.bottom - fillH;
      final amp = size.height * 0.018;
      final wave = Path();
      wave.moveTo(b.left, b.bottom);
      wave.lineTo(b.left, top);
      for (var i = 0; i <= 12; i++) {
        final t = i / 12.0;
        final px = b.left + b.width * t;
        final py = top + math.sin(wavePhase + t * math.pi * 2) * amp;
        wave.lineTo(px, py);
      }
      wave.lineTo(b.right, b.bottom);
      wave.close();
      canvas.drawPath(
        wave,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.85),
              color,
            ],
          ).createShader(b),
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
    canvas.drawPath(stem, Paint()..color = color.withValues(alpha: 0.92));
    canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: 0.82));
  }

  @override
  bool shouldRepaint(covariant _ApplePainter old) =>
      old.color != color || old.fill != fill || old.wavePhase != wavePhase;
}

class _HeartDock extends StatelessWidget {
  const _HeartDock({required this.colors, required this.width});

  final List<Color> colors;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in colors)
              Icon(Icons.favorite_rounded, color: c, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ThemeInfoCard extends StatelessWidget {
  const _ThemeInfoCard({
    required this.palette,
    required this.night,
    required this.lang,
    required this.side,
    required this.onDay,
    required this.onNight,
  });

  final HelsaPalette palette;
  final bool night;
  final String lang;
  final double side;
  final VoidCallback onDay;
  final VoidCallback onNight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = HomeText.getString(lang, 'palette_${palette.id}');
    final desc = HomeText.getString(lang, 'palette_${palette.id}_desc');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ModePill(
            selected: !night,
            icon: Icons.wb_sunny_rounded,
            label: HomeText.getString(lang, 'appearance_light'),
            lightStyle: true,
            onTap: onDay,
          ),
        ),
        SizedBox(width: context.hXs),
        // Smaller glass card, thin border
        Container(
          width: side,
          height: side * 0.98,
          padding: EdgeInsets.fromLTRB(
            context.hS * 0.65,
            context.vX2s,
            context.hS * 0.65,
            context.vX2s,
          ),
          decoration: BoxDecoration(
            // 9–10: layered glass, not flat brown slab
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  cs.primary.withValues(alpha: night ? 0.22 : 0.18),
                  cs.surface.withValues(alpha: night ? 0.55 : 0.92),
                ),
                Color.alphaBlend(
                  cs.primary.withValues(alpha: night ? 0.12 : 0.10),
                  cs.surface.withValues(alpha: night ? 0.40 : 0.85),
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Smaller top icon — less clash with orbit
              Icon(palette.icon, size: 24, color: cs.primary),
              SizedBox(height: context.vX2s),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.hXs,
                      vertical: context.vX2s,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: night ? 0.50 : 0.88),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.s * 1.12,
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.90),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.vX2s),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.l * 1.06,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.hXs),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _ModePill(
            selected: night,
            icon: Icons.nightlight_round,
            label: HomeText.getString(lang, 'appearance_dark'),
            lightStyle: false,
            onTap: onNight,
          ),
        ),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.selected,
    required this.icon,
    required this.label,
    required this.lightStyle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final bool lightStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 12–13: selected night stronger; unselected light quieter
    final bg = lightStyle
        ? (selected ? const Color(0xFFFFF6E8) : const Color(0xFFE8E4DE))
        : (selected ? const Color(0xFF243044) : const Color(0xFF1A222E));
    final fg = lightStyle
        ? (selected ? const Color(0xFFE8913A) : const Color(0xFF8A837C))
        : (selected ? const Color(0xFFF0F4FA) : const Color(0xFF7A8494));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12 : 9,
          vertical: selected ? 13 : 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? fg.withValues(alpha: 0.55) : Colors.transparent,
            width: selected ? 1.6 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: fg.withValues(alpha: lightStyle ? 0.30 : 0.40),
                    blurRadius: selected && !lightStyle ? 16 : 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 20 : 16, color: fg),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: selected ? context.xs * 1.06 : context.xs * 0.95,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitRing extends StatelessWidget {
  const _OrbitRing({
    required this.palettes,
    required this.selectedIndex,
    required this.angle,
    required this.pulse,
    required this.accent,
    required this.onSelect,
  });

  final List<HelsaPalette> palettes;
  final int selectedIndex;
  final double angle;
  final double pulse;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        // Closer nodes (14–15)
        final radius = size * 0.30;
        final n = palettes.length;
        final cx = size / 2;
        final cy = size / 2;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DualRingPainter(
                  accent: accent,
                  pulse: pulse,
                  outerR: radius * 1.10,
                  innerR: radius * 0.70,
                ),
              ),
              for (var i = 0; i < n; i++)
                Builder(
                  builder: (context) {
                    final a = angle + i * 2 * math.pi / n;
                    final x = cx + radius * math.cos(a);
                    final y = cy + radius * math.sin(a);
                    final selected = i == selectedIndex;
                    final node = selected ? size * 0.168 : size * 0.118;
                    final color = palettes[i].swatch;
                    return Positioned(
                      left: x - node / 2,
                      top: y - node / 2,
                      width: node,
                      height: node,
                      child: GestureDetector(
                        onTap: () => onSelect(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(
                                alpha: selected ? 0.32 : 0.12),
                            border: Border.all(
                              color: color.withValues(
                                  alpha: selected ? 1.0 : 0.38),
                              width: selected ? 2.3 : 1.15,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.50),
                                      blurRadius: 16,
                                      spreadRadius: 0.5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            palettes[i].icon,
                            size: selected ? 21 : 16,
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DualRingPainter extends CustomPainter {
  _DualRingPainter({
    required this.accent,
    required this.pulse,
    required this.outerR,
    required this.innerR,
  });

  final Color accent;
  final double pulse;
  final double outerR;
  final double innerR;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final breathe = 1.0 + 0.016 * math.sin(pulse * math.pi * 2);

    canvas.drawCircle(
      c,
      outerR * breathe,
      Paint()
        ..color = accent.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25,
    );
    canvas.drawCircle(
      c,
      innerR / breathe,
      Paint()
        ..color = accent.withValues(alpha: 0.11)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final sweep = math.pi * 0.5;
    final start = pulse * math.pi * 2;
    final arc = Paint()
      ..color = accent.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: outerR * breathe),
      start,
      sweep,
      false,
      arc,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: innerR / breathe),
      -start * 1.25,
      sweep * 0.9,
      false,
      arc..color = accent.withValues(alpha: 0.20),
    );
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter old) =>
      old.pulse != pulse || old.accent != accent;
}
