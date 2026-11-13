// lib/home/menu/menu_coming_soon_page.dart
import 'package:material_ui/material_ui.dart';
import 'package:helsa/home/home_text.dart';
import 'package:helsa/home/menu/menu_expand_host.dart';

class MenuComingSoonPage extends StatelessWidget {
  final String language;
  final String titleKey;

  const MenuComingSoonPage({
    super.key,
    required this.language,
    required this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = HomeText.getString(language, titleKey);
    final body = HomeText.getString(language, 'menu_coming_soon');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => MenuExpandScope.close(context),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}
