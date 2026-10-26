import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ui/tokens.dart';

// ---------------------------------------------------------------------------------------------
// Colours. One primary (terracotta), one accent (leaf green), and meaning colours for success,
// warning and error. Every pair that carries text is checked to be at least 4.5:1 in
// test/ui/design_system_test.dart (WCAG 2.2 AA).
// ---------------------------------------------------------------------------------------------

const _terracotta = Color(0xFFC2381E);
const _leaf = Color(0xFF2F7D3A);
const _turmeric = Color(0xFFF2B01E);

/// Colours Material does not have a slot for: success and warning.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.turmeric,
    required this.onTurmeric,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// The hero button colour: bright, with dark text on it.
  final Color turmeric;
  final Color onTurmeric;

  static const light = AppColors(
    success: _leaf,
    onSuccess: Colors.white,
    successContainer: Color(0xFFDDEFDF),
    onSuccessContainer: Color(0xFF11331B),
    warning: Color(0xFF8A5A00),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFF1D1),
    onWarningContainer: Color(0xFF4A3000),
    turmeric: _turmeric,
    onTurmeric: Color(0xFF281A12),
  );

  static const dark = AppColors(
    success: Color(0xFF7FC08F),
    onSuccess: Color(0xFF0F2D18),
    successContainer: Color(0xFF1F3A27),
    onSuccessContainer: Color(0xFFCDE8D3),
    warning: Color(0xFFF2B84B),
    onWarning: Color(0xFF3A2800),
    warningContainer: Color(0xFF4A3507),
    onWarningContainer: Color(0xFFFFE2A8),
    turmeric: Color(0xFFF2B84B),
    onTurmeric: Color(0xFF281A12),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) => t < 0.5 ? this : (other as AppColors? ?? this);
}

ColorScheme _scheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: _terracotta, brightness: brightness);
  return base.copyWith(
    primary: dark ? const Color(0xFFF08A57) : _terracotta,
    onPrimary: dark ? const Color(0xFF3A1507) : Colors.white,
    primaryContainer: dark ? const Color(0xFF5A2410) : const Color(0xFFFBE5DF),
    onPrimaryContainer: dark ? const Color(0xFFFFDBCB) : const Color(0xFF5A1608),
    secondary: dark ? const Color(0xFF7FC08F) : _leaf,
    onSecondary: dark ? const Color(0xFF0F2D18) : Colors.white,
    secondaryContainer: dark ? const Color(0xFF1F3A27) : const Color(0xFFDDEFDF),
    onSecondaryContainer: dark ? const Color(0xFFCDE8D3) : const Color(0xFF11331B),
    error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
    onError: dark ? const Color(0xFF601410) : Colors.white,
    errorContainer: dark ? const Color(0xFF8C1D18) : const Color(0xFFFBE4E1),
    onErrorContainer: dark ? const Color(0xFFFFDAD6) : const Color(0xFF7A1A14),
    surface: dark ? const Color(0xFF1D1813) : const Color(0xFFFFF7EC),
    onSurface: dark ? const Color(0xFFF3E9DC) : const Color(0xFF281A12),
    onSurfaceVariant: dark ? const Color(0xFFD3C4B0) : const Color(0xFF685548),
    surfaceContainerLowest: dark ? const Color(0xFF17130F) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF241E18) : const Color(0xFFFFFFFF),
    surfaceContainer: dark ? const Color(0xFF2B241D) : const Color(0xFFFBEFDD),
    surfaceContainerHigh: dark ? const Color(0xFF342C24) : const Color(0xFFF5E8D3),
    surfaceContainerHighest: dark ? const Color(0xFF3D342B) : const Color(0xFFEDDDC4),
    outline: dark ? const Color(0xFFA08F7B) : const Color(0xFF8A7664),
    outlineVariant: dark ? const Color(0xFF4D4237) : const Color(0xFFEADBC4),
  );
}

// ---------------------------------------------------------------------------------------------
// Type. Four sizes only: title 26, card heading 19, body 16, caption 13. Body is never below 16.
// Everything scales with the phone's font setting (tested up to 200%).
// ---------------------------------------------------------------------------------------------

const double _display = 26;
const double _title = 19;
const double _body = 16;
const double _caption = 13;

TextTheme _textTheme(bool useWebFonts) {
  TextStyle serif(double size) => useWebFonts
      ? GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: FontWeight.w700, height: 1.2)
      : TextStyle(fontSize: size, fontWeight: FontWeight.w700, height: 1.2);
  TextStyle sans(double size, FontWeight weight, [double height = 1.4]) => useWebFonts
      ? GoogleFonts.figtree(fontSize: size, fontWeight: weight, height: height)
      : TextStyle(fontSize: size, fontWeight: weight, height: height);

  return TextTheme(
    displayLarge: serif(_display),
    displayMedium: serif(_display),
    displaySmall: serif(_display),
    headlineLarge: serif(_display),
    headlineMedium: serif(_display),
    headlineSmall: serif(_title),
    titleLarge: serif(_title),
    titleMedium: sans(_body, FontWeight.w800),
    titleSmall: sans(_caption, FontWeight.w800),
    bodyLarge: sans(_body, FontWeight.w400),
    bodyMedium: sans(_body, FontWeight.w400),
    bodySmall: sans(_caption, FontWeight.w400),
    labelLarge: sans(_body, FontWeight.w800, 1.2),
    labelMedium: sans(_caption, FontWeight.w700),
    labelSmall: sans(_caption, FontWeight.w700),
  );
}

ThemeData _build(Brightness brightness, {required bool useWebFonts}) {
  final scheme = _scheme(brightness);
  final text = _textTheme(useWebFonts).apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: Corner.mediumRadius,
        borderSide: BorderSide(color: color, width: width),
      );
  final buttonShape = RoundedRectangleBorder(borderRadius: Corner.mediumRadius);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    extensions: [brightness == Brightness.dark ? AppColors.dark : AppColors.light],
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded, // 48 dp touch areas
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: Lift.flat,
      scrolledUnderElevation: Lift.flat,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: Lift.flat,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Corner.mediumRadius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
      labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      errorStyle: text.bodySmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(minTouchTarget, 56),
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        textStyle: text.labelLarge,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(minTouchTarget, 56),
        padding: const EdgeInsets.symmetric(horizontal: Space.l),
        textStyle: text.labelLarge,
        shape: buttonShape,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(minTouchTarget, minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: Space.m),
        textStyle: text.labelLarge,
        shape: buttonShape,
      ),
    ),
    chipTheme: ChipThemeData(
      labelStyle: text.labelLarge,
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.m),
      shape: RoundedRectangleBorder(borderRadius: Corner.smallRadius),
      side: BorderSide(color: scheme.outline),
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.primaryContainer,
      showCheckmark: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected) ? scheme.onSurface : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 26,
          color: states.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: Corner.mediumRadius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: Corner.largeRadius),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large)),
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 8,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      thumbColor: scheme.primary,
      showValueIndicator: ShowValueIndicator.never,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 10,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
  );
}

/// [useWebFonts] is false in tests, which have no network to fetch fonts from.
ThemeData buildLightTheme({bool useWebFonts = true}) => _build(Brightness.light, useWebFonts: useWebFonts);

ThemeData buildDarkTheme({bool useWebFonts = true}) => _build(Brightness.dark, useWebFonts: useWebFonts);

/// The light theme. Kept under the old name for screens that have not been redesigned yet.
ThemeData buildTheme({bool useWebFonts = true}) => buildLightTheme(useWebFonts: useWebFonts);

// ---------------------------------------------------------------------------------------------
// Old fixed colours, used directly by screens that are still being redesigned. Each screen moves
// to Theme.of(context).colorScheme as it is redesigned, and these are deleted with the last one.
// ---------------------------------------------------------------------------------------------
const cream = Color(0xFFFFF7EC);
const creamDeep = Color(0xFFF3E9D6);
const terracotta = _terracotta;
const terracottaSoft = Color(0xFFF8E1D3);
const leafGreen = _leaf;
const inkBrown = Color(0xFF281A12);
const mutedBrown = Color(0xFF6B5A4A);
const lineTan = Color(0xFFE6D8C0);
