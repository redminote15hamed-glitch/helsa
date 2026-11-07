import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/appearance_chrome.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/storage/meta_store.dart';

/// Settings — language only for now. Same tick / apply chrome as Appearance.
class MenuSettingsPage extends StatefulWidget {
  const MenuSettingsPage({super.key, this.language});

  final String? language;

  @override
  State<MenuSettingsPage> createState() => _MenuSettingsPageState();
}

class _MenuSettingsPageState extends State<MenuSettingsPage> {
  late String _previewLang;
  late String _savedLang;

  static const _options = <_LangOpt>[
    _LangOpt('fa', 'فارسی', 'Persian'),
    _LangOpt('en', 'English', 'English'),
    _LangOpt('fr', 'Français', 'French'),
  ];

  @override
  void initState() {
    super.initState();
    try {
      _savedLang = MetaStore.language;
    } catch (_) {
      _savedLang = widget.language ?? 'en';
    }
    _previewLang = _savedLang;
  }

  bool get _dirty => _previewLang != _savedLang;
  bool get _isRtl => _previewLang == 'fa';

  String get _uiLang => _previewLang;

  void _close() {
    // MenuExpandScope.close already falls back to Navigator.pop
    MenuExpandScope.close(context);
  }

  Future<void> _saveAndClose() async {
    if (_dirty) {
      try {
        await MetaStore.open();
        await MetaStore.setLanguage(_previewLang);
        _savedLang = _previewLang;
      } catch (e, st) {
        debugPrint('MetaStore.setLanguage failed: $e\n$st');
      }
    }
    if (!mounted) return;
    _close();
  }

  void _onBack() {
    // Discard preview — do not save.
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pad = MediaQuery.paddingOf(context);

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: cs.surface,
        child: SafeArea(
          child: Column(
            children: [
              AppearanceTopBar(
                lang: _uiLang,
                titleKey: 'menu_settings',
                dirty: _dirty,
                isRtl: _isRtl,
                onBack: _onBack,
                onSave: _dirty ? _saveAndClose : null,
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
                    Text(
                      HomeText.getString(_uiLang, 'settings_language_title'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.m,
                        color: cs.onSurface,
                      ),
                    ),
                    SizedBox(height: context.vX2s),
                    Text(
                      HomeText.getString(_uiLang, 'settings_language_hint'),
                      style: TextStyle(
                        fontSize: context.s,
                        color: cs.onSurface.withValues(alpha: 0.65),
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: context.vM),
                    for (final opt in _options) ...[
                      _LanguageTile(
                        opt: opt,
                        selected: _previewLang == opt.code,
                        onTap: () => setState(() => _previewLang = opt.code),
                      ),
                      SizedBox(height: context.vS),
                    ],
                  ],
                ),
              ),
              AppearanceApplyBar(
                lang: _uiLang,
                visible: _dirty,
                onApply: _saveAndClose,
              ),
              SizedBox(height: pad.bottom > 0 ? pad.bottom * 0.3 : context.vS),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOpt {
  const _LangOpt(this.code, this.nativeName, this.englishName);
  final String code;
  final String nativeName;
  final String englishName;
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.opt,
    required this.selected,
    required this.onTap,
  });

  final _LangOpt opt;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.14)
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.hM,
            vertical: context.vS * 1.1,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? cs.primary.withValues(alpha: 0.85)
                  : cs.onSurface.withValues(alpha: 0.08),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
              ),
              SizedBox(width: context.hS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.nativeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.m,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      opt.englishName,
                      style: TextStyle(
                        fontSize: context.s * 0.95,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
