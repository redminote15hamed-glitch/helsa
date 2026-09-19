import 'package:flutter/material.dart';

const Map<String, String> _englishToPersianDigits = {
  '0': '۰',
  '1': '۱',
  '2': '۲',
  '3': '۳',
  '4': '۴',
  '5': '۵',
  '6': '۶',
  '7': '۷',
  '8': '۸',
  '9': '۹',
};

String _convertDigitsToPersian(String value) {
  return value.replaceAllMapped(RegExp(r'[0-9]'), (match) {
    return _englishToPersianDigits[match.group(0)] ?? match.group(0)!;
  });
}

extension FarsiDigitExtension on String {
  String toLocalizedDigits(BuildContext context, {String? languageCode}) {
    final code = languageCode ?? Localizations.localeOf(context).languageCode;
    if (code.toLowerCase() != 'fa') return this;
    return _convertDigitsToPersian(this);
  }
}
