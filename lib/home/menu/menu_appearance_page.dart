import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:helsa/setting/motion/motion_settings.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/appearance_chrome.dart';
import 'package:helsa/home/menu/appearance_theme_card.dart';
import 'package:helsa/home/menu/appearance_metric_preview.dart';
import 'package:helsa/home/menu/appearance_orbit_ring.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/setting/color/metric_colors.dart';
import 'package:helsa/setting/color/theme_color.dart';
import 'package:helsa/setting/color/theme_palette.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';
import 'package:helsa/setting/storage/theme_store.dart';
import 'package:helsa/setting/branding/launcher_icon_service.dart';

/// Appearance — local preview until tick / continue; then saves + closes.
/// Opened via [MenuExpandHost] overlay → close with [MenuExpandScope.close].
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
  late final AnimationController _cardCtrl;
  late final AnimationController _burstCtrl; // 0=heart center, 1=icons on ring
  late final AnimationController _ringPulse;
  late final AnimationController _wave;
  double _orbitAngle = 0;
  bool _busy = false; // intro / exit / switch in progress

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
    // Card starts hidden — only after icons land
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 0,
    );
    // Soft open burst; close will temporarily speed up
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
      value: 0,
    );
    _ringPulse = AnimationController(
      vsync: this,
      duration: MotionSettings.ms(4800),
    );
    _wave = AnimationController(
      vsync: this,
      duration: MotionSettings.ms(2400),
    );
    if (!MotionSettings.simple) {
      _ringPulse.repeat();
      _wave.repeat();
    } else {
      _ringPulse.value = 0;
      _wave.value = 0;
    }
    _orbitAngle = _angleForIndex(_selectedIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) => _playOpen());
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _cardCtrl.dispose();
    _burstCtrl.dispose();
    _ringPulse.dispose();
    _wave.dispose();
    super.dispose();
  }

  double _angleForIndex(int index) {
    final n = _palettes.length;
    return -math.pi / 2 - (index * 2 * math.pi / n);
  }

  Future<void> _playOpen() async {
    if (!mounted) return;
    _busy = true;
    // Wait until MenuExpandHost two-phase expand is fully done (~1.3s),
    // THEN play heart → icons → theme card. Never start mid-expand.
    await Future<void>.delayed(MotionSettings.ms(MotionSettings.simple ? 120 : 1380));
    if (!mounted) return;
    _burstCtrl.duration = MotionSettings.ms(MotionSettings.simple ? 200 : 980);
    if (MotionSettings.simple) {
      _burstCtrl.value = 1;
      _cardCtrl.duration = MotionSettings.ms(220);
      await _cardCtrl.forward(from: 0);
    } else {
      await _burstCtrl.forward(from: 0);
      if (!mounted) return;
      await Future<void>.delayed(MotionSettings.ms(80));
      if (!mounted) return;
      _cardCtrl.duration = MotionSettings.ms(420);
      await _cardCtrl.forward(from: 0);
    }
    if (!mounted) return;
    _busy = false;
  }

  Future<void> _playCloseAndDismiss({required bool save}) async {
    if (_busy) return;
    _busy = true;
    if (save) {
      // Persist theme FIRST. Icon switch can kill the process on some OEMs —
      // if it runs before Hive write, theme is lost and icon reverts on next open.
      ThemeStore.paletteId.value = _paletteId;
      ThemeStore.night.value = _night;
      try {
        await ThemeStore.save();
      } catch (e, st) {
        debugPrint('ThemeStore.save failed: $e\n$st');
      }
    }
    // Do not touch launcher icon until after close animation (see _saveAndClose).
    if (!mounted) return;

    // Card retreats first (quick)
    _cardCtrl.duration = MotionSettings.ms(220);
    if (_cardCtrl.value > 0) {
      await _cardCtrl.reverse();
    }
    if (!mounted) return;

    // Short hold, then icons collapse into heart (faster than open)
    await Future<void>.delayed(MotionSettings.ms(90));
    if (!mounted) return;
    _burstCtrl.duration = MotionSettings.ms(420);
    await _burstCtrl.reverse();
    if (!mounted) return;

    await Future<void>.delayed(MotionSettings.ms(40));
    if (!mounted) return;
    await MenuExpandScope.close(context);
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

  Future<void> _onSelectPalette(int index) async {
    if (_busy) return;
    final p = _palettes[index];
    if (p.id == _paletteId) return;
    _busy = true;
    // Card soft-returns into orbit icon, then new card emerges
    await _cardCtrl.reverse();
    if (!mounted) return;
    setState(() => _paletteId = p.id);
    // Icon applies only on Save — mid-select switch kills the process on many
    // Android OEMs and leaves theme unsaved / icon out of sync.
    await Future.wait([
      _rotateTo(index),
      _cardCtrl.forward(),
    ]);
    if (!mounted) return;
    _busy = false;
  }

  Future<void> _saveAndClose() async {
    final paletteToApply = _paletteId;
    final paletteChanged = _paletteId != _savedPaletteId;
    await _playCloseAndDismiss(save: true);
    // After UI is gone + theme is on disk, switch icon safely.
    if (paletteChanged) {
      // Small delay so the expand host finishes removing the overlay.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      try {
        await LauncherIconService.applyForPalette(paletteToApply);
      } catch (e, st) {
        debugPrint('launcher icon after save: $e\n$st');
      }
    }
  }

  Future<void> _back() async {
    await _playCloseAndDismiss(save: false);
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = AppTheme.fromPalette(_selected, night: _night);
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
                  AppearanceTopBar(
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

                        // Responsive: bigger preview, card glued to orbit.
                        // Below min orbit size → scroll instead of crushing.
                        final applyReserve = _dirty ? 64.0 : 8.0;
                        final usableH = (h - applyReserve).clamp(320.0, h);
                                                final tight = usableH < 480;

                        final appleSize = (w * (tight ? 0.19 : 0.21))
                            .clamp(tight ? 54.0 : 64.0, tight ? 72.0 : 92.0);
                        final cardSide =
                            (w * 0.50).clamp(160.0, tight ? 190.0 : 220.0);
                        // Orbit: prefer ~48% width, never below readable floor
                        // unless forced by remaining height (then scroll).
                        final orbitIdeal =
                            (math.min(w, usableH) * 0.48).clamp(200.0, 300.0);
                        final orbitMin = 168.0;
                        final orbitSize = orbitIdeal;

                        final column = Column(
                          children: [
                            SizedBox(height: context.vX3s * 0.35),
                            AnimatedBuilder(
                              animation: _wave,
                              builder: (context, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppearancePreviewApple(
                                      label: HomeText.getString(
                                          _lang, 'appearance_preview_steps'),
                                      color: metrics.steps,
                                      fill: 0.62,
                                      size: appleSize,
                                      wave: _wave.value,
                                    ),
                                    SizedBox(width: w * 0.05),
                                    AppearancePreviewApple(
                                      label: HomeText.getString(
                                          _lang, 'appearance_preview_cal'),
                                      color: metrics.calories,
                                      fill: 0.38,
                                      size: appleSize,
                                      wave: _wave.value + 0.33,
                                    ),
                                    SizedBox(width: w * 0.05),
                                    AppearancePreviewApple(
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
                            AppearanceHeartDock(
                              // Real theme colors only — same as apples / app metrics.
                              colors: [
                                metrics.steps,
                                metrics.calories,
                                metrics.active,
                                cs.primary,
                                cs.secondary,
                              ],
                              width: w * 0.62,
                            ),
                            // Push description card down toward the orbit ring
                            const Spacer(flex: 2),
                            AnimatedBuilder(
                              animation: _cardCtrl,
                              builder: (context, child) {
                                final tCard = Curves.easeOutCubic
                                    .transform(_cardCtrl.value);
                                return Opacity(
                                  opacity: tCard.clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - tCard) * 36),
                                    child: Transform.scale(
                                      scale: 0.35 + 0.65 * tCard,
                                      alignment: Alignment.bottomCenter,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: AppearanceThemeInfoCard(
                                palette: _selected,
                                night: _night,
                                lang: _lang,
                                side: cardSide,
                                onDay: () => setState(() => _night = false),
                                onNight: () => setState(() => _night = true),
                              ),
                            ),
                            // Tight gap — card sticks to theme picker
                            SizedBox(height: context.vS * 0.35),
                            Expanded(
                              flex: 5,
                              child: LayoutBuilder(
                                builder: (context, orbitBox) {
                                  // Fit orbit into remaining space; floor at orbitMin
                                  final available = math.min(
                                    orbitBox.maxWidth,
                                    orbitBox.maxHeight,
                                  );
                                  // Never crush below readable floor; scroll if needed.
                                  final side = available < orbitMin
                                      ? orbitMin
                                      : math.min(available, orbitSize);
                                  final needsScroll =
                                      orbitBox.maxHeight + 0.5 < orbitMin;

                                  Widget ring = SizedBox(
                                    height: side,
                                    width: side,
                                    child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _ringPulse,
                                      _burstCtrl,
                                    ]),
                                    builder: (context, _) {
                                      return AppearanceOrbitRing(
                                        palettes: _palettes,
                                        selectedIndex: _selectedIndex,
                                        angle: _orbitAngle,
                                        pulse: _ringPulse.value,
                                        burst: _burstCtrl.value,
                                        accent: cs.primary,
                                        onSelect: _onSelectPalette,
                                      );
                                    },
                                  ),
                                  );

                                  if (needsScroll) {
                                    return SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: SizedBox(
                                        height: orbitMin + 8,
                                        child: Center(child: ring),
                                      ),
                                    );
                                  }
                                  return Center(child: ring);
                                },
                              ),
                            ),
                            AppearanceApplyBar(
                              lang: _lang,
                              visible: _dirty,
                              onApply: _saveAndClose,
                            ),
                            SizedBox(
                              height: bottomInset > 0
                                  ? bottomInset * 0.15
                                  : context.vX3s * 0.5,
                            ),
                          ],
                        );

                        if (tight) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: usableH),
                              child: column,
                            ),
                          );
                        }
                        return column;
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

