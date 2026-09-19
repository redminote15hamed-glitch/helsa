class SplashText {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'title': 'HELSA',
      'subtitle': 'healthy after all',
      'version': 'Ver 0.1',
    },
    'fa': {
      'title': 'هِلسا',
      'subtitle': 'بالاخره، سلامتی مانا',
      'version': 'نسخه ۰.۱',
    },
    'fr': {
      'title': 'HELSA',
      'subtitle': 'la santé après tout',
      'version': 'Ver 0.1',
    },
  };

  static String getString(String languageCode, String key) {
    final langMap = _localizedValues[languageCode] ?? _localizedValues['en']!;
    return langMap[key] ?? '';
  }
}
