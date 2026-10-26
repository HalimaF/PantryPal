import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the app is showing: English or Urdu. Urdu is written right to left, and Flutter
/// flips every screen by itself when the locale is Urdu.
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('en'));

const supportedAppLocales = [Locale('en'), Locale('ur')];

/// Reads the language she chose last time. Remembering is a convenience, never a reason to fail.
Future<void> loadAppLocale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language');
    if (code == 'ur' || code == 'en') appLocale.value = Locale(code!);
  } catch (_) {}
}

Future<void> setAppLocale(Locale locale) async {
  appLocale.value = locale;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  } catch (_) {}
}
