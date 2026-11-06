// lib/home/menu/menu_privacy_page.dart
// Privacy policy (on-device only) + selective data deletion sheet.
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/diet_store.dart';
import 'package:helsa/setting/storage/favorite_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/restriction_store.dart';
import 'package:helsa/setting/storage/sleep_store.dart';
import 'package:helsa/home/services/step_tracker.dart';

/// Privacy & data control — opened via [MenuExpandHost].
class MenuPrivacyPage extends StatelessWidget {
  const MenuPrivacyPage({super.key, this.language});

  final String? language;

  String get _lang => language ?? 'en';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.hS,
                vertical: context.vX2s,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => MenuExpandScope.close(context),
                    icon: Icon(
                      isRtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      color: cs.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      HomeText.getString(_lang, 'menu_privacy'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.l,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.hM,
                  context.vS,
                  context.hM,
                  context.vM,
                ),
                children: [
                  // On-device badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.hS,
                      vertical: context.vX2s,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phonelink_lock_rounded,
                            color: cs.primary, size: 22),
                        SizedBox(width: context.hXs),
                        Expanded(
                          child: Text(
                            HomeText.getString(
                                _lang, 'privacy_on_device_badge'),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: context.s,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.vM),
                  Text(
                    HomeText.getString(_lang, 'privacy_title'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.m,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: context.vX2s),
                  Text(
                    HomeText.getString(_lang, 'privacy_body'),
                    style: TextStyle(
                      height: 1.55,
                      fontSize: context.s,
                      color: cs.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                  SizedBox(height: context.vM),
                  Text(
                    HomeText.getString(_lang, 'privacy_points_title'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.s,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: context.vX2s),
                  for (final key in const [
                    'privacy_point_local',
                    'privacy_point_encrypt',
                    'privacy_point_control',
                    'privacy_point_no_cloud',
                  ])
                    Padding(
                      padding: EdgeInsets.only(bottom: context.vX2s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: cs.primary),
                          SizedBox(width: context.hXs),
                          Expanded(
                            child: Text(
                              HomeText.getString(_lang, key),
                              style: TextStyle(
                                height: 1.4,
                                fontSize: context.s,
                                color:
                                    cs.onSurface.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Delete-data capsule
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.hM,
                0,
                context.hM,
                bottom + context.vS,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _showDeleteSheet(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: context.vS * 0.85,
                      horizontal: context.hS,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.75),
                        width: 1.6,
                      ),
                      color: cs.primary.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: cs.primary, size: 20),
                        SizedBox(width: context.hXs),
                        Text(
                          HomeText.getString(_lang, 'privacy_delete_data'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: context.m,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteSheet(BuildContext context) async {
    final lang = _lang;
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'delete-data',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim, sec) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, sec, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _DeleteDataSheet(language: lang),
            ),
          ),
        );
      },
    );
  }
}

enum _DeleteKind {
  gender,
  body,
  age,
  activity,
  diet,
  favorites,
  restrictions,
  allExceptName,
}

class _DeleteDataSheet extends StatefulWidget {
  const _DeleteDataSheet({required this.language});

  final String language;

  @override
  State<_DeleteDataSheet> createState() => _DeleteDataSheetState();
}

class _DeleteDataSheetState extends State<_DeleteDataSheet> {
  bool _busy = false;
  _DeleteKind? _done;

  String get _lang => widget.language;

  Future<void> _clear(_DeleteKind kind) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      switch (kind) {
        case _DeleteKind.gender:
          await GenderStore.open();
          await GenderStore.clear();
        case _DeleteKind.body:
          await BodyStore.open();
          await BodyStore.clear();
        case _DeleteKind.age:
          await AgeStore.open();
          await AgeStore.clear();
        case _DeleteKind.activity:
          await ActivityStore.open();
          await ActivityStore.clear();
        case _DeleteKind.diet:
          await DietStore.open();
          await DietStore.clear();
        case _DeleteKind.favorites:
          await FavoriteStore.open();
          await FavoriteStore.clear();
        case _DeleteKind.restrictions:
          await RestrictionStore.open();
          await RestrictionStore.clear();
        case _DeleteKind.allExceptName:
          // Keep firstName / lastName — clear everything else listed + sleep
          await Future.wait([
            GenderStore.open(),
            AgeStore.open(),
            BodyStore.open(),
            ActivityStore.open(),
            DietStore.open(),
            FavoriteStore.open(),
            RestrictionStore.open(),
            SleepStore.open(),
            IdentityStore.open(),
          ]);
          final first = IdentityStore.firstName;
          final last = IdentityStore.lastName;
          final avatarPreset = IdentityStore.avatarPreset;
          final avatarPath = IdentityStore.avatarPath;
          await GenderStore.clear();
          await AgeStore.clear();
          await BodyStore.clear();
          await ActivityStore.clear();
          await DietStore.clear();
          await FavoriteStore.clear();
          await RestrictionStore.clear();
          await SleepStore.clear();
          // Restore name (and avatar so identity shell stays usable)
          await IdentityStore.save(firstName: first, lastName: last);
          if (avatarPath.isNotEmpty) {
            await IdentityStore.saveAvatarFile(avatarPath);
          } else if (avatarPreset.isNotEmpty) {
            await IdentityStore.saveAvatarPreset(avatarPreset);
          }
      }
      // Refresh goals (standard if profile incomplete) + UI listeners
      try {
        StepTracker.instance.profileChanged();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _done = kind;
        _busy = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget chip({
      required String labelKey,
      required _DeleteKind kind,
      required IconData icon,
      bool danger = false,
    }) {
      final selected = _done == kind;
      // All colors from theme; "danger" = stronger primary, not red
      final bg = danger
          ? cs.primary.withValues(alpha: selected ? 0.32 : 0.18)
          : cs.surfaceContainerHighest.withValues(alpha: 0.95);
      final fg = danger ? cs.primary : cs.onSurface;
      final border = danger
          ? cs.primary
          : cs.outline.withValues(alpha: 0.22);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _busy ? null : () => _clear(kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: context.hS,
              vertical: context.vS * 0.72,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: danger ? 1.5 : 1.1),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: fg),
                SizedBox(width: context.hXs),
                Expanded(
                  child: Text(
                    HomeText.getString(_lang, labelKey),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: context.s,
                      color: fg,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 18, color: fg)
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: fg.withValues(alpha: 0.45)),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(
          context.hM,
          0,
          context.hM,
          bottom + context.vS,
        ),
        padding: EdgeInsets.fromLTRB(
          context.hM,
          context.vM,
          context.hM,
          context.vS,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: context.vS),
            Text(
              HomeText.getString(_lang, 'privacy_delete_sheet_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
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
            chip(
              labelKey: 'privacy_del_gender',
              kind: _DeleteKind.gender,
              icon: Icons.wc_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_body',
              kind: _DeleteKind.body,
              icon: Icons.accessibility_new_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_age',
              kind: _DeleteKind.age,
              icon: Icons.cake_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_activity',
              kind: _DeleteKind.activity,
              icon: Icons.directions_run_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_diet',
              kind: _DeleteKind.diet,
              icon: Icons.restaurant_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_favorites',
              kind: _DeleteKind.favorites,
              icon: Icons.favorite_outline_rounded,
            ),
            SizedBox(height: context.vX2s),
            chip(
              labelKey: 'privacy_del_restrictions',
              kind: _DeleteKind.restrictions,
              icon: Icons.warning_amber_rounded,
            ),
            SizedBox(height: context.vS),
            chip(
              labelKey: 'privacy_del_all_except_name',
              kind: _DeleteKind.allExceptName,
              icon: Icons.delete_forever_rounded,
              danger: true,
            ),
            if (_busy) ...[
              SizedBox(height: context.vS),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
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
