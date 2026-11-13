// lib/home/widgets/ambient_background.dart
// Sky follows APP theme brightness first. Time-of-day only tints within that mode.
// Never force dark home + light drawer (or the reverse).
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

enum _SkyPhase { morning, noon, evening, night }

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  _SkyPhase get _phase {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 11) return _SkyPhase.morning;
    if (h >= 11 && h < 16) return _SkyPhase.noon;
    if (h >= 16 && h < 20) return _SkyPhase.evening;
    return _SkyPhase.night;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final phase = _phase;
    final cs = theme.colorScheme;

    // Base ALWAYS matches theme brightness (root contrast fix).
    late Color base;
    late Color blobA;
    late Color blobB;
    late Color blobC;

    if (isDark) {
      base = cs.surface.withValues(alpha: 1.0);
      // Prefer deep surface; fallback if surface is mid-tone
      base = Color.alphaBlend(
          const Color(0xFF0A0E14).withValues(alpha: 0.92), cs.surface);
      blobA = cs.primary.withValues(alpha: 0.10);
      blobB = const Color(0xFF1A2740).withValues(alpha: 0.45);
      blobC = cs.secondary.withValues(alpha: 0.08);
      // slight phase tint only
      if (phase == _SkyPhase.evening) {
        blobC = const Color(0xFF2A1F4A).withValues(alpha: 0.14);
      }
    } else {
      switch (phase) {
        case _SkyPhase.morning:
          base = const Color(0xFFF7F3EC);
          blobA = const Color(0xFFFFE0B2).withValues(alpha: 0.35);
          blobB = cs.primary.withValues(alpha: 0.08);
          blobC = const Color(0xFFFFCC80).withValues(alpha: 0.12);
          break;
        case _SkyPhase.noon:
          base = Color.alphaBlend(const Color(0xFFF3F8F6), cs.surface);
          blobA = cs.primary.withValues(alpha: 0.10);
          blobB = cs.tertiary.withValues(alpha: 0.10);
          blobC = cs.secondary.withValues(alpha: 0.07);
          break;
        case _SkyPhase.evening:
          base = const Color(0xFFF8F0EB);
          blobA = const Color(0xFFFFAB91).withValues(alpha: 0.22);
          blobB = const Color(0xFFCE93D8).withValues(alpha: 0.10);
          blobC = cs.primary.withValues(alpha: 0.06);
          break;
        case _SkyPhase.night:
          // Still LIGHT theme: soft cool grey, NOT pure black
          base = const Color(0xFFEEF2F6);
          blobA = cs.primary.withValues(alpha: 0.07);
          blobB = const Color(0xFF94A3B8).withValues(alpha: 0.10);
          blobC = cs.tertiary.withValues(alpha: 0.06);
          break;
      }
    }

    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final dx = math.sin(t * math.pi) * 0.10;
          final dy = math.cos(t * math.pi * 0.8) * 0.07;

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: base),
              Align(
                alignment: Alignment(dx - 0.6, dy - 0.7),
                child: _blob(blobA, 320),
              ),
              Align(
                alignment: Alignment(-dx + 0.5, -dy + 0.4),
                child: _blob(blobB, 280),
              ),
              Align(
                alignment: Alignment(dx * 0.5, 0.8),
                child: _blob(blobC, 260),
              ),
              widget.child,
            ],
          );
        },
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
