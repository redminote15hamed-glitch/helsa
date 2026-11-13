// lib/home/menu/menu_avatar_picker.dart
// Floating card: pick a built-in avatar or a gallery photo.
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/helsa_avatar.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MenuAvatarPicker {
  MenuAvatarPicker._();

  /// Floating centered card. Returns true if avatar changed.
  static Future<bool> show(
    BuildContext context, {
    required String language,
    ThemeData? theme,
  }) async {
    final resolved = theme ?? Theme.of(context);
    final result = await showGeneralDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'avatar',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, a, b) {
        return Theme(
          data: resolved,
          child: _AvatarSheet(language: language, theme: resolved),
        );
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result == true;
  }
}

class _AvatarSheet extends StatefulWidget {
  final String language;
  final ThemeData theme;

  const _AvatarSheet({required this.language, required this.theme});

  @override
  State<_AvatarSheet> createState() => _AvatarSheetState();
}

class _AvatarSheetState extends State<_AvatarSheet> {
  String _preset = 'mint';
  String _path = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    try {
      _path = IdentityStore.avatarPath;
      final pr = IdentityStore.avatarPreset;
      _preset = pr.isEmpty ? 'mint' : pr;
    } catch (_) {}
  }

  String get _lang => widget.language;

  Future<void> _pickGallery() async {
    if (kIsWeb) {
      _toast(HomeText.getString(_lang, 'avatar_android_only'), error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (x == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}${Platform.pathSeparator}avatars');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final dest = '${folder.path}${Platform.pathSeparator}avatar.jpg';
      await File(x.path).copy(dest);
      if (!mounted) return;
      setState(() {
        _path = dest;
        _preset = '';
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(HomeText.getString(_lang, 'avatar_pick_error'), error: true);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      if (_path.isNotEmpty) {
        await IdentityStore.saveAvatarFile(_path);
      } else {
        await IdentityStore.saveAvatarPreset(
          _preset.isEmpty ? 'mint' : _preset,
        );
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(HomeText.getString(_lang, 'avatar_pick_error'), error: true);
      }
    }
  }

  void _toast(String msg, {required bool error}) {
    SnackBarer.show(
      context,
      message: msg,
      template: error ? SnackbarTemplate.caution : SnackbarTemplate.neutral,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    final maxW = MediaQuery.sizeOf(context).width.clamp(280.0, 400.0);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW * 0.92),
          child: Material(
            color: cs.surface,
            elevation: 18,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.hS,
                context.vS,
                context.hS,
                context.vS,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFielder(
                          text: HomeText.getString(_lang, 'avatar_title'),
                          languageCode: _lang,
                          template: TextTemplate.subtitle,
                          customStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .pop(false),
                        icon: Icon(Icons.close_rounded, color: cs.onSurface),
                      ),
                    ],
                  ),
                  SizedBox(height: context.vX2s),
                  // Live preview
                  HelsaAvatar(
                    radius: 44,
                    showBorder: true,
                    presetId: _preset,
                    filePath: _path,
                  ),
                  SizedBox(height: context.vS),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextFielder(
                      text: HomeText.getString(_lang, 'avatar_presets'),
                      languageCode: _lang,
                      template: TextTemplate.caption,
                      customStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: context.vX2s),
                  // Preset grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: AvatarPresets.all.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, i) {
                      final p = AvatarPresets.all[i];
                      final selected = _path.isEmpty && _preset == p.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: _busy
                            ? null
                            : () => setState(() {
                                  _preset = p.id;
                                  _path = '';
                                }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            backgroundColor: p.bg,
                            child: Icon(p.icon, color: p.fg, size: 26),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: context.vS),
                  // Gallery
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _pickGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        HomeText.getString(_lang, 'avatar_gallery'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.primary,
                        side: BorderSide(
                          color: cs.primary.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.vX2s),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : Text(
                              HomeText.getString(_lang, 'confirm'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
