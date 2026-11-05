import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/metric_colors.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';

/// Appearance — preview is local until tick / continue saves.
class MenuAppearancePage extends StatefulWidget {
  const MenuAppearancePage({super.key, this.language});

  /// When null, falls back to [MetaStore.language].
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
    _orbitAngle = _angleForIndex(_selectedIndex);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
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
    await ThemeStore.save();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _back() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final localTheme = AppTheme.fromPalette(_selected, night: _night);
    final pad = context.hM;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final metrics = MetricColors.fromPalette(_selected, night: _night);

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
                    onBack: _back,
                    onSave: _dirty ? _saveAndClose : null,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final h = constraints.maxHeight;
                        final w = constraints.maxWidth;
                        final appleZone = (h * 0.26).clamp(140.0, 200.0);
                        final orbitSize = (w * 0.72).clamp(200.0, 280.0);
                        final cardSide = (w * 0.72).clamp(220.0, 300.0);

                        return Column(
                          children: [
                            SizedBox(height: context.vS * 0.4),
                            SizedBox(
                              height: appleZone * 0.72,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _PreviewApple(
                                    label: HomeText.getString(
                                        _lang, 'appearance_preview_steps'),
                                    color: metrics.steps,
                                    fill: 0.62,
                                    size: appleZone * 0.55,
                                  ),
                                  SizedBox(width: w * 0.04),
                                  _PreviewApple(
                                    label: HomeText.getString(
                                        _lang, 'appearance_preview_cal'),
                                    color: metrics.calories,
                                    fill: 0.38,
                                    size: appleZone * 0.55,
                                  ),
                                  SizedBox(width: w * 0.04),
                                  _PreviewApple(
                                    label: HomeText.getString(
                                        _lang, 'appearance_preview_time'),
                                    color: metrics.active,
                                    fill: 0.55,
                                    size: appleZone * 0.55,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.vS * 0.5),
                            _HeartDock(
                              colors: [
                                cs.primary,
                                cs.secondary,
                                cs.tertiary,
                                cs.primaryContainer,
                                cs.secondaryContainer,
                              ],
                              width: w * 0.78,
                            ),
                            const Spacer(flex: 2),
                            _ThemeInfoCard(
                              palette: _selected,
                              night: _night,
                              lang: _lang,
                              side: cardSide,
                              onDay: () => setState(() => _night = false),
                              onNight: () => setState(() => _night = true),
                            ),
                            const Spacer(flex: 2),
                            SizedBox(
                              height: orbitSize,
                              width: orbitSize,
                              child: _OrbitRing(
                                palettes: _palettes,
                                selectedIndex: _selectedIndex,
                                angle: _orbitAngle,
                                onSelect: _onSelectPalette,
                              ),
                            ),
                            SizedBox(height: context.vS * 0.8),
                            if (_dirty)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: pad),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _saveAndClose,
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: context.vS * 0.85,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                              ),
                            SizedBox(
                              height: bottomInset > 0
                                  ? bottomInset * 0.3
                                  : context.vS,
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
    required this.onBack,
    required this.onSave,
  });

  final String lang;
  final bool dirty;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.hS,
        vertical: context.vS * 0.4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          ),
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
          if (dirty)
            IconButton(
              onPressed: onSave,
              icon: Icon(Icons.check_rounded, color: cs.primary, size: 28),
            )
          else
            const SizedBox(width: 48),
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
  });

  final String label;
  final Color color;
  final double fill;
  final double size;

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
        SizedBox(height: context.vS * 0.25),
        CustomPaint(
          size: Size(size, size * 1.12),
          painter: _ApplePainter(color: color, fill: fill),
        ),
        SizedBox(height: context.vS * 0.2),
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

class _ApplePainter extends CustomPainter {
  _ApplePainter({required this.color, required this.fill});

  final Color color;
  final double fill;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = _bodyPath(w, h);

    canvas.drawPath(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    final fillH = h * fill.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      Rect.fromLTWH(0, h - fillH, w, fillH),
      Paint()..color = color,
    );
    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final stem = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..quadraticBezierTo(w * 0.52, h * 0.02, w * 0.58, h * 0.04);
    canvas.drawPath(
      stem,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final leaf = Path()
      ..moveTo(w * 0.52, h * 0.08)
      ..quadraticBezierTo(w * 0.68, h * 0.00, w * 0.62, h * 0.12)
      ..quadraticBezierTo(w * 0.55, h * 0.14, w * 0.52, h * 0.08);
    canvas.drawPath(leaf, Paint()..color = color.withValues(alpha: 0.75));
  }

  Path _bodyPath(double w, double h) {
    final p = Path();
    p.moveTo(w * 0.50, h * 0.16);
    p.cubicTo(w * 0.22, h * 0.16, w * 0.06, h * 0.38, w * 0.08, h * 0.55);
    p.cubicTo(w * 0.10, h * 0.78, w * 0.28, h * 0.96, w * 0.50, h * 0.96);
    p.cubicTo(w * 0.72, h * 0.96, w * 0.90, h * 0.78, w * 0.92, h * 0.55);
    p.cubicTo(w * 0.94, h * 0.38, w * 0.78, h * 0.16, w * 0.50, h * 0.16);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _ApplePainter old) =>
      old.color != color || old.fill != fill;
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in colors)
              Icon(Icons.favorite_rounded, color: c, size: 26),
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
        SizedBox(width: context.hS * 0.6),
        Container(
          width: side,
          height: side * 0.92,
          padding: EdgeInsets.symmetric(
            horizontal: context.hS,
            vertical: context.vS * 0.8,
          ),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.35),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(palette.icon, size: 36, color: cs.primary),
              SizedBox(height: context.vS * 0.6),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.hS * 0.8,
                      vertical: context.vS * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.s * 1.05,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.vS * 0.55),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.l * 1.05,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: context.hS * 0.6),
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
    final bg = lightStyle
        ? (selected ? const Color(0xFFFFF6E8) : const Color(0xFFF3F0EA))
        : (selected ? const Color(0xFF1A2330) : const Color(0xFF2A3340));
    final fg = lightStyle
        ? (selected ? const Color(0xFFE8913A) : const Color(0xFF6B6560))
        : (selected ? const Color(0xFFE8EEF8) : const Color(0xFF9AA3B2));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 12 : 10,
          vertical: selected ? 14 : 11,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? fg.withValues(alpha: 0.45) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: fg.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: selected ? 22 : 18, color: fg),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: selected ? context.xs * 1.05 : context.xs,
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
    required this.onSelect,
  });

  final List<HelsaPalette> palettes;
  final int selectedIndex;
  final double angle;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        final radius = size * 0.36;
        final n = palettes.length;
        final cx = size / 2;
        final cy = size / 2;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < n; i++)
                Builder(
                  builder: (context) {
                    final a = angle + i * 2 * math.pi / n;
                    final x = cx + radius * math.cos(a);
                    final y = cy + radius * math.sin(a);
                    final selected = i == selectedIndex;
                    final node = selected ? size * 0.20 : size * 0.145;
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
                            color: color.withValues(alpha: selected ? 0.28 : 0.14),
                            border: Border.all(
                              color:
                                  color.withValues(alpha: selected ? 0.95 : 0.45),
                              width: selected ? 2.4 : 1.4,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            palettes[i].icon,
                            size: selected ? 26 : 20,
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.75),
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
