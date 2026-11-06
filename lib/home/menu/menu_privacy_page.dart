// lib/home/menu/menu_privacy_page.dart
// Privacy shell — policy body + open delete sheet.
import 'package:flutter/material.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';
import 'package:helsa/home/menu/privacy_delete_sheet.dart';
import 'package:helsa/home/menu/privacy_policy_body.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

/// Privacy & data control — opened via [MenuExpandHost].
class MenuPrivacyPage extends StatelessWidget {
  const MenuPrivacyPage({super.key, this.language});

  final String? language;

  String get _lang => language ?? 'en';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: cs.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.hS,
                vertical: context.vX2s,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => MenuExpandScope.close(context),
                    icon: Icon(
                      isRtl
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      color: cs.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      HomeText.getString(_lang, 'menu_privacy'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.m,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(width: context.xl),
                ],
              ),
            ),
            Expanded(child: PrivacyPolicyBody(language: _lang)),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.hM, context.vX2s, context.hM, bottom + context.vS,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showPrivacyDeleteSheet(context, language: _lang),
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    padding: EdgeInsets.symmetric(vertical: context.vS),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.45),
                      ),
                      color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFE11D48), size: 20),
                        SizedBox(width: context.hXs),
                        Text(
                          HomeText.getString(_lang, 'privacy_delete_data'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: context.m,
                            color: const Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
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
