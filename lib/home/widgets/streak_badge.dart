// lib/home/widgets/streak_badge.dart
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class StreakBadge extends StatefulWidget {
  final String language;
  final int streak;
  final bool isNight;

  const StreakBadge({
    super.key,
    required this.language,
    required this.streak,
    this.isNight = false,
  });

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String _label() {
    if (widget.isNight) {
      return HomeText.getString(widget.language, 'night_mode');
    }
    return HomeText.streakLabel(widget.language, widget.streak);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNight && widget.streak <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = widget.isNight
        ? const Color(0xFF7EB6FF)
        : ColorPalette.calorieBurn;
    final bg = isDark
        ? border.withValues(alpha: 0.15)
        : border.withValues(alpha: 0.10);

    return Center(
      child: Container(
        margin: EdgeInsets.only(bottom: context.vX2s, top: context.vX3s),
        padding: EdgeInsets.symmetric(
          horizontal: context.hS,
          vertical: context.vX3s,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 2),
          boxShadow: [
            BoxShadow(
              color: border.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final t = _anim.value;
                if (widget.isNight) {
                  final glow = 0.7 + t * 0.3;
                  return Icon(
                    Icons.nightlight_round,
                    color: Color.lerp(
                      const Color(0xFF9EC5FF),
                      const Color(0xFFE8F1FF),
                      t,
                    ),
                    size: context.baseScale * 1.15,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF7EB6FF)
                            .withValues(alpha: 0.35 * glow),
                        blurRadius: 10 + t * 6,
                      ),
                    ],
                  );
                }
                final scale = 0.92 + t * 0.16;
                final angle = (t - 0.5) * 0.12;
                return Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Color.lerp(
                        const Color(0xFFFF6B00),
                        const Color(0xFFFFD000),
                        t,
                      ),
                      size: context.baseScale * 1.15,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFF6B00)
                              .withValues(alpha: 0.45 + t * 0.25),
                          blurRadius: 8 + t * 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(width: context.hX3s),
            Text(
              _label(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: context.m * 0.95,
                color: border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
