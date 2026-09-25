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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double width = widget.itemWidth ?? context.hX5l;
    final double wantedHeight = widget.itemHeight ?? context.vX5l;

    // ارتفاع را با فضای والد محدود می‌کنیم تا در شناور overflow نشود
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : wantedHeight;
        final double height =
            wantedHeight > maxH && maxH > 0 ? maxH : wantedHeight;

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

                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: context.vX3s),
                          Iconer(
                            icon: item['icon'],
                            template: IconTemplate.large,
                            customColor: isSelected
                                ? theme.colorScheme.surface
                                : theme.colorScheme.primary,
                          ),
                          if (item['desc'] != null &&
                              item['desc'].toString().isNotEmpty) ...[
                            SizedBox(height: context.vX3s),
                            Flexible(
                              child: Container(
                                width: width * 0.85,
                                constraints: BoxConstraints(
                                  maxHeight: height * 0.48,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.hX2s,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface
                                      .withValues(alpha: 0.7),
                                  borderRadius:
                                      BorderRadius.circular(context.x2s),
                                ),
                                child: Center(
                                  child: TextFielder(
                                    text: item['desc'],
                                    template: TextTemplate.caption,
                                    maxLines: 6,
                                    languageCode: widget.currentLang,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    customStyle: TextStyle(
                                      fontSize: isSelected
                                          ? context.m * 0.85
                                          : context.s,
                                      color: isSelected
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.primary
                                              .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: context.vX3s),
                          TextFielder(
                            text: item['title'],
                            template: TextTemplate.body,
                            languageCode: widget.currentLang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            customStyle: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: context.vX3s),
                        ],
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
