// lib/home/menu/privacy_policy_body.dart
import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/setting/responsive/responsive_utils.dart';

class PrivacyPolicyBody extends StatelessWidget {
  const PrivacyPolicyBody({super.key, required this.language});

  final String language;

  String get _lang => language;

  bool get _rtl => _lang == 'fa' || _lang == 'ar';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dir = _rtl ? TextDirection.rtl : TextDirection.ltr;

    Widget point(IconData icon, String key) {
      return Padding(
        padding: EdgeInsets.only(bottom: context.vX2s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: dir,
          children: [
            Icon(icon, size: 20, color: cs.primary),
            SizedBox(width: context.hXs),
            Expanded(
              child: Text(
                HomeText.getString(_lang, key),
                textDirection: dir,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: context.s,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: dir,
      child: ListView(
        padding:
            EdgeInsets.fromLTRB(context.hM, context.vS, context.hM, context.vM),
        children: [
          Container(
            padding: EdgeInsets.all(context.s),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.28)),
            ),
            child: Row(
              textDirection: dir,
              children: [
                Icon(Icons.phone_android_rounded, color: cs.primary),
                SizedBox(width: context.hXs),
                Expanded(
                  child: Text(
                    HomeText.getString(_lang, 'privacy_on_device_badge'),
                    textDirection: dir,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: context.s,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.vM),
          Text(
            HomeText.getString(_lang, 'privacy_policy_title'),
            textDirection: dir,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: context.l,
              color: cs.onSurface,
            ),
          ),
          SizedBox(height: context.vX2s),
          Text(
            HomeText.getString(_lang, 'privacy_policy_body'),
            textDirection: dir,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: context.s,
              height: 1.55,
              color: cs.onSurface.withValues(alpha: 0.82),
            ),
          ),
          SizedBox(height: context.vM),
          point(Icons.lock_rounded, 'privacy_point_encrypt'),
          point(Icons.cloud_off_rounded, 'privacy_point_no_cloud'),
          point(Icons.tune_rounded, 'privacy_point_control'),
          point(Icons.visibility_outlined, 'privacy_point_transparent'),
          point(Icons.smartphone_rounded, 'privacy_point_local'),
        ],
      ),
    );
  }
}
