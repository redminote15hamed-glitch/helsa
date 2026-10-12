// lib/setting/kit/pageviewer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/displayer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/search_bar.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

/// One selectable chip in [PageViewer].
class PageViewerItem {
  final int id;
  final IconData icon;
  final String titleKey;

  const PageViewerItem({
    required this.id,
    required this.icon,
    required this.titleKey,
  });

  factory PageViewerItem.fromMap(Map<String, dynamic> m) => PageViewerItem(
        id: m['id'] as int,
        icon: m['icon'] as IconData,
        titleKey: m['title'] as String,
      );
}

/// Shared green box: search + paged chip grid + dots.
/// Used by restriction, favorite food, etc.
class PageViewer extends StatefulWidget {
  final String currentLang;
  final List<PageViewerItem> items;
  final List<int> selectedIds;
  final ValueChanged<List<int>> onChanged;
  final String? subtitleKey;
  final bool showSearch;
  final String searchHintKey;
  final String noResultsKey;

  const PageViewer({
    super.key,
    required this.currentLang,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    this.subtitleKey,
    this.showSearch = true,
    this.searchHintKey = 'search_hint',
    this.noResultsKey = 'search_no_results',
  });

  @override
  State<PageViewer> createState() => _PageViewerState();
}

class _PageViewerState extends State<PageViewer> {
  late final PageController _pageCtrl;
  int _page = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    final next = q.trim();
    if (next == _query) return;
    setState(() {
      _query = next;
      _page = 0;
    });
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
  }

  List<PageViewerItem> get _filtered {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      final label = SetupText.getString(
        widget.currentLang,
        item.titleKey,
      ).toLowerCase();
      return label.contains(q);
    }).toList();
  }

  void _toggle(int id) {
    final List<int> next = List<int>.from(widget.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onChanged(next);
  }

  int _capacityFor(double innerSide, BuildContext context) {
    final double gap = context.hX3s;
    int cols = 2;
    if (innerSide > 340) cols = 3;
    if (innerSide > 420) cols = 4;
    final double chipH = math.max(44.0, context.m + context.vX2s * 2 + 8);
    final int rows = math.max(3, ((innerSide + gap) / (chipH + gap)).floor());
    return (cols * rows).clamp(9, 24);
  }

  List<List<PageViewerItem>> _pages(int perPage) {
    final source = _filtered;
    if (source.isEmpty) return [];
    final out = <List<PageViewerItem>>[];
    for (int i = 0; i < source.length; i += perPage) {
      out.add(source.sublist(i, math.min(i + perPage, source.length)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.subtitleKey != null) ...[
          Displayer(
            index: 1,
            template: MotionTemplate.bottomSlide,
            child: TextFielder(
              text: SetupText.getString(
                widget.currentLang,
                widget.subtitleKey!,
              ),
              template: TextTemplate.body,
              textAlign: TextAlign.center,
              customStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.60),
                fontSize: context.baseScale * 0.95,
              ),
            ),
          ),
          SizedBox(height: context.vS),
        ],
        Displayer(
          index: 2,
          template: MotionTemplate.flipX,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final Size screen = MediaQuery.sizeOf(context);
              final double maxW = constraints.maxWidth.isFinite &&
                      constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : screen.width;
              final double maxH = screen.height * 0.62;
              double side = math.min(maxW * 0.96, maxH);
              if (constraints.maxHeight.isFinite &&
                  constraints.maxHeight > 0) {
                final double byParent = constraints.maxHeight * 0.95;
                side = math.min(math.max(side, byParent * 0.85), byParent);
                side = math.min(side, maxW * 0.96);
              }
              if (side < 220) side = math.min(220.0, maxW * 0.98);

              final double greenPad = context.s;
              final double innerSide = (side - greenPad * 2).clamp(40.0, side);
              final int perPage = _capacityFor(innerSide, context);
              final pages = _pages(perPage);
              if (pages.isNotEmpty && _page >= pages.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _page = pages.length - 1);
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.m),
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          padding: EdgeInsets.all(greenPad),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(context.m),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.22),
                                blurRadius: context.s,
                                offset: Offset(0, context.vX4s),
                              ),
                            ],
                          ),
                          child: Container(
                            clipBehavior: Clip.hardEdge,
                            padding: EdgeInsets.all(context.x2s),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(context.s),
                            ),
                            child: Column(
                              children: [
                                if (widget.showSearch) ...[
                                  SearchBarer(
                                    currentLang: widget.currentLang,
                                    onQueryCommitted: _setQuery,
                                    onQueryChanged: _setQuery,
                                    hintKey: widget.searchHintKey,
                                  ),
                                  SizedBox(height: context.vX2s),
                                ],
                                Expanded(
                                  child: _filtered.isEmpty
                                      ? Center(
                                          child: TextFielder(
                                            text: SetupText.getString(
                                              widget.currentLang,
                                              widget.noResultsKey,
                                            ),
                                            template: TextTemplate.title,
                                            textAlign: TextAlign.center,
                                            customStyle: TextStyle(
                                              color: theme
                                                  .colorScheme.onPrimary
                                                  .withValues(alpha: 0.85),
                                              fontSize:
                                                  context.baseScale * 1.35,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : PageView.builder(
                                          controller: _pageCtrl,
                                          itemCount: pages.length,
                                          onPageChanged: (i) =>
                                              setState(() => _page = i),
                                          itemBuilder: (context, index) {
                                            return _TagsGrid(
                                              items: pages[index],
                                              currentLang:
                                                  widget.currentLang,
                                              selected:
                                                  widget.selectedIds,
                                              onToggle: _toggle,
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.vS),
                  if (pages.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(pages.length, (i) {
                        final on = i == _page;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: context.hX4s),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _pageCtrl.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: on ? context.s : context.x2s,
                              height: context.x2s,
                              decoration: BoxDecoration(
                                color: on
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.25),
                                borderRadius:
                                    BorderRadius.circular(context.x2s),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TagsGrid extends StatelessWidget {
  final List<PageViewerItem> items;
  final String currentLang;
  final List<int> selected;
  final ValueChanged<int> onToggle;

  const _TagsGrid({
    required this.items,
    required this.currentLang,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;
        final double h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }

        final int n = items.length;
        if (n == 0) return const SizedBox.shrink();

        final double gap = context.hX3s;
        int cols = 2;
        if (w > 340) cols = 3;
        if (w > 420) cols = 4;
        cols = math.min(cols, n);
        int rows = (n / cols).ceil();
        while (rows < 3 && cols > 2 && n > 2) {
          cols--;
          rows = (n / cols).ceil();
        }

        final double cellW = (w - gap * (cols - 1)) / cols;
        final double cellH = (h - gap * (rows - 1)) / rows;

        return SizedBox(
          width: w,
          height: h,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: cellW,
                  height: cellH.clamp(36.0, 120.0),
                  child: _TagChip(
                    icon: item.icon,
                    label: SetupText.getString(currentLang, item.titleKey),
                    selected: selected.contains(item.id),
                    onTap: () => onToggle(item.id),
                    maxWidth: cellW,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double maxWidth;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double radius = context.x2s;

    final Color bg = selected
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.95)
        : theme.colorScheme.onPrimary.withValues(alpha: 0.20);
    final Color fg =
        selected ? theme.colorScheme.primary : theme.colorScheme.onPrimary;
    final Color borderColor = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimary.withValues(alpha: 0.40);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: maxWidth,
          height: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: context.hX2s,
            vertical: context.vX2s,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: context.baseScale * 0.07,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Iconer(
                icon: icon,
                template: IconTemplate.small,
                customColor: fg,
                useGradient: false,
              ),
              SizedBox(width: context.hX3s),
              Flexible(
                child: TextFielder(
                  text: label,
                  template: TextTemplate.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  customStyle: TextStyle(
                    fontSize: context.m * 0.95,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: fg,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
