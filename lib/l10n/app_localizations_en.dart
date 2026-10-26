// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Pantry Pal';

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

  @override
  String get tabHome => 'Home';

  @override
  String get tabGroceries => 'Groceries';

  @override
  String get tabCook => 'Cook';

  @override
  String get tabFamily => 'Family';

  @override
  String get homeMenuToday => 'What\'s on the menu today?';

  @override
  String get homeAddName => 'Add your name';

  @override
  String get askNameTitle => 'What should we call you?';

  @override
  String get askNameLabel => 'Your name';

  @override
  String get askNameNotNow => 'Not now';

  @override
  String get settings => 'Settings';

  @override
  String get heroTitle => 'What should we cook today?';

  @override
  String get heroAltLine => 'آج کیا پکائیں؟';

  @override
  String get suggestDish => 'Suggest a dish';

  @override
  String get kitchenStock => 'KITCHEN STOCK';

  @override
  String get seeAll => 'See all';

  @override
  String get shoppingDay => 'Shopping day';

  @override
  String get shoppingCycleProgress => 'Shopping cycle progress';

  @override
  String percentValue(int n) {
    return '$n percent';
  }

  @override
  String get nothingLow => 'Nothing running low';

  @override
  String lowLeft(String name, String amount) {
    return '$name, $amount left';
  }

  @override
  String get cookedThisWeek => 'Cooked this week';

  @override
  String get dailyLog => 'Daily log';

  @override
  String get nothingCookedWeek =>
      'Nothing cooked yet this week. Tap to log a dish.';

  @override
  String get noGroceriesYet => 'No groceries yet';

  @override
  String get noGroceriesBody =>
      'Add this month\'s shopping and I will keep track of what is left and how many days until your next trip.';

  @override
  String get addGroceries => 'Add groceries';

  @override
  String get couldNotLoadGroceries =>
      'Could not load your groceries. Please check your internet.';

  @override
  String get saved => 'Saved';

  @override
  String get saving => 'Saving…';

  @override
  String get daysSetDate =>
      'Set your next shopping date when you add groceries.';

  @override
  String daysPassed(String date) {
    return 'Your shopping day ($date) has passed. Add your new groceries.';
  }

  @override
  String daysToday(String date) {
    return 'Shopping day is today ($date).';
  }

  @override
  String daysUntil(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days until your next shopping ($date).',
      one: '1 day until your next shopping ($date).',
    );
    return '$_temp0';
  }

  @override
  String get cookTitle => 'What to cook';

  @override
  String get cookSubtitle => 'Best match first, using what is in your kitchen';

  @override
  String get filterMeal => 'Meal';

  @override
  String get filterWeight => 'Weight';

  @override
  String get filterWith => 'With';

  @override
  String get optLunch => 'Lunch';

  @override
  String get optDinner => 'Dinner';

  @override
  String get optLight => 'Light';

  @override
  String get optMedium => 'Medium';

  @override
  String get optHeavy => 'Heavy';

  @override
  String get optRice => 'Rice';

  @override
  String get optRoti => 'Roti';

  @override
  String get optBread => 'Bread';

  @override
  String get optAny => 'Any';

  @override
  String get hiddenRecent => 'Dishes cooked in the last 7 days are hidden.';

  @override
  String get whatHaveHome => 'What do you have at home?';

  @override
  String get hintIngredients => 'For example: chicken, onion, rice, yogurt';

  @override
  String get helperCommas => 'Separate with commas';

  @override
  String get showDishes => 'Show me dishes';

  @override
  String get typeSomething => 'Please type a few things you have at home.';

  @override
  String get showDifferent => 'Show different dishes';

  @override
  String youHaveAll(int n) {
    return 'You have all $n';
  }

  @override
  String youHaveOf(int have, int total) {
    return 'You have $have of $total';
  }

  @override
  String missingNames(String names) {
    return 'Missing: $names';
  }

  @override
  String get recipeBook => 'Recipe book';

  @override
  String get aiSuggestion => 'AI suggestion';

  @override
  String get bestMatch => 'Best match';

  @override
  String get btnRecipe => 'Recipe';

  @override
  String get btnCookThis => 'Cook this';

  @override
  String get addSubtitle => 'This month\'s shopping, by photo or by typing';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get typeItIn => 'Type it in';

  @override
  String get choosePhoto => 'Choose a photo';

  @override
  String get readingPhoto => 'Reading your photo…';

  @override
  String foundItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'We found $n items in your photo.',
      one: 'We found 1 item in your photo.',
    );
    return '$_temp0';
  }

  @override
  String needCheck(int c) {
    String _temp0 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '$c need a check.',
      one: '1 needs a check.',
    );
    return '$_temp0';
  }

  @override
  String get cannotReadPhoto =>
      'I could not read that photo. Please type what it is.';

  @override
  String get cannotTell => 'I could not tell what this is. Please type it.';

  @override
  String get cannotOpenPhotos =>
      'Could not open the photos. Please type what you bought.';

  @override
  String get amountUnclear => 'Amount unclear. Tap to fix.';

  @override
  String pleaseSayHowMuch(String name) {
    return 'Please say how much $name, or remove it.';
  }

  @override
  String get oftenBought => 'OFTEN BOUGHT';

  @override
  String get saveOneItem => 'Save 1 item';

  @override
  String saveAllItems(int n) {
    return 'Save all $n items';
  }

  @override
  String get savedOffline =>
      'Saved on your phone. It will sync when you are online.';

  @override
  String addedOne(String name, String amount, String unit) {
    return 'Added $name, $amount $unit.';
  }

  @override
  String addedMany(int n) {
    return 'Added $n items.';
  }

  @override
  String alreadyThere(String name, String total, String unit) {
    return '$name was already in your kitchen, so now you have $total $unit.';
  }

  @override
  String addedManyRaised(int n, String names) {
    return 'Added $n items. $names: already in your kitchen, so the amount went up.';
  }

  @override
  String get shoppingDays => 'Shopping days';

  @override
  String get iShoppedOn => 'I shopped on';

  @override
  String get nextShopping => 'Next shopping';

  @override
  String get nextAfterShopped =>
      'The next shopping day must come after the day you shopped.';

  @override
  String get couldNotSave =>
      'Could not save. Please check your internet and try again.';

  @override
  String get inKitchenNow => 'In your kitchen now';

  @override
  String get nothingAddedYet => 'Nothing added yet.';

  @override
  String removeNamedQ(String name) {
    return 'Remove $name?';
  }

  @override
  String removeNamedTip(String name) {
    return 'Remove $name';
  }

  @override
  String get removeBody => 'It will disappear from your groceries.';

  @override
  String get sheetTypeTitle => 'Type an item';

  @override
  String get sheetFixTitle => 'Fix this item';

  @override
  String get fieldItem => 'Item';

  @override
  String get fieldItemHint => 'For example: Chicken';

  @override
  String get fieldHowMuch => 'How much';

  @override
  String get fieldUnit => 'Unit';

  @override
  String get pleaseTypeWhat =>
      'Please type what you bought, for example chicken.';

  @override
  String get pleaseTypeHowMuch => 'Please type how much, for example 1.5.';

  @override
  String get addToList => 'Add to list';

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get unitPieces => 'pieces';

  @override
  String get unitPacks => 'packs';

  @override
  String get nameOnion => 'Onion';

  @override
  String get nameAtta => 'Atta';

  @override
  String get nameMilk => 'Milk';

  @override
  String get nameEggs => 'Eggs';

  @override
  String get familyTitle => 'Family';

  @override
  String get whoEats => 'Who eats at home';

  @override
  String get adults => 'Adults';

  @override
  String get childrenUnder12 => 'Children under 12';

  @override
  String get spiceLevel => 'Spice level';

  @override
  String get spiceMild => 'Mild';

  @override
  String get spiceMedium => 'Medium';

  @override
  String get spiceHot => 'Hot';

  @override
  String get spiceHelpMild => 'Mild skips hot dishes and favours gentle ones.';

  @override
  String get spiceHelpMedium =>
      'Medium shows most dishes and skips very hot ones.';

  @override
  String get spiceHelpHot =>
      'Hot shows everything, including the spiciest dishes.';

  @override
  String get favCuisines => 'Favourite cuisines';

  @override
  String get cuisinePakistani => 'Pakistani';

  @override
  String get cuisineChinese => 'Chinese';

  @override
  String get cuisineArabic => 'Arabic';

  @override
  String get cuisineItalian => 'Italian';

  @override
  String get cuisineBbq => 'BBQ';

  @override
  String get anythingKnow => 'Anything we should know?';

  @override
  String get notesHint => 'For example: no mushrooms, less fried food';

  @override
  String get privacyCard =>
      'The AI only sees family size, spice level and favourite cuisines. It never gets names, exact ages or your email.';

  @override
  String get savedJustNow => 'Saved just now';

  @override
  String get savedOnPhone => 'Saved on your phone';

  @override
  String get couldNotSaveTry => 'Could not save. Try again';

  @override
  String get authTagline =>
      'Decide dinner in a minute, from what is already in your kitchen.';

  @override
  String get labelName => 'Your name';

  @override
  String get nameHint => 'For example: Ayesha';

  @override
  String get labelEmail => 'Email';

  @override
  String get emailHint => 'name@gmail.com';

  @override
  String get labelPassword => 'Password';

  @override
  String get passwordHelper => 'At least 6 characters';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get signIn => 'Sign in';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get createAccount => 'Create an account';

  @override
  String get createMyAccount => 'Create my account';

  @override
  String get creatingAccount => 'Creating your account…';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get privateNote =>
      'Your groceries and family details stay private to your account.';

  @override
  String get errName => 'Please tell us your name.';

  @override
  String get errEmailPassword => 'Please enter your email and password.';

  @override
  String get errEmailFormat => 'Add the full address, like name@gmail.com';

  @override
  String get errTypeEmailFirst =>
      'Type your email above first, then tap Forgot password.';

  @override
  String resetSent(String email) {
    return 'We sent a link to $email. Open it to choose a new password.';
  }

  @override
  String get authInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get authWrong => 'Wrong email or password. Please try again.';

  @override
  String get authInUse => 'This email already has an account. Try signing in.';

  @override
  String get authWeak => 'Please choose a password with at least 6 characters.';

  @override
  String get authNetwork =>
      'No internet connection. Please check and try again.';

  @override
  String get authNotEnabled =>
      'Email sign-up is not switched on in Firebase yet.';

  @override
  String authGeneric(String code) {
    return 'Something went wrong ($code). Please try again.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get account => 'Account';

  @override
  String get nameLabel => 'Name';

  @override
  String get notSet => 'Not set';

  @override
  String get emailLabel => 'Email';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'Your groceries and family details are private to your account. The AI only sees family size, spice level and favourite cuisines. It never gets names, exact ages or your email.';

  @override
  String get about => 'About';

  @override
  String get aboutTag => 'Dish ideas from what is at home';

  @override
  String get aboutNote =>
      'Amounts are approximate. Dish ideas are suggestions, not guarantees.';

  @override
  String get amountsDishes => 'Amounts and dishes';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutQ => 'Log out?';

  @override
  String get logOutBody =>
      'Your groceries and family details stay saved. Log in again any time.';

  @override
  String get nameSaved => 'Name saved';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'اردو';
}
