import 'package:flutter/material.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/setting/kit/textfielder.dart';

enum TextBoxTemplate { singleLine, multiLine, obscure }

class TextBoxConfig {
  final Color Function(ThemeData) focusedBorderColor;
  final Color Function(ThemeData) enabledBorderColor;
  final double Function(BuildContext) width;
  final double Function(BuildContext) borderRadius;
  final int? maxLines;
  final TextInputType keyboardType;

  const TextBoxConfig({
    required this.focusedBorderColor,
    required this.enabledBorderColor,
    required this.width,
    required this.borderRadius,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
}

class TextBoxer extends StatefulWidget {
  final String hintText;
  final TextBoxTemplate template;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  // اضافه شده
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const TextBoxer({
    super.key,
    required this.hintText,
    this.template = TextBoxTemplate.singleLine,
    this.controller,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<TextBoxer> createState() => _TextBoxerState();
}

class _TextBoxerState extends State<TextBoxer> {
  late bool _obscureText;

  late FocusNode _focusNode;
  bool _isExternalFocusNode = false;

  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();

    _obscureText = widget.template == TextBoxTemplate.obscure;

    _internalController = widget.controller ?? TextEditingController();

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _isExternalFocusNode = true;
    } else {
      _focusNode = FocusNode();
    }

    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (!_isExternalFocusNode) {
      _focusNode.dispose();
    }

    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  bool _isRTL(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  TextDirection _getDirection(String text) =>
      _isRTL(text) ? TextDirection.rtl : TextDirection.ltr;

  TextAlign _getAlignment(String text) =>
      _isRTL(text) ? TextAlign.right : TextAlign.left;

  FontConfig _extractFontSettings(
    BuildContext context,
    TextTemplate textTemplate,
  ) {
    final dummyTextFielder = TextFielder(text: '', template: textTemplate);

    final textWidget = dummyTextFielder.build(context) as Padding;

    final textChild = textWidget.child as Text;

    return FontConfig(
      fontFamily: textChild.style?.fontFamily ?? 'YekanBakh',
      fontWeight: textChild.style?.fontWeight ?? FontWeight.w400,
      fontSize: (c) => textChild.style?.fontSize ?? c.baseScale,
      color: (t) => textChild.style?.color ?? t.colorScheme.onSurface,
      bottomSpacing: (c) => 0.0,
      height: textChild.style?.height,
      letterSpacing: textChild.style?.letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final config = _getTextBoxMatrix(widget.template);

    final bodyFontSettings = _extractFontSettings(
      context,
      TextTemplate.body,
    );

    final captionFontSettings = _extractFontSettings(
      context,
      TextTemplate.caption,
    );

    final currentText = _internalController.text;

    final referenceText =
        currentText.isNotEmpty ? currentText : widget.hintText;

    final textDirection = _getDirection(referenceText);

    final textAlign = _getAlignment(referenceText);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.symmetric(vertical: context.vX3s),
      width: config.width(context),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(
          config.borderRadius(context),
        ),
      ),
      child: Directionality(
        textDirection: textDirection,
        child: TextField(
          controller: _internalController,
          focusNode: _focusNode,
          obscureText: _obscureText,
          textDirection: textDirection,
          textAlign: textAlign,
          textInputAction: widget.textInputAction,
          maxLines: widget.template == TextBoxTemplate.multiLine
              ? null
              : config.maxLines,
          keyboardType: widget.template == TextBoxTemplate.multiLine
              ? TextInputType.multiline
              : config.keyboardType,
          style: TextStyle(
            fontFamily: bodyFontSettings.fontFamily,
            fontWeight: bodyFontSettings.fontWeight,
            fontSize: bodyFontSettings.fontSize(context),
            color: bodyFontSettings.color(theme),
            height: bodyFontSettings.height,
            letterSpacing: bodyFontSettings.letterSpacing,
          ),
          onChanged: (value) {
            setState(() {});

            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          onSubmitted: (value) {
            if (widget.onSubmitted != null) {
              widget.onSubmitted!(value);
              return;
            }

            if (widget.textInputAction == TextInputAction.done) {
              _focusNode.unfocus();
            }
          },
          decoration: InputDecoration(
            labelText: widget.hintText,
            alignLabelWithHint: widget.template == TextBoxTemplate.multiLine,
            labelStyle: TextStyle(
              fontFamily: captionFontSettings.fontFamily,
              fontWeight: captionFontSettings.fontWeight,
              fontSize: captionFontSettings.fontSize(
                context,
              ),
              color: _focusNode.hasFocus
                  ? config.focusedBorderColor(
                      theme,
                    )
                  : captionFontSettings.color(
                      theme,
                    ),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.m,
              vertical: widget.template == TextBoxTemplate.multiLine
                  ? context.s
                  : context.vXs,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                config.borderRadius(
                  context,
                ),
              ),
              borderSide: BorderSide(
                color: config.enabledBorderColor(
                  theme,
                ),
                width: 0.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                config.borderRadius(
                  context,
                ),
              ),
              borderSide: BorderSide(
                color: config.focusedBorderColor(
                  theme,
                ),
                width: 1.5,
              ),
            ),
            suffixIcon: widget.template == TextBoxTemplate.obscure
                ? Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.x4s,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _focusNode.hasFocus
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                        size: bodyFontSettings.fontSize(
                              context,
                            ) *
                            1.3,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  TextBoxConfig _getTextBoxMatrix(TextBoxTemplate template) {
    switch (template) {
      case TextBoxTemplate.singleLine:
        return TextBoxConfig(
          focusedBorderColor: (t) => t.colorScheme.primary,
          enabledBorderColor: (t) => t.colorScheme.onSurface.withValues(alpha: 0.5),
          width: (c) => c.screenWidth * 0.75,
          borderRadius: (c) => c.m,
        );

      case TextBoxTemplate.multiLine:
        return TextBoxConfig(
          focusedBorderColor: (t) => t.colorScheme.primary,
          enabledBorderColor: (t) => t.colorScheme.primary.withValues(alpha: 0.5),
          width: (c) => c.screenWidth * 0.75,
          borderRadius: (c) => c.m,
          maxLines: null,
        );

      case TextBoxTemplate.obscure:
        return TextBoxConfig(
          focusedBorderColor: (t) => t.colorScheme.primary,
          enabledBorderColor: (t) => t.colorScheme.primary.withValues(alpha: 0.2),
          width: (c) => c.screenWidth * 0.75,
          borderRadius: (c) => c.m,
          keyboardType: TextInputType.visiblePassword,
        );
    }
  }
}
