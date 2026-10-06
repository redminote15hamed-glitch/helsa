import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';

class ListViewer extends StatefulWidget {
  final List<String> items;
  final Function(int) onSelectedItemChanged;
  final bool isVertical;
  final double diameterRatio;
  final String? languageCode;
  final int initialIndex;

  const ListViewer({
    super.key,
    required this.items,
    required this.onSelectedItemChanged,
    this.isVertical = true,
    this.diameterRatio = 0.8,
    this.languageCode,
    this.initialIndex = 0,
  });

  @override
  State<ListViewer> createState() => _ListViewerState();
}

class _ListViewerState extends State<ListViewer> {
  late int _selectedIndex;
  late FixedExtentScrollController _scrollController;

  int get _normalizedInitialIndex {
    if (widget.items.isEmpty) return 0;
    return widget.initialIndex.clamp(0, widget.items.length - 1);
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = _normalizedInitialIndex;
    _scrollController =
        FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(covariant ListViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _normalizedInitialIndex;
    if (newIndex != _selectedIndex) {
      _selectedIndex = newIndex;
      if (_scrollController.hasClients) {
        _scrollController.jumpToItem(newIndex);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Text? _findTextWidget(Widget? w, {int depth = 0}) {
    if (w == null || depth > 6) return null;
    if (w is Text) return w;
    if (w is Padding) return _findTextWidget(w.child, depth: depth + 1);
    if (w is Directionality) {
      return _findTextWidget(w.child, depth: depth + 1);
    }
    if (w is Align) return _findTextWidget(w.child, depth: depth + 1);
    if (w is Center) return _findTextWidget(w.child, depth: depth + 1);
    if (w is SizedBox) return _findTextWidget(w.child, depth: depth + 1);
    return null;
  }

  FontConfig _extractFontSettings(BuildContext context) {
    final dummyTextFielder = TextFielder(
      text: ' ',
      template: TextTemplate.body,
      languageCode: widget.languageCode,
    );
    final built = dummyTextFielder.build(context);
    final textChild = _findTextWidget(built);

    if (textChild?.style != null) {
      final s = textChild!.style!;
      return FontConfig(
        fontFamily: s.fontFamily ?? 'YekanBakh',
        fontWeight: s.fontWeight ?? FontWeight.w400,
        fontSize: (c) => s.fontSize ?? c.baseScale,
        color: (t) => s.color ?? t.colorScheme.onSurface,
        bottomSpacing: (c) => 0.0,
        height: s.height,
        letterSpacing: s.letterSpacing,
      );
    }

    return FontConfig(
      fontFamily: 'YekanBakh',
      fontWeight: FontWeight.w400,
      fontSize: (c) => c.m,
      color: (t) => t.colorScheme.onSurface,
      bottomSpacing: (c) => 0.0,
      height: 1.35,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemFontSettings = _extractFontSettings(context);
    final double itemExtent = widget.isVertical ? context.vM : context.vL;
    final double wheelSize = widget.isVertical ? itemExtent * 5 : itemExtent;

    Widget wheel = ListWheelScrollView.useDelegate(
      controller: _scrollController,
      itemExtent: itemExtent,
      diameterRatio: widget.diameterRatio,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() => _selectedIndex = index);
        widget.onSelectedItemChanged(index);
      },
      useMagnifier: true,
      magnification: 1.3,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.items.length,
        builder: (context, index) {
          final isSelected = index == _selectedIndex;
          final baseSize = itemFontSettings.fontSize(context);

          Widget itemText = Text(
            widget.items[index],
            softWrap: false,
            maxLines: 1,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: itemFontSettings.fontFamily,
              fontWeight:
                  isSelected ? FontWeight.bold : itemFontSettings.fontWeight,
              fontSize: isSelected ? baseSize * 1.2 : baseSize,
              color: isSelected
                  ? theme.colorScheme.primary
                  : itemFontSettings.color(theme),
              height: itemFontSettings.height,
              letterSpacing: itemFontSettings.letterSpacing,
            ),
          );

          return Center(
            child: widget.isVertical
                ? itemText
                : RotatedBox(quarterTurns: -1, child: itemText),
          );
        },
      ),
    );

    Widget content =
        widget.isVertical ? wheel : RotatedBox(quarterTurns: 1, child: wheel);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: widget.isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: widget.isVertical
              ? Alignment.bottomCenter
              : Alignment.centerRight,
          colors: const [Colors.transparent, Colors.white, Colors.transparent],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: wheelSize,
        width: double.infinity,
        child: content,
      ),
    );
  }
}
