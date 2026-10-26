import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Short names for the things every screen needs: `context.colors`, `context.text`, `context.l10n`.
extension AppContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// True when the phone is set to reduce motion. Every animation checks this.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  /// An animation length that becomes instant when motion is reduced.
  Duration motion([int milliseconds = 200]) =>
      reduceMotion ? Duration.zero : Duration(milliseconds: milliseconds);
}
