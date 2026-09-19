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
    if (widget.selectedIndex != _currentPage) {
      _currentPage = widget.selectedIndex;
      if (_pageController.hasClients && _currentPage != null) {
        _pageController.jumpToPage(_currentPage!);
      }
    }
    if (widget.itemWidth != oldWidget.itemWidth) {
      _updateViewportFraction();
    }
  }

  void _updateViewportFraction() {
    final double newViewportFraction = _calculateViewportFraction(context);
    if (newViewportFraction != _viewportFraction) {
      _viewportFraction = newViewportFraction;
      final int currentPage = _currentPage ?? 0;
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: currentPage,
      );
    }
  }

  double _calculateViewportFraction(BuildContext context) {
    final double width = widget.itemWidth ?? context.hX5l;
    final double pagePadding = context.hX4s * 2;
    final double totalPageWidth = width + pagePadding;
    final double screenWidth = MediaQuery.of(context).size.width;
    return (totalPageWidth / screenWidth).clamp(0.3, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double width = widget.itemWidth ?? context.hX5l;
    final double height = widget.itemHeight ?? context.vX5l;

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: widget.isVertical ? Axis.vertical : Axis.horizontal,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
          widget.onSelected(index);
        },
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final isSelected = (_currentPage != null) && (index == _currentPage);
          final item = widget.items[index];

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double scale = 1.0;
              if (_pageController.position.haveDimensions) {
                scale = (1 - ((_pageController.page! - index).abs() * 0.25))
                    .clamp(0.75, 1.0);
              } else {
                // منطق اصلاح شده: در صورت نبود انتخاب، دکمه اول همیشه بزرگ است
                scale = (_currentPage == null && index == 0)
                    ? 1.0
                    : (_currentPage != null && index == _currentPage)
                        ? 1.0
                        : 0.85;
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
                onTap: () => widget.onSelected(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: context.vX2s),
                    Iconer(
                      icon: item['icon'],
                      template: IconTemplate.large,
                      customColor: isSelected
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary,
                    ),
                    if (item['desc'] != null && item['desc'].isNotEmpty) ...[
                      SizedBox(height: context.vX2s),
                      Container(
                        width: width * 0.85,
                        height: height * 0.5,
                        padding: EdgeInsets.symmetric(horizontal: context.hX2s),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(context.x2s),
                        ),
                        child: Center(
                          child: TextFielder(
                            text: item['desc'],
                            template: TextTemplate.caption,
                            maxLines: 9,
                            languageCode: widget.currentLang,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            customStyle: TextStyle(
                              fontSize:
                                  isSelected ? context.m * 0.9 : context.s,
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: context.vX2s),
                    TextFielder(
                      text: item['title'],
                      template: TextTemplate.body,
                      languageCode: widget.currentLang,
                      customStyle: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        fontWeight:
                            isSelected ? FontWeight.w900 : FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: context.vX2s),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
