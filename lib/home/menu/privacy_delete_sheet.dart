// lib/home/menu/privacy_delete_sheet.dart
// Floating delete sheet + confirm dialog + store clear actions.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/diet_store.dart';
import 'package:helsa/setting/storage/favorite_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/restriction_store.dart';
import 'package:helsa/setting/storage/sleep_store.dart';
import 'package:helsa/setting/storage/storage_init.dart';
import 'package:helsa/setting/storage/app_data_revision.dart';

enum PrivacyDeleteKind {
  gender,
  body,
  age,
  activity,
  diet,
  favorites,
  restrictions,
  allApp,
}

/// Opens the delete sheet above drawer + expand overlays (root Overlay).
Future<void> showPrivacyDeleteSheet(
  BuildContext context, {
  required String language,
}) {
  final completer = Completer<void>();
  final overlayState = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;

  void finish() {
    if (!completer.isCompleted) completer.complete();
  }

  entry = OverlayEntry(
    builder: (ctx) {
      return _PrivacyDeleteOverlay(
        language: language,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          finish();
        },
      );
    },
  );
  overlayState.insert(entry);
  return completer.future;
}

class _PrivacyDeleteOverlay extends StatefulWidget {
  const _PrivacyDeleteOverlay({
    required this.language,
    required this.onDismiss,
  });

  final String language;
  final VoidCallback onDismiss;

  @override
  State<_PrivacyDeleteOverlay> createState() => _PrivacyDeleteOverlayState();
}

class _PrivacyDeleteOverlayState extends State<_PrivacyDeleteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    try {
      await _ctrl.reverse();
    } catch (_) {}
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fade,
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: PrivacyDeleteSheet(
                  language: widget.language,
                  onRequestClose: _close,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyDeleteSheet extends StatefulWidget {
  const PrivacyDeleteSheet({
    super.key,
    required this.language,
    this.onRequestClose,
  });

  final String language;
  final Future<void> Function()? onRequestClose;

  @override
  State<PrivacyDeleteSheet> createState() => _PrivacyDeleteSheetState();
}

class _PrivacyDeleteSheetState extends State<PrivacyDeleteSheet> {
  bool _busy = false;

  String get _lang => widget.language;

  Future<void> _dismissSheet() async {
    final custom = widget.onRequestClose;
    if (custom != null) {
      await custom();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _labelKey(PrivacyDeleteKind kind) {
    switch (kind) {
      case PrivacyDeleteKind.gender:
        return 'privacy_del_gender';
      case PrivacyDeleteKind.body:
        return 'privacy_del_body';
      case PrivacyDeleteKind.age:
        return 'privacy_del_age';
      case PrivacyDeleteKind.activity:
        return 'privacy_del_activity';
      case PrivacyDeleteKind.diet:
        return 'privacy_del_diet';
      case PrivacyDeleteKind.favorites:
        return 'privacy_del_favorites';
      case PrivacyDeleteKind.restrictions:
        return 'privacy_del_restrictions';
      case PrivacyDeleteKind.allApp:
        return 'privacy_del_all_app';
    }
  }

  Future<void> _runDelete(PrivacyDeleteKind kind) async {
    switch (kind) {
      case PrivacyDeleteKind.gender:
        await GenderStore.open();
        await GenderStore.clear();
        break;
      case PrivacyDeleteKind.body:
        await BodyStore.open();
        await BodyStore.clear();
        break;
      case PrivacyDeleteKind.age:
        await AgeStore.open();
        await AgeStore.clear();
        break;
      case PrivacyDeleteKind.activity:
        await ActivityStore.open();
        await ActivityStore.clear();
        break;
      case PrivacyDeleteKind.diet:
        await DietStore.open();
        await DietStore.clear();
        break;
      case PrivacyDeleteKind.favorites:
        await FavoriteStore.open();
        await FavoriteStore.clear();
        break;
      case PrivacyDeleteKind.restrictions:
        await RestrictionStore.open();
        await RestrictionStore.clear();
        break;
      case PrivacyDeleteKind.allApp:
        await StorageInit.clearAll();
        await SleepStore.open();
        await SleepStore.clear();
        break;
    }
    try {
      StepTracker.instance.profileChanged();
    } catch (_) {}
    
  }

  Future<bool> _confirm(PrivacyDeleteKind kind) async {
    final cs = Theme.of(context).colorScheme;
    final field = HomeText.getString(_lang, _labelKey(kind));
    final isAll = kind == PrivacyDeleteKind.allApp;
    const warn = Color(0xFFE11D48);

    final title = HomeText.getString(
      _lang,
      isAll ? 'privacy_confirm_all_title' : 'privacy_confirm_one_title',
    );
    final body = isAll
        ? HomeText.getString(_lang, 'privacy_confirm_all_body')
        : HomeText.format(_lang, 'privacy_confirm_one_body', {'field': field});

    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'delete-confirm',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, a, s) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.sizeOf(ctx).width * 0.86,
                  padding: EdgeInsets.fromLTRB(
                    context.hM, context.vM, context.hM, context.vS,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: warn.withValues(alpha: 0.55), width: 1.4),
                    boxShadow: [
                      BoxShadow(
                        color: warn.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: warn.withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          isAll ? Icons.warning_rounded : Icons.delete_outline_rounded,
                          color: warn, size: 26,
                        ),
                      ),
                      SizedBox(height: context.vS),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: context.l,
                          color: cs.onSurface,
                        ),
                      ),
                      SizedBox(height: context.vX2s),
                      Text(
                        body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.s,
                          height: 1.35,
                          color: cs.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      SizedBox(height: context.vM),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.onSurface.withValues(alpha: 0.75),
                              ),
                              child: Text(
                                HomeText.getString(_lang, 'privacy_confirm_no'),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SizedBox(width: context.hS),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: warn,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: context.vX2s),
                              ),
                              child: Text(
                                HomeText.getString(_lang, 'privacy_confirm_yes'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    return ok == true;
  }

  Future<void> _onTap(PrivacyDeleteKind kind) async {
    if (_busy) return;
    final confirmed = await _confirm(kind);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final field = HomeText.getString(_lang, _labelKey(kind));
    try {
      await _runDelete(kind);
      try {
        StepTracker.instance.profileChanged();
      } catch (_) {}
      AppDataRevision.bump();
      if (!mounted) return;
      final msg = kind == PrivacyDeleteKind.allApp
          ? HomeText.getString(_lang, 'privacy_deleted_all_ok')
          : HomeText.format(_lang, 'privacy_deleted_one_ok', {'field': field});
      SnackBarer.show(
        context,
        message: msg,
        template: SnackbarTemplate.neutral,
        duration: const Duration(seconds: 3),
      );
      // Keep sheet open for single-section deletes; close only after full wipe.
      if (kind == PrivacyDeleteKind.allApp) {
        if (mounted) await _dismissSheet();
      } else if (mounted) {
        setState(() => _busy = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      SnackBarer.show(
        context,
        message: HomeText.getString(_lang, 'privacy_delete_error'),
        template: SnackbarTemplate.caution,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _chip({
    required String labelKey,
    required PrivacyDeleteKind kind,
    required IconData icon,
    bool danger = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bg = danger
        ? const Color(0xFFE11D48).withValues(alpha: 0.14)
        : cs.primary.withValues(alpha: 0.12);
    final fg = danger ? const Color(0xFFE11D48) : cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _busy ? null : () => _onTap(kind),
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: context.hS,
            vertical: context.vX2s + 2,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: fg.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              SizedBox(width: context.hXs),
              Expanded(
                child: Text(
                  HomeText.getString(_lang, labelKey),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.s,
                    color: fg,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.hM, context.vS, context.hM, bottom + context.vM,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            SizedBox(height: context.vS),
            Text(
              HomeText.getString(_lang, 'privacy_delete_sheet_title'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: context.m,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: context.vX3s),
            Text(
              HomeText.getString(_lang, 'privacy_delete_sheet_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.xs,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            SizedBox(height: context.vS),
            _chip(labelKey: 'privacy_del_gender', kind: PrivacyDeleteKind.gender, icon: Icons.wc_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_body', kind: PrivacyDeleteKind.body, icon: Icons.accessibility_new_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_age', kind: PrivacyDeleteKind.age, icon: Icons.cake_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_activity', kind: PrivacyDeleteKind.activity, icon: Icons.directions_run_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_diet', kind: PrivacyDeleteKind.diet, icon: Icons.restaurant_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_favorites', kind: PrivacyDeleteKind.favorites, icon: Icons.favorite_outline_rounded),
            SizedBox(height: context.vX2s),
            _chip(labelKey: 'privacy_del_restrictions', kind: PrivacyDeleteKind.restrictions, icon: Icons.warning_amber_rounded),
            SizedBox(height: context.vS),
            _chip(labelKey: 'privacy_del_all_app', kind: PrivacyDeleteKind.allApp, icon: Icons.delete_forever_rounded, danger: true),
            if (_busy) ...[
              SizedBox(height: context.vS),
              const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
