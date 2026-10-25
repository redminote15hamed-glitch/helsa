// lib/startup/setup/widget/search_bar.dart
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// Search field — rounded rectangle, leading icon flips search ↔ clear.
/// Search runs on submit (keyboard done) or when search icon is tapped.
class SearchBarer extends StatefulWidget {
  final String currentLang;
  final ValueChanged<String> onQueryCommitted;
  final ValueChanged<String>? onQueryChanged;
  final String? hintKey;

  const SearchBarer({
    super.key,
    required this.currentLang,
    required this.onQueryCommitted,
    this.onQueryChanged,
    this.hintKey,
  });

  @override
  State<SearchBarer> createState() => _SearchBarerState();
}

class _SearchBarerState extends State<SearchBarer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final bool next = _ctrl.text.trim().isNotEmpty;
      if (next != _hasText) setState(() => _hasText = next);
      widget.onQueryChanged?.call(_ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    _focus.unfocus();
    widget.onQueryCommitted(_ctrl.text.trim());
  }

  void _onIconTap() {
    if (_hasText) {
      _ctrl.clear();
      widget.onQueryCommitted('');
      widget.onQueryChanged?.call('');
      setState(() => _hasText = false);
    } else {
      _commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String hint = SetupText.getString(
      widget.currentLang,
      widget.hintKey ?? 'search_hint',
    );

    final iconBtn = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onIconTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.hX2s),
        child: Iconer(
          icon: _hasText ? Icons.close_rounded : Icons.search_rounded,
          template: IconTemplate.small,
          customColor: theme.colorScheme.onPrimary.withValues(alpha: 0.90),
          useGradient: false,
        ),
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        height: context.vXl.clamp(40.0, 52.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(context.s),
          border: Border.all(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.35),
            width: context.baseScale * 0.06,
          ),
        ),
        // Always LTR structure for field + icon placement:
        // icon on the START (left in LTR, right visual when parent is RTL via Directionality)
        // Text gets enough padding so it never sits under the icon.
        child: Row(
          children: [
            iconBtn,
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _commit(),
                onEditingComplete: _commit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: context.m,
                  height: 1.2,
                ),
                cursorColor: theme.colorScheme.onPrimary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: hint,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.45),
                    fontSize: context.m,
                    height: 1.2,
                  ),
                  contentPadding: EdgeInsets.only(
                    right: context.hX2s,
                    left: context.hX3s,
                    top: context.vX2s,
                    bottom: context.vX2s,
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
