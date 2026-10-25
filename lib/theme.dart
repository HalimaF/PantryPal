import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Kitchen-paper palette, per spec.md > Look and Feel.
const cream = Color(0xFFFBF5EA);
const creamDeep = Color(0xFFF3E9D6);
const terracotta = Color(0xFFC4501B); // white text on it passes 4.5:1
const terracottaSoft = Color(0xFFF8E1D3);
const leafGreen = Color(0xFF2F6B3F);
const inkBrown = Color(0xFF2B2118);
const mutedBrown = Color(0xFF6B5A4A);
const lineTan = Color(0xFFE6D8C0);

/// [useWebFonts] is false in tests, which have no network to fetch fonts from.
ThemeData buildTheme({bool useWebFonts = true}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: terracotta,
    primary: terracotta,
    onPrimary: Colors.white,
    secondary: leafGreen,
    surface: cream,
    onSurface: inkBrown,
    error: const Color(0xFFB3261E),
  );

  var text = ThemeData.light().textTheme.apply(bodyColor: inkBrown, displayColor: inkBrown);
  if (useWebFonts) {
    // Fraunces (warm serif) for headings, Nunito (rounded sans) for everything else.
    final body = GoogleFonts.nunitoTextTheme(text);
    TextStyle head(TextStyle? base, double size) =>
        GoogleFonts.fraunces(textStyle: base, fontSize: size, fontWeight: FontWeight.w700, height: 1.15);
    text = body.copyWith(
      headlineLarge: head(body.headlineLarge, 36),
      headlineMedium: head(body.headlineMedium, 30),
      headlineSmall: head(body.headlineSmall, 24),
      titleLarge: head(body.titleLarge, 21),
    );
  }

  TextStyle button(double size) => useWebFonts
      ? GoogleFonts.nunito(fontSize: size, fontWeight: FontWeight.w800)
      : TextStyle(fontSize: size, fontWeight: FontWeight.w800);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: inkBrown,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: mutedBrown),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lineTan),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lineTan),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: terracotta, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        textStyle: button(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        textStyle: button(16),
        backgroundColor: creamDeep,
        foregroundColor: mutedBrown,
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: terracotta,
        side: BorderSide.none,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: inkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
