// lib/home/home_text.dart
// Single source of truth for all Home-area user-facing strings.
class HomeText {
  HomeText._();

  static const Map<String, Map<String, String>> _values = {
    'fa': {
      'perm_activity':
          'برای فعال شدن شمارش قدم، دسترسی به فعالیت‌های بدنی را بدهید.',
      'perm_grant': 'اجازه دسترسی',
      'steps': 'قدم',
      'calories': 'کالری',
      'kcal': 'کالری',
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
      'menu_today': 'امروز',
      'menu_mood_done': 'هدف امروز کامل شد 🎉',
      'menu_mood_good': 'امروز خوب پیش می‌ری',
      'menu_mood_go': 'یه کم دیگه تا هدف',
      'menu_mood_start': 'وقت حرکت است',
      'menu_goals': 'هدف‌ها',
      'menu_widget': 'ویجت',
      'menu_support': 'پشتیبانی',
      'menu_settings': 'تنظیمات',
      'menu_profile': 'اطلاعات کاربری',
      'menu_appearance': 'تنظیمات ظاهری',
      'menu_title_male': 'آقای',
      'menu_title_female': 'بانو',
      'menu_version': 'Helsa v{v}',
      'app_name': 'Helsa',
      'night_mode': 'حالت شب',
      'streak_start': 'شروع استریک',
      'streak_days': '{n} روز پیاپی',
      'support_copy': 'کپی',
      'support_copied': 'کپی شد',
      'support_hint': 'ارسال مشکلات و پیشنهادات',
      'notif_body': 'قدم زدن برای سلامتی عالیه، حتی کم',
    },
    'en': {
      'perm_activity':
          'To enable step counting, allow access to physical activity.',
      'perm_grant': 'Allow access',
      'steps': 'Steps',
      'calories': 'Calories',
      'kcal': 'kcal',
      'active': 'Active',
      'minutes': 'min',
      'goal_steps': 'Change steps goal',
      'goal_calories': 'Change calories goal',
      'goal_active': 'Change active time goal',
      'goal_hint': 'Enter goal value',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'recap_title': "Yesterday's report",
      'recap_steps': 'Steps',
      'recap_cal': 'Approx. calories',
      'recap_active': 'Active minutes',
      'recap_goal': 'of steps goal',
      'recap_ok': "Let's go",
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
      'menu_today': 'Today',
      'menu_mood_done': "Today's goals complete 🎉",
      'menu_mood_good': "You're doing great today",
      'menu_mood_go': 'A bit more to your goal',
      'menu_mood_start': 'Time to move',
      'menu_goals': 'Goals',
      'menu_widget': 'Widget',
      'menu_support': 'Support',
      'menu_settings': 'Settings',
      'menu_profile': 'Profile',
      'menu_appearance': 'Appearance',
      'menu_title_male': 'Mr.',
      'menu_title_female': 'Ms.',
      'menu_version': 'Helsa v{v}',
      'app_name': 'Helsa',
      'night_mode': 'Night mode',
      'streak_start': 'Start a streak',
      'streak_days': '{n} day streak',
      'support_copy': 'Copy',
      'support_copied': 'Copied',
      'support_hint': 'Send issues and suggestions',
      'notif_body': 'A few steps each day keeps the doctor away',
    },
    'fr': {
      'perm_activity':
          "Pour activer le compteur de pas, autorisez l'accès à l'activité physique.",
      'perm_grant': 'Autoriser',
      'steps': 'Pas',
      'calories': 'Calories',
      'kcal': 'kcal',
      'active': 'Actif',
      'minutes': 'min',
      'goal_steps': "Modifier l'objectif de pas",
      'goal_calories': "Modifier l'objectif de calories",
      'goal_active': "Modifier l'objectif de temps actif",
      'goal_hint': "Entrez l'objectif",
      'confirm': 'Confirmer',
      'cancel': 'Annuler',
      'recap_title': "Rapport d'hier",
      'recap_steps': 'Pas',
      'recap_cal': 'Calories approx.',
      'recap_active': 'Minutes actives',
      'recap_goal': "de l'objectif",
      'recap_ok': "C'est parti",
      'recap_empty': "Pas de pas hier — nouvelle chance aujourd'hui !",
      'widget_add': 'Ajouter le widget',
      'widget_add_short': 'Ajouter',
      'widget_promo_msg':
          "Ajoutez le widget d'accueil pour garder votre santé toujours à portée",
      'widget_pin_ok': "Confirmez le widget sur l'écran d'accueil",
      'widget_pin_manual':
          'Ajout auto impossible. Ajoutez Helsa depuis le menu widgets',
      'widget_pin_error':
          "Impossible d'ajouter le widget. Réessayez ou ajoutez-le manuellement",
      'widget_android_only': 'Widget disponible uniquement sur Android',
      'menu_today': "Aujourd'hui",
      'menu_mood_done': 'Objectifs du jour atteints 🎉',
      'menu_mood_good': "Belle journée jusqu'ici",
      'menu_mood_go': "Encore un peu pour l'objectif",
      'menu_mood_start': 'Il est temps de bouger',
      'menu_goals': 'Objectifs',
      'menu_widget': 'Widget',
      'menu_support': 'Support',
      'menu_settings': 'Réglages',
      'menu_profile': 'Profil',
      'menu_appearance': 'Apparence',
      'menu_title_male': 'M.',
      'menu_title_female': 'Mme',
      'menu_version': 'Helsa v{v}',
      'app_name': 'Helsa',
      'night_mode': 'Mode nuit',
      'streak_start': 'Série à démarrer',
      'streak_days': '{n} jours de série',
      'support_copy': 'Copier',
      'support_copied': 'Copié',
      'support_hint': 'Envoyez problèmes et suggestions',
      'notif_body': 'Quelques pas chaque jour éloignent le médecin',
    },
  };

  static String _lang(String languageCode) {
    final code = languageCode.toLowerCase();
    if (code.startsWith('fa') || code.startsWith('per')) return 'fa';
    if (code.startsWith('fr')) return 'fr';
    return 'en';
  }

  static String getString(String languageCode, String key) {
    final lang = _lang(languageCode);
    return _values[lang]?[key] ?? _values['en']![key] ?? key;
  }

  /// Replace `{name}` placeholders, e.g. format(lang, 'streak_days', {'n': '5'}).
  static String format(
    String languageCode,
    String key,
    Map<String, String> vars,
  ) {
    var s = getString(languageCode, key);
    vars.forEach((k, v) {
      s = s.replaceAll('{$k}', v);
    });
    return s;
  }

  static String streakLabel(String languageCode, int n) {
    if (n <= 0) return getString(languageCode, 'streak_start');
    return format(languageCode, 'streak_days', {'n': '$n'});
  }

  static String versionLabel(String languageCode, String version) {
    return format(languageCode, 'menu_version', {'v': version});
  }
}
