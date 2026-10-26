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
      'recap_title': 'گزارش دیروز',
      'recap_steps': 'قدم',
      'recap_cal': 'کالری تقریبی',
      'recap_active': 'دقیقه حرکت',
      'recap_goal': 'از هدف قدم',
      'recap_ok': 'عالی، بزن بریم',
      'recap_empty': 'دیروز قدمی ثبت نشد — امروز فرصتته!',
      'widget_add': 'اضافه کردن ویجت',
      'widget_add_short': 'افزودن',
      'widget_promo_msg':
          'ویجت صفحهٔ اصلی را اضافه کنید تا سلامت‌تان همیشه نزدیک باشد',
      'widget_pin_ok': 'ویجت را روی صفحهٔ اصلی تأیید کنید',
      'widget_pin_manual':
          'افزودن خودکار ممکن نشد. از منوی ویجت‌های گوشی، Helsa را اضافه کنید',
      'widget_pin_error':
          'افزودن ویجت انجام نشد. لطفاً دوباره تلاش کنید یا دستی اضافه کنید',
      'widget_android_only': 'ویجت فقط روی اندروید فعال است',
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
      'recap_title': 'Yesterday\'s report',
      'recap_steps': 'Steps',
      'recap_cal': 'Approx. calories',
      'recap_active': 'Active minutes',
      'recap_goal': 'of steps goal',
      'recap_ok': 'Let\'s go',
      'recap_empty': 'No steps yesterday — today is a fresh start!',
      'widget_add': 'Add widget',
      'widget_add_short': 'Add',
      'widget_promo_msg':
          'Add the home screen widget to keep your health close at all times',
      'widget_pin_ok': 'Confirm the widget on your home screen',
      'widget_pin_manual':
          'Auto-add failed. Add Helsa from your phone widget menu',
      'widget_pin_error':
          'Could not add the widget. Try again or add it manually',
      'widget_android_only': 'Widget is only available on Android',
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
      'recap_title': 'Rapport d\'hier',
      'recap_steps': 'Pas',
      'recap_cal': 'Calories approx.',
      'recap_active': 'Minutes actives',
      'recap_goal': 'de l\'objectif',
      'recap_ok': 'C\'est parti',
      'recap_empty': 'Pas de pas hier — nouvelle chance aujourd\'hui !',
      'widget_add': 'Ajouter le widget',
      'widget_add_short': 'Ajouter',
      'widget_promo_msg':
          'Ajoutez le widget d\'accueil pour garder votre santé toujours à portée',
      'widget_pin_ok': 'Confirmez le widget sur l\'écran d\'accueil',
      'widget_pin_manual':
          'Ajout auto impossible. Ajoutez Helsa depuis le menu widgets',
      'widget_pin_error':
          'Impossible d\'ajouter le widget. Réessayez ou ajoutez-le manuellement',
      'widget_android_only': 'Widget disponible uniquement sur Android',
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
