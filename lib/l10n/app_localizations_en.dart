// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'What Can I Cook?';

  @override
  String get retry => 'Try again';

  @override
  String get undo => 'Undo';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading…';

  @override
  String get syncPending =>
      'Saved on this phone. It will sync when you are online.';

  @override
  String get syncPendingShort => 'Waiting to sync';

  @override
  String lessOf(String name) {
    return 'Less $name';
  }

  @override
  String moreOf(String name) {
    return 'More $name';
  }

  @override
  String amountOf(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String get typeExactAmount => 'Tap to type an exact amount';

  @override
  String howMuchOf(String name) {
    return 'How much $name?';
  }

  @override
  String get amountNeedsNumber => 'Please type a number above 0.';

  @override
  String amountTooMuch(String max) {
    return 'That is more than you have ($max).';
  }

  @override
  String get haveIt => 'Have';

  @override
  String get missingIt => 'Missing';
}
