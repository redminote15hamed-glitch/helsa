// lib/home/menu/menu_support_sheet.dart
// Support sheet like startup — Genie open + Genie close back into menu edge.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';
import 'package:helsa/startup/setup/widget/setup_text.dart';

class MenuSupportSheet {
  MenuSupportSheet._();

  static const String supportEmail = 'redmi.note.15.hamed@gmail.com';

  static String _lang(String language) {
    final c = language.toLowerCase();
    if (c.startsWith('fa') || c.startsWith('per')) return 'fa';
    if (c.startsWith('fr')) return 'fr';
    return 'en';
  }

  static Future<void> show(BuildContext context, {required String language}) {
    final lang = _lang(language);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final edge = GenieEdge.start;

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false, // we handle dismiss with Genie exit
      barrierLabel: 'support',
      barrierColor: Colors.black38,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _SupportHost(
          language: lang,
          theme: theme,
          media: media,
          isRtl: isRtl,
          edge: edge,
        );
      },
    );
  }
}

class _SupportHost extends StatefulWidget {
  final String language;
  final ThemeData theme;
  final MediaQueryData media;
  final bool isRtl;
  final GenieEdge edge;

  const _SupportHost({
    required this.language,
    required this.theme,
    required this.media,
    required this.isRtl,
    required this.edge,
  });

  @override
  State<_SupportHost> createState() => _SupportHostState();
}

class _SupportHostState extends State<_SupportHost> {
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
    _forcePop = Timer(const Duration(milliseconds: 900), _onExitDone);
  }

  void _onExitDone() {
    _forcePop?.cancel();
    _forcePop = null;
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _forcePop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _SupportCard(
      language: widget.language,
      theme: widget.theme,
    );

    final genieChild = _closing
        ? KeyedSubtree(
            key: ValueKey('ex-$_genieKey'),
            child: card.exGenieReal(
              context,
              s: AS.balanced,
              edge: widget.edge,
              strips: 32,
              onComplete: _onExitDone,
            ),
          )
        : KeyedSubtree(
            key: ValueKey('en-$_genieKey'),
            child: card.enGenieReal(
              context,
              s: AS.slow,
              edge: widget.edge,
              strips: 32,
            ),
          );

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _requestClose,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: widget.isRtl ? Alignment.topRight : Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                top: widget.media.padding.top + context.vL,
                left: context.hM,
                right: context.hM,
              ),
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: widget.media.size.width * 0.88,
                  ),
                  child: genieChild,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final String language;
  final ThemeData theme;

  const _SupportCard({
    required this.language,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        context.hS,
        context.vS,
        context.hS,
        context.vS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(context.m * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: context.baseScale * 0.8,
            offset: Offset(0, context.baseScale * 0.12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.hX2s,
              vertical: context.vX2s,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(context.m),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: context.baseScale * 0.06,
              ),
            ),
            child: Row(
              children: [
                Iconer(
                  icon: Icons.email_rounded,
                  template: IconTemplate.small,
                  customColor: theme.colorScheme.primary,
                  useGradient: false,
                ),
                SizedBox(width: context.hX2s),
                Expanded(
                  child: TextFielder(
                    text: MenuSupportSheet.supportEmail,
                    languageCode: language,
                    template: TextTemplate.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    customStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: context.m * 0.85,
                    ),
                  ),
                ),
                SizedBox(width: context.hX3s),
                Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(context.m * 0.7),
                  child: InkWell(
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(
                          text: MenuSupportSheet.supportEmail,
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              SetupText.getString(language, 'support_copied'),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(context.m * 0.7),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.hS,
                        vertical: context.vX2s,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: context.m,
                            color: theme.colorScheme.onPrimary,
                          ),
                          SizedBox(width: context.hX3s),
                          Text(
                            SetupText.getString(language, 'support_copy'),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: context.s,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.vX2s),
          TextFielder(
            text: SetupText.getString(language, 'support_hint'),
            languageCode: language,
            template: TextTemplate.caption,
            textAlign: TextAlign.center,
            customStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontSize: context.s,
            ),
          ),
        ],
      ),
    );
  }
}
