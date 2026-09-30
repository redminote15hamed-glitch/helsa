import 'package:flutter/material.dart';
import 'package:helsa/setting/kit/buttoner.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class ListViewButtoner extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int? selectedIndex;
  final Function(int) onSelected;
  final bool isVertical;
  final double? itemWidth;
  final double? itemHeight;
  final String currentLang;

  const ListViewButtoner({
    super.key,
    required this.items,
    this.selectedIndex,
    required this.onSelected,
    this.isVertical = false,
    this.itemWidth,
    this.itemHeight,
    required this.currentLang,
  });

  @override
  State<ListViewButtoner> createState() => _ListViewButtonerState();
}

class _ListViewButtonerState extends State<ListViewButtoner> {
  late PageController _pageController;
  late double _viewportFraction;
  int? _currentPage;
  bool _ignoreNextSelectedSync = false;

  static const _pageAnimDuration = Duration(milliseconds: 320);
  static const _pageAnimCurve = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.selectedIndex;
    _viewportFraction = 0.6;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: widget.selectedIndex ?? 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateViewportFraction();
  }

  @override
  void didUpdateWidget(covariant ListViewButtoner oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex != _currentPage) {
      if (_ignoreNextSelectedSync) {
        _ignoreNextSelectedSync = false;
      } else if (_pageController.hasClients && widget.selectedIndex != null) {
        _currentPage = widget.selectedIndex;
        _pageController.animateToPage(
          widget.selectedIndex!,
          duration: _pageAnimDuration,
          curve: _pageAnimCurve,
        );
      } else {
        _currentPage = widget.selectedIndex;
      }
    }

    if (widget.itemWidth != oldWidget.itemWidth) {
      _updateViewportFraction();
    }
  }

  void _updateViewportFraction() {
    final double newViewportFraction = _calculateViewportFraction(context);
    if ((newViewportFraction - _viewportFraction).abs() < 0.001) return;

    _viewportFraction = newViewportFraction;
    final int currentPage = _currentPage ?? 0;
    final oldController = _pageController;
    _pageController = PageController(
      viewportFraction: _viewportFraction,
      initialPage: currentPage,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      if (mounted) setState(() {});
    });
  }

  double _calculateViewportFraction(BuildContext context) {
    final double width = widget.itemWidth ?? context.hX5l;
    final double pagePadding = context.hX4s * 2;
    final double totalPageWidth = width + pagePadding;
    final double screenWidth = MediaQuery.of(context).size.width;
    return (totalPageWidth / screenWidth).clamp(0.3, 0.95);
  }

  void _onPageChanged(int index) {
    if (_currentPage == index) return;
    setState(() => _currentPage = index);
    _ignoreNextSelectedSync = true;
    widget.onSelected(index);
  }

  void _onItemTap(int index) {
    if (index == _currentPage) return;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: _pageAnimDuration,
        curve: _pageAnimCurve,
      );
    } else {
      _ignoreNextSelectedSync = true;
      setState(() => _currentPage = index);
      widget.onSelected(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// فقط روی پنجره خیلی کوچک جمع می‌شود
  double _densityScale({
    required BuildContext context,
    required double cardW,
    required double cardH,
  }) {
    final double refW = context.hX6l + context.hXl;
    final double refH = context.vX4l;
    final double sx = (cardW / refW).clamp(0.0, 1.0);
    final double sy = (cardH / refH).clamp(0.0, 1.0);
    final double raw = sx < sy ? sx : sy;
    if (raw >= 0.90) return 1.0;
    return raw.clamp(0.70, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double width = widget.itemWidth ?? context.hX5l;
    // ارتفاع جمع‌وجور نسبت به عرض — نه vX5l که روی دسکتاپ غول می‌شود
    // کارت کوتاه‌تر تا حاشیه خالی نماند
    final double wantedHeight =
        widget.itemHeight ?? (width * 0.92).clamp(context.vXl, context.vX2l);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : wantedHeight;
        double height = wantedHeight;
        if (maxH > 0 && height > maxH) height = maxH;
        final double cap = width * 0.95;
        if (height > cap) height = cap;

        final double density = _densityScale(
          context: context,
          cardW: width,
          cardH: height,
        );

        return SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection:
                widget.isVertical ? Axis.vertical : Axis.horizontal,
            onPageChanged: _onPageChanged,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final isSelected =
                  (_currentPage != null) && (index == _currentPage);
              final item = widget.items[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double scale = 0.85;
                  try {
                    if (_pageController.hasClients &&
                        _pageController.position.haveDimensions) {
                      final page = _pageController.page;
                      if (page != null) {
                        scale = (1 - ((page - index).abs() * 0.25))
                            .clamp(0.75, 1.0);
                      }
                    } else {
                      scale = (_currentPage == null && index == 0)
                          ? 1.0
                          : (index == _currentPage)
                              ? 1.0
                              : 0.85;
                    }
                  } catch (_) {
                    scale = (index == _currentPage) ? 1.0 : 0.85;
                  }

                  return Transform.scale(scale: scale, child: child);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.hX4s),
                  child: Buttoner(
                    text: "",
                    template: ButtonTemplate.squarePrimary,
                    isSelected: isSelected,
                    customWidth: width,
                    customHeight: height,
                    onTap: () => _onItemTap(index),
                    child: ClipRect(
                      child: _CardBody(
                        item: item,
                        isSelected: isSelected,
                        currentLang: widget.currentLang,
                        width: width,
                        theme: theme,
                        density: density,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// ساختار مرجع:
/// [آیکون]
/// [باکس توضیح]
/// [عنوان]
class _CardBody extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final String currentLang;
  final double width;
  final ThemeData theme;
  final double density;

  const _CardBody({
    required this.item,
    required this.isSelected,
    required this.currentLang,
    required this.width,
    required this.theme,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    final hasDesc =
        item['desc'] != null && item['desc'].toString().isNotEmpty;

    final double pad = context.s * density;
    // فونت کارت درشت‌تر روی همه دستگاه‌ها
    final double fontBoost =
        context.shortestSide >= 600 ? 2.6 : 1.85;
    final double descSize = context.s * density * fontBoost;
    final double titleSize = context.m * density * fontBoost;
    final int maxLines = density < 0.85 ? 3 : 4;

    final Color onCard = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    final Color descBoxBg = isSelected
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.18)
        : theme.colorScheme.surface.withValues(alpha: 0.85);

    final Color descTextColor = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface.withValues(alpha: 0.85);

    final double tight = context.vX5s * density; // خیلی کم

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: pad,
        vertical: pad * 0.45,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconer(
            icon: item['icon'],
            template:
                density < 0.8 ? IconTemplate.medium : IconTemplate.large,
            customColor: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          SizedBox(height: tight),
          if (hasDesc) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.hX2s * density,
                vertical: context.vX5s * density,
              ),
              decoration: BoxDecoration(
                color: descBoxBg,
                borderRadius: BorderRadius.circular(context.s),
              ),
              child: TextFielder(
                text: item['desc'],
                template: TextTemplate.caption,
                maxLines: maxLines,
                languageCode: currentLang,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                customStyle: TextStyle(
                  fontSize: descSize,
                  height: 1.25,
                  color: descTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: tight),
          ],
          TextFielder(
            text: item['title'],
            template: TextTemplate.body,
            languageCode: currentLang,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              fontSize: titleSize,
              color: onCard,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
