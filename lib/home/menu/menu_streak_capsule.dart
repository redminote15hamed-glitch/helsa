// lib/home/menu/menu_streak_capsule.dart
// Compact streak capsule for the side menu only.
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/color/color_palette.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/streak_store.dart';

class MenuStreakCapsule extends StatefulWidget {
  final String language;

  const MenuStreakCapsule({super.key, required this.language});

  @override
  State<MenuStreakCapsule> createState() => _MenuStreakCapsuleState();
}

class _MenuStreakCapsuleState extends State<MenuStreakCapsule>
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

  int get _streak {
    try {
      return StreakStore.currentStreak;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _streak;
    final border = ColorPalette.calorieBurn;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = border.withValues(alpha: isDark ? 0.16 : 0.10);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: context.hX2s,
        vertical: context.vX3s,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final t = _anim.value;
              final scale = n > 0 ? (0.92 + t * 0.14) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: Color.lerp(
                    const Color(0xFFFF6B00),
                    const Color(0xFFFFD000),
                    t,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: context.hX3s),
          Flexible(
            child: TextFielder(
              text: HomeText.streakLabel(widget.language, n),
              languageCode: widget.language,
              template: TextTemplate.caption,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              customStyle: TextStyle(
                fontWeight: FontWeight.w800,
                color: border,
                fontSize: context.s,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
