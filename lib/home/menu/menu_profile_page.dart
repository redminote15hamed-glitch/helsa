// lib/home/menu/menu_profile_page.dart
// Profile editor: Genie in/out, full scroll, no section overlap, keyboard-safe.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/kit/snackbarer.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/activity_store.dart';
import 'package:helsa/setting/storage/age_store.dart';
import 'package:helsa/setting/storage/body_store.dart';
import 'package:helsa/setting/storage/diet_store.dart';
import 'package:helsa/setting/storage/gender_store.dart';
import 'package:helsa/setting/storage/identity_store.dart';
import 'package:helsa/setting/storage/sleep_store.dart';
import 'package:helsa/setting/storage/restriction_store.dart';
import 'package:helsa/setting/storage/favorite_store.dart';
import 'package:helsa/home/services/step_tracker.dart';
import 'package:helsa/startup/setup/widget/activity_setup.dart';
import 'package:helsa/startup/setup/widget/diet_setup.dart';
import 'package:helsa/startup/setup/widget/restriction_setup.dart';
import 'package:helsa/startup/setup/widget/favorite_food_setup.dart';
import 'package:helsa/startup/setup/widget/gender_setup.dart';

class MenuProfilePage {
  MenuProfilePage._();

  static Future<void> show(
    BuildContext context, {
    required String language,
    VoidCallback? onSaved,
    ThemeData? theme,
    Rect? origin,
  }) {
    final resolved = theme ?? Theme.of(context);
    final child = Theme(
      data: resolved,
      child: _ProfileHost(
        language: language,
        theme: resolved,
        onSaved: onSaved,
        skipGenie: origin != null,
      ),
    );
    if (origin != null) {
      return MenuExpandHost.open<void>(
        context: context,
        origin: origin,
        theme: resolved,
        builder: (_) => child,
      );
    }
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'profile',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, a, b) => child,
    );
  }
}

class _ProfileHost extends StatefulWidget {
  final String language;
  final ThemeData theme;
  final VoidCallback? onSaved;
  final bool skipGenie;

  const _ProfileHost({
    required this.language,
    required this.theme,
    this.onSaved,
    this.skipGenie = false,
  });

  @override
  State<_ProfileHost> createState() => _ProfileHostState();
}

class _ProfileHostState extends State<_ProfileHost> {
  bool _closing = false;
  int _genieKey = 0;
  Timer? _forcePop;

  void _requestClose() {
    if (widget.skipGenie) {
      MenuExpandScope.close(context);
      return;
    }
    if (_closing) return;
    setState(() {
      _closing = true;
      _genieKey++;
    });
    _forcePop?.cancel();
    _forcePop = Timer(const Duration(milliseconds: 1200), _onExitDone);
  }

  void _onExitDone() {
    _forcePop?.cancel();
    _forcePop = null;
    if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  void dispose() {
    _forcePop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const edge = GenieEdge.start;

    final page = _ProfileEditor(
      language: widget.language,
      theme: widget.theme,
      onRequestClose: _requestClose,
      onSaved: () {
        widget.onSaved?.call();
        _requestClose();
      },
    );

    if (widget.skipGenie) {
      return Material(
        type: MaterialType.transparency,
        child: page,
      );
    }

    final genieChild = KeyedSubtree(
      key: ValueKey(_closing ? 'ex-$_genieKey' : 'en-$_genieKey'),
      child: _closing
          ? page.exGenieReal(
              context,
              s: AS.slow,
              edge: edge,
              strips: 48,
              onComplete: _onExitDone,
            )
          : page.enGenieReal(
              context,
              s: AS.slow,
              edge: edge,
              strips: 48,
            ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _requestClose,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned.fill(child: genieChild),
        ],
      ),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  final String language;
  final ThemeData theme;
  final VoidCallback onRequestClose;
  final VoidCallback onSaved;

  const _ProfileEditor({
    required this.language,
    required this.theme,
    required this.onRequestClose,
    required this.onSaved,
  });

  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final TextEditingController _first;
  late final TextEditingController _last;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  late final TextEditingController _sleep;
  late final TextEditingController _wake;

  String? _gender;
  int? _activity;
  int? _diet;
  List<int> _restrictions = [];
  List<int> _favorites = [];

  late String _sFirst,
      _sLast,
      _sAge,
      _sHeight,
      _sWeight,
      _sWaist,
      _sSleep,
      _sWake;
  late String? _sGender;
  late int? _sActivity, _sDiet;
  late List<int> _sRestrictions, _sFavorites;

  final _scroll = ScrollController();

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  bool get _dirty {
    return _first.text.trim() != _sFirst ||
        _last.text.trim() != _sLast ||
        _age.text.trim() != _sAge ||
        _height.text.trim() != _sHeight ||
        _weight.text.trim() != _sWeight ||
        _waist.text.trim() != _sWaist ||
        _sleep.text.trim() != _sSleep ||
        _wake.text.trim() != _sWake ||
        _gender != _sGender ||
        _activity != _sActivity ||
        _diet != _sDiet ||
        !_listEq(_restrictions, _sRestrictions) ||
        !_listEq(_favorites, _sFavorites);
  }

  @override
  void initState() {
    super.initState();
    _sFirst = IdentityStore.firstName;
    _sLast = IdentityStore.lastName;
    _sGender = GenderStore.gender;
    _sAge = AgeStore.age?.toString() ?? '';
    _sHeight = BodyStore.height?.toString() ?? '';
    _sWeight = BodyStore.weight?.toString() ?? '';
    _sWaist = BodyStore.waist?.toString() ?? '';
    _sActivity = ActivityStore.activityLevel;
    _sDiet = DietStore.diet;
    _sRestrictions = List<int>.from(RestrictionStore.list);
    _sFavorites = List<int>.from(FavoriteStore.list);
    _sSleep = SleepStore.sleepTime ?? '';
    _sWake = SleepStore.wakeTime ?? '';

    _first = TextEditingController(text: _sFirst);
    _last = TextEditingController(text: _sLast);
    _age = TextEditingController(text: _sAge);
    _height = TextEditingController(text: _sHeight);
    _weight = TextEditingController(text: _sWeight);
    _waist = TextEditingController(text: _sWaist);
    _sleep = TextEditingController(text: _sSleep);
    _wake = TextEditingController(text: _sWake);
    _gender = _sGender;
    _activity = _sActivity;
    _diet = _sDiet;
    _restrictions = List<int>.from(_sRestrictions);
    _favorites = List<int>.from(_sFavorites);

    for (final c in [
      _first,
      _last,
      _age,
      _height,
      _weight,
      _waist,
      _sleep,
      _wake
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _waist.dispose();
    _sleep.dispose();
    _wake.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Age: clamp to sensible range
    int? age = int.tryParse(_age.text.trim());
    if (age != null) {
      if (age < 10) age = 10;
      if (age > 100) age = 100;
    }

    double? height = double.tryParse(_height.text.trim().replaceAll(',', '.'));
    double? weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    double? waist = double.tryParse(_waist.text.trim().replaceAll(',', '.'));
    if (height != null && height < 50) height = null; // reject nonsense cm
    if (weight != null && weight < 20) weight = null;
    if (waist != null && waist < 30) waist = null;

    await IdentityStore.save(
      firstName: _first.text,
      lastName: _last.text,
    );
    await GenderStore.save(_gender);
    await AgeStore.save(age);
    await BodyStore.save(
      height: height,
      weight: weight,
      waist: waist,
    );
    await ActivityStore.save(_activity);
    await DietStore.save(_diet);
    await RestrictionStore.save(_restrictions);
    await FavoriteStore.save(_favorites);
    await SleepStore.save(
      sleepTime: _sleep.text.trim().isEmpty ? null : _sleep.text.trim(),
      wakeTime: _wake.text.trim().isEmpty ? null : _wake.text.trim(),
    );

    try {
      StepTracker.instance.profileChanged();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _sFirst = _first.text.trim();
      _sLast = _last.text.trim();
      _sAge = age?.toString() ?? '';
      _sHeight = height?.toString() ?? '';
      _sWeight = weight?.toString() ?? '';
      _sWaist = waist?.toString() ?? '';
      _sGender = _gender;
      _sActivity = _activity;
      _sDiet = _diet;
      _sRestrictions = List<int>.from(_restrictions);
      _sFavorites = List<int>.from(_favorites);
      _sSleep = _sleep.text.trim();
      _sWake = _wake.text.trim();
      if (age != null) _age.text = '$age';
    });

    SnackBarer.show(
      context,
      message: HomeText.getString(_lang, 'profile_saved'),
      template: SnackbarTemplate.neutral,
      duration: const Duration(milliseconds: 1400),
    );
    widget.onSaved();
  }

  String get _lang => widget.language;

  Widget _sectionTitle(int n, String key) {
    final title = HomeText.format(_lang, 'profile_section', {
      'n': '$n',
      't': HomeText.getString(_lang, key),
    });
    return Padding(
      padding: EdgeInsets.only(top: context.vM, bottom: context.vX2s),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextFielder(
          text: title,
          languageCode: _lang,
          template: TextTemplate.subtitle,
          customStyle: TextStyle(
            fontWeight: FontWeight.w700,
            color: widget.theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _labeledField({
    required TextEditingController c,
    required String labelKey,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? helperKey,
  }) {
    final cs = widget.theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          HomeText.getString(_lang, labelKey),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        SizedBox(height: context.vX3s),
        TextField(
          controller: c,
          keyboardType: keyboard,
          inputFormatters: formatters,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
          cursorColor: cs.primary,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          decoration: InputDecoration(
            filled: true,
            // Stronger fill so boxes read clearly on dark & light
            fillColor: cs.brightness == Brightness.dark
                ? cs.primary.withValues(alpha: 0.12)
                : cs.primary.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: cs.primary.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: cs.primary.withValues(alpha: 0.55),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: cs.primary,
                width: 2.2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.hS,
              vertical: 14,
            ),
            helperText:
                helperKey == null ? null : HomeText.getString(_lang, helperKey),
            helperStyle: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }

  /// Intrinsic height — never a fixed % that causes section overlap.
  Widget _chipBlock({required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vX2s),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: widget.theme.colorScheme.surface,
      child: AnimatedTheme(
        data: widget.theme,
        duration: Duration.zero,
        child: Column(
          children: [
            // App bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.hX2s,
                top + context.vX2s,
                context.hX2s,
                context.vX2s,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onRequestClose,
                    icon: Icon(Icons.close_rounded, color: cs.onSurface),
                  ),
                  Expanded(
                    child: TextFielder(
                      text: HomeText.getString(_lang, 'menu_profile'),
                      languageCode: _lang,
                      template: TextTemplate.subtitle,
                      textAlign: TextAlign.center,
                      customStyle: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _dirty ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_dirty,
                      child: IconButton(
                        onPressed: _dirty ? _save : null,
                        icon: Icon(
                          Icons.check_rounded,
                          color: cs.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
                height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
            Expanded(
              child: ListView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  context.hS,
                  context.vX2s,
                  context.hS,
                  bottom + keyboard + 88,
                ),
                children: [
                  // 1 Name — clear boxes
                  _sectionTitle(1, 'profile_name'),
                  _labeledField(c: _first, labelKey: 'profile_first'),
                  SizedBox(height: context.vX2s),
                  _labeledField(c: _last, labelKey: 'profile_last'),

                  // 2 Gender
                  _sectionTitle(2, 'profile_gender'),
                  _chipBlock(
                    child: GenderSetup(
                      currentLang: _lang,
                      selectedGender: _gender,
                      onGenderSelected: (g) => setState(() => _gender = g),
                    ),
                  ),

                  // 3 Age — min 10
                  _sectionTitle(3, 'profile_age'),
                  _labeledField(
                    c: _age,
                    labelKey: 'profile_age_hint',
                    helperKey: 'profile_age_helper',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  // 4 Body — height, waist, weight
                  _sectionTitle(4, 'profile_body'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _labeledField(
                          c: _height,
                          labelKey: 'profile_height',
                          helperKey: 'profile_height_helper',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: context.hX2s),
                      Expanded(
                        child: _labeledField(
                          c: _weight,
                          labelKey: 'profile_weight',
                          helperKey: 'profile_weight_helper',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.vX2s),
                  _labeledField(
                    c: _waist,
                    labelKey: 'profile_waist',
                    helperKey: 'profile_waist_helper',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  // 5 Activity — natural height, not cramped fixed box
                  _sectionTitle(5, 'profile_activity'),
                  _chipBlock(
                    child: ActivitySetup(
                      currentLang: _lang,
                      selectedLevel: _activity,
                      onActivitySelected: (v) => setState(() => _activity = v),
                    ),
                  ),

                  // 6 Diet
                  _sectionTitle(6, 'profile_diet'),
                  _chipBlock(
                    child: DietSetup(
                      currentLang: _lang,
                      selectedDiet: _diet,
                      onDietSelected: (v) => setState(() => _diet = v),
                    ),
                  ),

                  // 7 Restrictions — NO fixed 42% height (was causing overlap)
                  _sectionTitle(7, 'profile_restrictions'),
                  _chipBlock(
                    child: RestrictionSetup(
                      currentLang: _lang,
                      selectedRestrictions: _restrictions,
                      onChanged: (v) {
                        setState(() {
                          _restrictions = List<int>.from(v);
                          final hidden = FavoriteFoodSetup.hiddenFavoriteIds(
                              _restrictions);
                          _favorites = _favorites
                              .where((id) => !hidden.contains(id))
                              .toList();
                        });
                      },
                    ),
                  ),

                  // 8 Favorites
                  _sectionTitle(8, 'profile_favorites'),
                  _chipBlock(
                    child: FavoriteFoodSetup(
                      currentLang: _lang,
                      selectedFoods: _favorites,
                      selectedRestrictions: _restrictions,
                      onChanged: (v) {
                        setState(() => _favorites = List<int>.from(v));
                      },
                    ),
                  ),

                  // 9 Sleep
                  _sectionTitle(9, 'profile_sleep'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _labeledField(
                          c: _sleep,
                          labelKey: 'profile_sleep_time',
                        ),
                      ),
                      SizedBox(width: context.hX2s),
                      Expanded(
                        child: _labeledField(
                          c: _wake,
                          labelKey: 'profile_wake_time',
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: context.vS),
                  TextFielder(
                    text: HomeText.getString(_lang, 'profile_save_hint'),
                    languageCode: _lang,
                    template: TextTemplate.caption,
                    textAlign: TextAlign.center,
                    customStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  SizedBox(height: context.vS),
                ],
              ),
            ),

            // Sticky save bar when dirty — visible while scrolling
            AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _dirty ? Offset.zero : const Offset(0, 1.1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _dirty ? 1 : 0,
                child: Material(
                  elevation: 12,
                  color: cs.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.hS,
                        context.vX2s,
                        context.hS,
                        context.vX2s + (keyboard > 0 ? 0 : 0),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _dirty ? _save : null,
                          icon: const Icon(Icons.check_rounded),
                          label: Text(
                            HomeText.getString(_lang, 'confirm'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
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
}
