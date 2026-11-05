// lib/home/menu/helsa_avatar.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:helsa/setting/storage/identity_store.dart';

class AvatarPreset {
  final String id;
  final IconData icon;
  final Color bg;
  final Color fg;

  const AvatarPreset({
    required this.id,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

/// Built-in faces — no asset files needed.
class AvatarPresets {
  AvatarPresets._();

  static const List<AvatarPreset> all = [
    AvatarPreset(
      id: 'mint',
      icon: Icons.person_rounded,
      bg: Color(0xFF12352C),
      fg: Color(0xFF10B981),
    ),
    AvatarPreset(
      id: 'sky',
      icon: Icons.face_rounded,
      bg: Color(0xFF0F2744),
      fg: Color(0xFF38BDF8),
    ),
    AvatarPreset(
      id: 'coral',
      icon: Icons.sentiment_satisfied_alt_rounded,
      bg: Color(0xFF3A1C18),
      fg: Color(0xFFFB7185),
    ),
    AvatarPreset(
      id: 'amber',
      icon: Icons.emoji_emotions_rounded,
      bg: Color(0xFF3A2A0E),
      fg: Color(0xFFFBBF24),
    ),
    AvatarPreset(
      id: 'violet',
      icon: Icons.spa_rounded,
      bg: Color(0xFF2A1848),
      fg: Color(0xFFA78BFA),
    ),
    AvatarPreset(
      id: 'leaf',
      icon: Icons.eco_rounded,
      bg: Color(0xFF14301F),
      fg: Color(0xFF4ADE80),
    ),
    AvatarPreset(
      id: 'night',
      icon: Icons.nightlight_round,
      bg: Color(0xFF1A2030),
      fg: Color(0xFF93C5FD),
    ),
    AvatarPreset(
      id: 'sport',
      icon: Icons.directions_run_rounded,
      bg: Color(0xFF1C2A1A),
      fg: Color(0xFF86EFAC),
    ),
  ];

  static AvatarPreset byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return all.first;
  }
}

/// Renders current user avatar (preset or gallery file).
class HelsaAvatar extends StatelessWidget {
  final double radius;
  final String? presetId;
  final String? filePath;
  final bool showBorder;

  const HelsaAvatar({
    super.key,
    this.radius = 28,
    this.presetId,
    this.filePath,
    this.showBorder = false,
  });

  factory HelsaAvatar.fromStore({Key? key, double radius = 28, bool showBorder = false}) {
    return HelsaAvatar(
      key: key,
      radius: radius,
      showBorder: showBorder,
      presetId: IdentityStore.avatarPreset,
      filePath: IdentityStore.avatarPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final path = filePath ?? '';
    final hasFile = path.isNotEmpty && File(path).existsSync();

    Widget core;
    if (hasFile) {
      core = CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
        backgroundImage: FileImage(File(path)),
      );
    } else {
      final p = AvatarPresets.byId(
        (presetId == null || presetId!.isEmpty) ? 'mint' : presetId!,
      );
      core = CircleAvatar(
        radius: radius,
        backgroundColor: p.bg,
        child: Icon(p.icon, size: radius * 1.05, color: p.fg),
      );
    }

    if (!showBorder) return core;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      child: core,
    );
  }
}
