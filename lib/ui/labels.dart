import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../logic/days_left.dart' as logic;

/// Turns the values the app stores (always English, like "Lunch" or "pieces") into words in the
/// language on screen. What is saved never changes with the language.
extension AppLabels on AppLocalizations {
  String option(String value) => switch (value) {
        'Lunch' => optLunch,
        'Dinner' => optDinner,
        'Light' => optLight,
        'Medium' => optMedium,
        'Heavy' => optHeavy,
        'Rice' => optRice,
        'Roti' => optRoti,
        'Bread' => optBread,
        'Any' => optAny,
        'Mild' => spiceMild,
        'Hot' => spiceHot,
        'Pakistani' => cuisinePakistani,
        'Chinese' => cuisineChinese,
        'Arabic' => cuisineArabic,
        'Italian' => cuisineItalian,
        'BBQ' => cuisineBbq,
        'Onion' => nameOnion,
        'Atta' => nameAtta,
        'Milk' => nameMilk,
        'Eggs' => nameEggs,
        _ => value,
      };

  String unit(String unit) => switch (unit) {
        'pieces' => unitPieces,
        'packs' => unitPacks,
        _ => unit,
      };

  String shortDate(DateTime date) => DateFormat('d MMM', localeName).format(date);

  /// The sentence at the top of the stock card, in the language on screen.
  String daysMessage(DateTime today, DateTime? next) {
    if (next == null) return daysSetDate;
    final days = logic.daysUntil(today, next);
    final date = shortDate(next);
    if (days < 0) return daysPassed(date);
    if (days == 0) return daysToday(date);
    return daysUntil(days, date);
  }

  String authError(String code) {
    switch (code) {
      case 'invalid-email':
        return authInvalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return authWrong;
      case 'email-already-in-use':
        return authInUse;
      case 'weak-password':
        return authWeak;
      case 'network-request-failed':
        return authNetwork;
      case 'operation-not-allowed':
        return authNotEnabled;
      default:
        return authGeneric(code);
    }
  }

  /// A "7 Oct" style label; separate from [shortDate] only so callers read clearly.
  String weekdayShort(DateTime date) => DateFormat.E(localeName).format(date);
  String dateLine(DateTime date) => DateFormat.MMMMEEEEd(localeName).format(date);
}
