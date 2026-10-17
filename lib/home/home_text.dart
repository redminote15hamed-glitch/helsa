// lib/home/home_text.dart
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
      'goal_steps': 'تغییر هدف قدم',
      'goal_calories': 'تغییر هدف کالری',
      'goal_active': 'تغییر هدف زمان حرکت',
      'goal_hint': 'عدد هدف را وارد کنید',
      'confirm': 'تأیید',
      'cancel': 'انصراف',
    },
    'en': {
      'perm_activity':
          'To enable step counting, allow access to physical activity.',
      'perm_grant': 'Allow access',
      'steps': 'Steps',
      'calories': 'Calories',
      'active': 'Active',
      'minutes': 'min',
      'goal_steps': 'Change steps goal',
      'goal_calories': 'Change calories goal',
      'goal_active': 'Change active time goal',
      'goal_hint': 'Enter goal value',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
    },
    'fr': {
      'perm_activity':
          'Pour activer le compteur de pas, autorisez l\'accès à l\'activité physique.',
      'perm_grant': 'Autoriser',
      'steps': 'Pas',
      'calories': 'Calories',
      'active': 'Actif',
      'minutes': 'min',
      'goal_steps': 'Modifier l\'objectif de pas',
      'goal_calories': 'Modifier l\'objectif de calories',
      'goal_active': 'Modifier l\'objectif de temps actif',
      'goal_hint': 'Entrez l\'objectif',
      'confirm': 'Confirmer',
      'cancel': 'Annuler',
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
