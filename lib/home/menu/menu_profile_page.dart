// lib/home/menu/menu_profile_page.dart
// Profile editor: Genie in from menu item, Genie out (vacuum) back into it.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/kit/textfielder.dart';
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
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'profile',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, a, b) {
        return _ProfileHost(
          language: language,
          theme: Theme.of(context),
          onSaved: onSaved,
        );
      },
    );
  }
}

class _ProfileHost extends StatefulWidget {
  final String language;
  final ThemeData theme;
  final VoidCallback? onSaved;

  const _ProfileHost({
    required this.language,
    required this.theme,
    this.onSaved,
  });

  @override
  State<_ProfileHost> createState() => _ProfileHostState();
}

class _ProfileHostState extends State<_ProfileHost> {
  bool _closing = false;
  int _genieKey = 0;
  Timer? _forcePop;

  void _requestClose() {
    if (_closing) return;
    setState(() {
      _closing = true;
      _genieKey++;
    });
    _forcePop?.cancel();
    _forcePop = Timer(const Duration(milliseconds: 1100), _onExitDone);
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
    // Vacuum back into menu (start edge) — like Mac Genie into the dock item.
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

    final genieChild = KeyedSubtree(
      key: ValueKey(_closing ? 'ex-$_genieKey' : 'en-$_genieKey'),
      child: _closing
          ? page.exGenieReal(
              context,
              s: AS.balanced,
              edge: edge,
              strips: 40,
              onComplete: _onExitDone,
            )
          : page.enGenieReal(
              context,
              s: AS.slow,
              edge: edge,
              strips: 40,
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
  late final TextEditingController _sleep;
  late final TextEditingController _wake;

  String? _gender;
  int? _activity;
  int? _diet;
  List<int> _restrictions = [];
  List<int> _favorites = [];

  // Snapshot for dirty detection
  late String _sFirst, _sLast, _sAge, _sHeight, _sWeight, _sSleep, _sWake;
  late String? _sGender;
  late int? _sActivity, _sDiet;
  late List<int> _sRestrictions, _sFavorites;

  bool get _dirty {
    return _first.text.trim() != _sFirst ||
        _last.text.trim() != _sLast ||
        _age.text.trim() != _sAge ||
        _height.text.trim() != _sHeight ||
        _weight.text.trim() != _sWeight ||
        _sleep.text.trim() != _sSleep ||
        _wake.text.trim() != _sWake ||
        _gender != _sGender ||
        _activity != _sActivity ||
        _diet != _sDiet ||
        !_listEq(_restrictions, _sRestrictions) ||
        !_listEq(_favorites, _sFavorites);
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
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
    _sleep = TextEditingController(text: _sSleep);
    _wake = TextEditingController(text: _sWake);
    _gender = _sGender;
    _activity = _sActivity;
    _diet = _sDiet;
    _restrictions = List<int>.from(_sRestrictions);
    _favorites = List<int>.from(_sFavorites);

    for (final c in [_first, _last, _age, _height, _weight, _sleep, _wake]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _sleep.dispose();
    _wake.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await IdentityStore.save(
      firstName: _first.text,
      lastName: _last.text,
    );
    await GenderStore.save(_gender);
    final age = int.tryParse(_age.text.trim());
    await AgeStore.save(age);
    await BodyStore.save(
      height: double.tryParse(_height.text.trim()),
      weight: double.tryParse(_weight.text.trim()),
      waist: BodyStore.waist,
    );
    await ActivityStore.save(_activity);
    await DietStore.save(_diet);
    await RestrictionStore.save(_restrictions);
    await FavoriteStore.save(_favorites);
    await SleepStore.save(
      sleepTime: _sleep.text.trim().isEmpty ? null : _sleep.text.trim(),
      wakeTime: _wake.text.trim().isEmpty ? null : _wake.text.trim(),
    );
    if (!mounted) return;
    widget.onSaved();
  }

  String get _lang => widget.language;

  Widget _sectionTitle(int n, String key) {
    final title = HomeText.format(_lang, 'profile_section', {
      'n': '$n',
      't': HomeText.getString(_lang, key),
    });
    return Padding(
      padding: EdgeInsets.only(top: context.vS, bottom: context.vX2s),
      child: TextFielder(
        text: title,
        languageCode: _lang,
        template: TextTemplate.subtitle,
        customStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: widget.theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController c,
    required String hintKey,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    final cs = widget.theme.colorScheme;
    return TextField(
      controller: c,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: TextStyle(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: HomeText.getString(_lang, hintKey),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.hS,
          vertical: context.vX2s,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: cs.surface,
      child: SafeArea(
        top: false,
        bottom: false,
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
                  // Save check — only when dirty
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
            Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.hS,
                  context.vX2s,
                  context.hS,
                  bottom + context.vXl,
                ),
                children: [
                  // 1 Name
                  _sectionTitle(1, 'profile_name'),
                  _field(c: _first, hintKey: 'profile_first'),
                  SizedBox(height: context.vX2s),
                  _field(c: _last, hintKey: 'profile_last'),

                  // 2 Gender
                  _sectionTitle(2, 'profile_gender'),
                  GenderSetup(
                    currentLang: _lang,
                    selectedGender: _gender,
                    onGenderSelected: (g) {
                      setState(() => _gender = g);
                    },
                  ),

                  // 3 Age
                  _sectionTitle(3, 'profile_age'),
                  _field(
                    c: _age,
                    hintKey: 'profile_age_hint',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),

                  // 4 Body
                  _sectionTitle(4, 'profile_body'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          c: _height,
                          hintKey: 'profile_height',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                      SizedBox(width: context.hX2s),
                      Expanded(
                        child: _field(
                          c: _weight,
                          hintKey: 'profile_weight',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 5 Activity
                  _sectionTitle(5, 'profile_activity'),
                  ActivitySetup(
                    currentLang: _lang,
                    selectedLevel: _activity,
                    onActivitySelected: (v) {
                      setState(() => _activity = v);
                    },
                  ),

                  // 6 Diet
                  _sectionTitle(6, 'profile_diet'),
                  DietSetup(
                    currentLang: _lang,
                    selectedDiet: _diet,
                    onDietSelected: (v) {
                      setState(() => _diet = v);
                    },
                  ),

                  // 7 Restrictions
                  _sectionTitle(7, 'profile_restrictions'),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.42,
                    child: RestrictionSetup(
                      currentLang: _lang,
                      selectedRestrictions: _restrictions,
                      onChanged: (v) {
                        setState(() {
                          _restrictions = List<int>.from(v);
                          final hidden =
                              FavoriteFoodSetup.hiddenFavoriteIds(_restrictions);
                          _favorites = _favorites
                              .where((id) => !hidden.contains(id))
                              .toList();
                        });
                      },
                    ),
                  ),

                  // 8 Favorites
                  _sectionTitle(8, 'profile_favorites'),
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.42,
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
                    children: [
                      Expanded(
                        child: _field(c: _sleep, hintKey: 'profile_sleep_time'),
                      ),
                      SizedBox(width: context.hX2s),
                      Expanded(
                        child: _field(c: _wake, hintKey: 'profile_wake_time'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
