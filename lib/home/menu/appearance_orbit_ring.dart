import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:helsa/setting/color/theme_palette.dart';

/// Dual-ring theme selector with heart burst open/close.
class AppearanceOrbitRing extends StatelessWidget {
  const AppearanceOrbitRing({
    super.key,
    required this.palettes,
    required this.selectedIndex,
    required this.angle,
    required this.pulse,
    required this.burst,
    required this.accent,
    required this.onSelect,
  });

  final List<HelsaPalette> palettes;
  final int selectedIndex;
  final double angle;
  final double pulse;

  /// 0 = icons stacked in center heart, 1 = icons on ring.
  final double burst;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        final n = palettes.length;
        final cx = size / 2;
        final cy = size / 2;

        // Wider band: inner track further in so large icons sit cleanly between rings
        final nodeBase = size * 0.135;
        final nodeSel = size * 0.175;
        final outerR = size * 0.455;
        final innerR = size * 0.265;
        final midR = (outerR + innerR) / 2;

        // Heart fades as icons leave (mostly gone by ~0.7)
        final heartT = (1.0 -
                Curves.easeIn.transform(
                  (burst / 0.72).clamp(0.0, 1.0),
                ))
            .clamp(0.0, 1.0);
        final heartSize = size * (0.20 + 0.04 * (1 - heartT));

        // Ring tracks fade in with burst
        final ringOpacity = Curves.easeOut.transform(
          ((burst - 0.15) / 0.55).clamp(0.0, 1.0),
        );

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: ringOpacity,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: AppearanceDualRingPainter(
                    accent: accent,
                    pulse: pulse,
                    outerR: outerR,
                    innerR: innerR,
                  ),
                ),
              ),
              // Center heart — source of icons
              if (heartT > 0.02)
                Positioned(
                  left: cx - heartSize / 2,
                  top: cy - heartSize / 2,
                  width: heartSize,
                  height: heartSize,
                  child: Opacity(
                    opacity: heartT,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * heartT,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: heartSize * 0.92,
                        color: accent,
                        shadows: [
                          Shadow(
                            color: accent.withValues(alpha: 0.45 * heartT),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < n; i++)
                Builder(
                  builder: (context) {
                    // Stagger: each icon leaves the heart slightly later
                    final start = i * 0.055;
                    final span = 0.58;
                    final local = ((burst - start) / span).clamp(0.0, 1.0);
                    final t = Curves.easeOutBack.transform(local);

                    final a = angle + i * 2 * math.pi / n;
                    final r = midR * t;
                    final x = cx + r * math.cos(a);
                    final y = cy + r * math.sin(a);
                    final selected = i == selectedIndex;
                    final node =
                        (selected ? nodeSel : nodeBase) * (0.55 + 0.45 * t);
                    final color = palettes[i].swatch;
                    final iconOpacity = (t * 1.15).clamp(0.0, 1.0);

                    return Positioned(
                      left: x - node / 2,
                      top: y - node / 2,
                      width: node,
                      height: node,
                      child: Opacity(
                        opacity: iconOpacity,
                        child: GestureDetector(
                          onTap: burst > 0.92 ? () => onSelect(i) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(
                                  alpha: selected ? 0.34 : 0.12),
                              border: Border.all(
                                color: color.withValues(
                                    alpha: selected ? 1.0 : 0.40),
                                width: selected ? 2.2 : 1.15,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.48),
                                        blurRadius: 14,
                                        spreadRadius: 0.4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              palettes[i].icon,
                              size: (selected ? 24.0 : 18.0) * (0.7 + 0.3 * t),
                              color: selected
                                  ? color
                                  : color.withValues(alpha: 0.72),
                            ),
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

/// Two tracks = one ring band; icons sit in the gap between them.
class AppearanceDualRingPainter extends CustomPainter {
  AppearanceDualRingPainter({
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
    final breathe = 1.0 + 0.01 * math.sin(pulse * math.pi * 2);
    final out = outerR * breathe;
    final inn = (innerR / breathe).clamp(1.0, out - 2);

    // Annulus fill (band between tracks)
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(c, out, Paint()..color = accent.withValues(alpha: 0.11));
    canvas.drawCircle(
      c,
      inn,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Outer track
    canvas.drawCircle(
      c,
      out,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1,
    );
    // Inner track
    canvas.drawCircle(
      c,
      inn,
      Paint()
        ..color = accent.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant AppearanceDualRingPainter old) =>
      old.pulse != pulse ||
      old.accent != accent ||
      old.outerR != outerR ||
      old.innerR != innerR;
}
