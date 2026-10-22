class SplashText {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'HELSA',
      'subtitle': 'healthy after all',
      'version': 'Ver 1.0',
    },
    'fa': {
      'title': 'هِلسا',
      'subtitle': 'بالاخره، سلامتی مانا',
      'version': 'نسخه ۱.۰',
    },
    'fr': {
      'title': 'HELSA',
      'subtitle': 'la santé après tout',
      'version': 'Ver 1.0',
    },
  };

  static String getString(String languageCode, String key) {
    final langMap = _localizedValues[languageCode] ?? _localizedValues['en']!;
    return langMap[key] ?? '';
  }
}
