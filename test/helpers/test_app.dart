import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:what_can_i_cook/l10n/app_localizations.dart';
import 'package:what_can_i_cook/theme.dart';

/// Wraps a widget in the app's theme and translations so it renders as it does on the phone.
Widget testApp(
  Widget child, {
  bool dark = false,
  Locale locale = const Locale('en'),
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: buildLightTheme(useWebFonts: false),
    darkTheme: buildDarkTheme(useWebFonts: false),
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: app!,
    ),
    home: Scaffold(body: child),
  );
}
