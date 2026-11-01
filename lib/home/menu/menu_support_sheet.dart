// lib/home/menu/menu_support_sheet.dart
// Support card in FRONT (root overlay). Genie expands from bottom near Support row,
// not from behind the drawer / not a left slide.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/kit/iconer.dart';
import 'package:helsa/setting/kit/textfielder.dart';
import 'package:helsa/setting/motion/animator/animator.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

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

    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'support',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, a, b) {
        return _SupportHost(
          language: lang,
          theme: theme,
        );
      },
    );
  }
}

class _SupportHost extends StatefulWidget {
  final String language;
  final ThemeData theme;

  const _SupportHost({
    required this.language,
    required this.theme,
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
    _forcePop = Timer(const Duration(milliseconds: 1000), _onExitDone);
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
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;

    // Edge: bottom — expands upward from near Support item (lower menu),
    // not a horizontal left-slide under the drawer.
    const edge = GenieEdge.bottom;

    final card = _SupportCard(
      language: widget.language,
      theme: widget.theme,
    );

    final genieChild = KeyedSubtree(
      key: ValueKey(_closing ? 'ex-$_genieKey' : 'en-$_genieKey'),
      child: _closing
          ? card.exGenieReal(
              context,
              s: AS.balanced,
              edge: edge,
              strips: 36,
              onComplete: _onExitDone,
            )
          : card.enGenieReal(
              context,
              s: AS.slow,
              edge: edge,
              strips: 36,
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
          // Center-bottom of FULL screen → clearly in front of the menu
          Positioned(
            left: media.size.width * 0.06,
            right: media.size.width * 0.06,
            bottom: bottom + 28,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: genieChild,
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
    return Material(
      color: theme.colorScheme.surface,
      elevation: 18,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(context.m * 1.2),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.hS,
          context.vS,
          context.hS,
          context.vS,
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
                                HomeText.getString(language, 'support_copied'),
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
                              HomeText.getString(language, 'support_copy'),
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
              text: HomeText.getString(language, 'support_hint'),
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
      ),
    );
  }
}
