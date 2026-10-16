// lib/home/home_text.dart
/// Localized strings for Home screen (separate from setup flow).
class HomeText {
  HomeText._();

  static const Map<String, Map<String, String>> _values = {
    'fa': {
      'perm_activity':
          'برای فعال شدن شمارش قدم، دسترسی به فعالیت‌های بدنی را بدهید.',
      'perm_grant': 'اجازه دسترسی',
      'steps': 'قدم',
      'calories': 'کالری',
      'active': 'زمان حرکت',
      'minutes': 'دقیقه',
    },
    'en': {
      'perm_activity':
          'To enable step counting, allow access to physical activity.',
      'perm_grant': 'Allow access',
      'steps': 'Steps',
      'calories': 'Calories',
      'active': 'Active',
      'minutes': 'min',
    },
    'fr': {
      'perm_activity':
          'Pour activer le compteur de pas, autorisez l\'accès à l\'activité physique.',
      'perm_grant': 'Autoriser',
      'steps': 'Pas',
      'calories': 'Calories',
      'active': 'Actif',
      'minutes': 'min',
    },
  };

  static String getString(String languageCode, String key) {
    final code = languageCode.toLowerCase();
    final lang = code.startsWith('fa')
        ? 'fa'
        : code.startsWith('fr')
            ? 'fr'
            : 'en';
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }
}
