import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Pantry Pal'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone. It will sync when you are online.'**
  String get syncPending;

  /// No description provided for @syncPendingShort.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get syncPendingShort;

  /// No description provided for @lessOf.
  ///
  /// In en, this message translates to:
  /// **'Less {name}'**
  String lessOf(String name);

  /// No description provided for @moreOf.
  ///
  /// In en, this message translates to:
  /// **'More {name}'**
  String moreOf(String name);

  /// No description provided for @amountOf.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}'**
  String amountOf(String name, String amount);

  /// No description provided for @typeExactAmount.
  ///
  /// In en, this message translates to:
  /// **'Tap to type an exact amount'**
  String get typeExactAmount;

  /// No description provided for @howMuchOf.
  ///
  /// In en, this message translates to:
  /// **'How much {name}?'**
  String howMuchOf(String name);

  /// No description provided for @amountNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Please type a number above 0.'**
  String get amountNeedsNumber;

  /// No description provided for @amountTooMuch.
  ///
  /// In en, this message translates to:
  /// **'That is more than you have ({max}).'**
  String amountTooMuch(String max);

  /// No description provided for @haveIt.
  ///
  /// In en, this message translates to:
  /// **'Have'**
  String get haveIt;

  /// No description provided for @missingIt.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missingIt;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get tabGroceries;

  /// No description provided for @tabCook.
  ///
  /// In en, this message translates to:
  /// **'Cook'**
  String get tabCook;

  /// No description provided for @tabFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tabFamily;

  /// No description provided for @homeMenuToday.
  ///
  /// In en, this message translates to:
  /// **'What\'s on the menu today?'**
  String get homeMenuToday;

  /// No description provided for @homeAddName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get homeAddName;

  /// No description provided for @askNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get askNameTitle;

  /// No description provided for @askNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get askNameLabel;

  /// No description provided for @askNameNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get askNameNotNow;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'What should we cook today?'**
  String get heroTitle;

  /// No description provided for @heroAltLine.
  ///
  /// In en, this message translates to:
  /// **'آج کیا پکائیں؟'**
  String get heroAltLine;

  /// No description provided for @suggestDish.
  ///
  /// In en, this message translates to:
  /// **'Suggest a dish'**
  String get suggestDish;

  /// No description provided for @kitchenStock.
  ///
  /// In en, this message translates to:
  /// **'KITCHEN STOCK'**
  String get kitchenStock;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @shoppingDay.
  ///
  /// In en, this message translates to:
  /// **'Shopping day'**
  String get shoppingDay;

  /// No description provided for @shoppingCycleProgress.
  ///
  /// In en, this message translates to:
  /// **'Shopping cycle progress'**
  String get shoppingCycleProgress;

  /// No description provided for @percentValue.
  ///
  /// In en, this message translates to:
  /// **'{n} percent'**
  String percentValue(int n);

  /// No description provided for @nothingLow.
  ///
  /// In en, this message translates to:
  /// **'Nothing running low'**
  String get nothingLow;

  /// No description provided for @lowLeft.
  ///
  /// In en, this message translates to:
  /// **'{name}, {amount} left'**
  String lowLeft(String name, String amount);

  /// No description provided for @cookedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Cooked this week'**
  String get cookedThisWeek;

  /// No description provided for @dailyLog.
  ///
  /// In en, this message translates to:
  /// **'Daily log'**
  String get dailyLog;

  /// No description provided for @nothingCookedWeek.
  ///
  /// In en, this message translates to:
  /// **'Nothing cooked yet this week. Tap to log a dish.'**
  String get nothingCookedWeek;

  /// No description provided for @noGroceriesYet.
  ///
  /// In en, this message translates to:
  /// **'No groceries yet'**
  String get noGroceriesYet;

  /// No description provided for @noGroceriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add this month\'s shopping and I will keep track of what is left and how many days until your next trip.'**
  String get noGroceriesBody;

  /// No description provided for @addGroceries.
  ///
  /// In en, this message translates to:
  /// **'Add groceries'**
  String get addGroceries;

  /// No description provided for @couldNotLoadGroceries.
  ///
  /// In en, this message translates to:
  /// **'Could not load your groceries. Please check your internet.'**
  String get couldNotLoadGroceries;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @daysSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set your next shopping date when you add groceries.'**
  String get daysSetDate;

  /// No description provided for @daysPassed.
  ///
  /// In en, this message translates to:
  /// **'Your shopping day ({date}) has passed. Add your new groceries.'**
  String daysPassed(String date);

  /// No description provided for @daysToday.
  ///
  /// In en, this message translates to:
  /// **'Shopping day is today ({date}).'**
  String daysToday(String date);

  /// No description provided for @daysUntil.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day until your next shopping ({date}).} other{{n} days until your next shopping ({date}).}}'**
  String daysUntil(int n, String date);

  /// No description provided for @cookTitle.
  ///
  /// In en, this message translates to:
  /// **'What to cook'**
  String get cookTitle;

  /// No description provided for @cookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Best match first, using what is in your kitchen'**
  String get cookSubtitle;

  /// No description provided for @filterMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get filterMeal;

  /// No description provided for @filterWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get filterWeight;

  /// No description provided for @filterWith.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get filterWith;

  /// No description provided for @optLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get optLunch;

  /// No description provided for @optDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get optDinner;

  /// No description provided for @optLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get optLight;

  /// No description provided for @optMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get optMedium;

  /// No description provided for @optHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get optHeavy;

  /// No description provided for @optRice.
  ///
  /// In en, this message translates to:
  /// **'Rice'**
  String get optRice;

  /// No description provided for @optRoti.
  ///
  /// In en, this message translates to:
  /// **'Roti'**
  String get optRoti;

  /// No description provided for @optBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get optBread;

  /// No description provided for @optAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get optAny;

  /// No description provided for @hiddenRecent.
  ///
  /// In en, this message translates to:
  /// **'Dishes cooked in the last 7 days are hidden.'**
  String get hiddenRecent;

  /// No description provided for @whatHaveHome.
  ///
  /// In en, this message translates to:
  /// **'What do you have at home?'**
  String get whatHaveHome;

  /// No description provided for @hintIngredients.
  ///
  /// In en, this message translates to:
  /// **'For example: chicken, onion, rice, yogurt'**
  String get hintIngredients;

  /// No description provided for @helperCommas.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get helperCommas;

  /// No description provided for @showDishes.
  ///
  /// In en, this message translates to:
  /// **'Show me dishes'**
  String get showDishes;

  /// No description provided for @typeSomething.
  ///
  /// In en, this message translates to:
  /// **'Please type a few things you have at home.'**
  String get typeSomething;

  /// No description provided for @showDifferent.
  ///
  /// In en, this message translates to:
  /// **'Show different dishes'**
  String get showDifferent;

  /// No description provided for @youHaveAll.
  ///
  /// In en, this message translates to:
  /// **'You have all {n}'**
  String youHaveAll(int n);

  /// No description provided for @youHaveOf.
  ///
  /// In en, this message translates to:
  /// **'You have {have} of {total}'**
  String youHaveOf(int have, int total);

  /// No description provided for @missingNames.
  ///
  /// In en, this message translates to:
  /// **'Missing: {names}'**
  String missingNames(String names);

  /// No description provided for @recipeBook.
  ///
  /// In en, this message translates to:
  /// **'Recipe book'**
  String get recipeBook;

  /// No description provided for @aiSuggestion.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion'**
  String get aiSuggestion;

  /// No description provided for @bestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get bestMatch;

  /// No description provided for @btnRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get btnRecipe;

  /// No description provided for @btnCookThis.
  ///
  /// In en, this message translates to:
  /// **'Cook this'**
  String get btnCookThis;

  /// No description provided for @addSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This month\'s shopping, by photo or by typing'**
  String get addSubtitle;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @typeItIn.
  ///
  /// In en, this message translates to:
  /// **'Type it in'**
  String get typeItIn;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get choosePhoto;

  /// No description provided for @readingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Reading your photo…'**
  String get readingPhoto;

  /// No description provided for @foundItems.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{We found 1 item in your photo.} other{We found {n} items in your photo.}}'**
  String foundItems(int n);

  /// No description provided for @needCheck.
  ///
  /// In en, this message translates to:
  /// **'{c, plural, =1{1 needs a check.} other{{c} need a check.}}'**
  String needCheck(int c);

  /// No description provided for @cannotReadPhoto.
  ///
  /// In en, this message translates to:
  /// **'I could not read that photo. Please type what it is.'**
  String get cannotReadPhoto;

  /// No description provided for @cannotTell.
  ///
  /// In en, this message translates to:
  /// **'I could not tell what this is. Please type it.'**
  String get cannotTell;

  /// No description provided for @cannotOpenPhotos.
  ///
  /// In en, this message translates to:
  /// **'Could not open the photos. Please type what you bought.'**
  String get cannotOpenPhotos;

  /// No description provided for @amountUnclear.
  ///
  /// In en, this message translates to:
  /// **'Amount unclear. Tap to fix.'**
  String get amountUnclear;

  /// No description provided for @pleaseSayHowMuch.
  ///
  /// In en, this message translates to:
  /// **'Please say how much {name}, or remove it.'**
  String pleaseSayHowMuch(String name);

  /// No description provided for @oftenBought.
  ///
  /// In en, this message translates to:
  /// **'OFTEN BOUGHT'**
  String get oftenBought;

  /// No description provided for @saveOneItem.
  ///
  /// In en, this message translates to:
  /// **'Save 1 item'**
  String get saveOneItem;

  /// No description provided for @saveAllItems.
  ///
  /// In en, this message translates to:
  /// **'Save all {n} items'**
  String saveAllItems(int n);

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone. It will sync when you are online.'**
  String get savedOffline;

  /// No description provided for @addedOne.
  ///
  /// In en, this message translates to:
  /// **'Added {name}, {amount} {unit}.'**
  String addedOne(String name, String amount, String unit);

  /// No description provided for @addedMany.
  ///
  /// In en, this message translates to:
  /// **'Added {n} items.'**
  String addedMany(int n);

  /// No description provided for @alreadyThere.
  ///
  /// In en, this message translates to:
  /// **'{name} was already in your kitchen, so now you have {total} {unit}.'**
  String alreadyThere(String name, String total, String unit);

  /// No description provided for @addedManyRaised.
  ///
  /// In en, this message translates to:
  /// **'Added {n} items. {names}: already in your kitchen, so the amount went up.'**
  String addedManyRaised(int n, String names);

  /// No description provided for @shoppingDays.
  ///
  /// In en, this message translates to:
  /// **'Shopping days'**
  String get shoppingDays;

  /// No description provided for @iShoppedOn.
  ///
  /// In en, this message translates to:
  /// **'I shopped on'**
  String get iShoppedOn;

  /// No description provided for @nextShopping.
  ///
  /// In en, this message translates to:
  /// **'Next shopping'**
  String get nextShopping;

  /// No description provided for @nextAfterShopped.
  ///
  /// In en, this message translates to:
  /// **'The next shopping day must come after the day you shopped.'**
  String get nextAfterShopped;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please check your internet and try again.'**
  String get couldNotSave;

  /// No description provided for @inKitchenNow.
  ///
  /// In en, this message translates to:
  /// **'In your kitchen now'**
  String get inKitchenNow;

  /// No description provided for @nothingAddedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing added yet.'**
  String get nothingAddedYet;

  /// No description provided for @removeNamedQ.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeNamedQ(String name);

  /// No description provided for @removeNamedTip.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String removeNamedTip(String name);

  /// No description provided for @removeBody.
  ///
  /// In en, this message translates to:
  /// **'It will disappear from your groceries.'**
  String get removeBody;

  /// No description provided for @sheetTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Type an item'**
  String get sheetTypeTitle;

  /// No description provided for @sheetFixTitle.
  ///
  /// In en, this message translates to:
  /// **'Fix this item'**
  String get sheetFixTitle;

  /// No description provided for @fieldItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get fieldItem;

  /// No description provided for @fieldItemHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Chicken'**
  String get fieldItemHint;

  /// No description provided for @fieldHowMuch.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get fieldHowMuch;

  /// No description provided for @fieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get fieldUnit;

  /// No description provided for @pleaseTypeWhat.
  ///
  /// In en, this message translates to:
  /// **'Please type what you bought, for example chicken.'**
  String get pleaseTypeWhat;

  /// No description provided for @pleaseTypeHowMuch.
  ///
  /// In en, this message translates to:
  /// **'Please type how much, for example 1.5.'**
  String get pleaseTypeHowMuch;

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addToList;

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get unitPieces;

  /// No description provided for @unitPacks.
  ///
  /// In en, this message translates to:
  /// **'packs'**
  String get unitPacks;

  /// No description provided for @nameOnion.
  ///
  /// In en, this message translates to:
  /// **'Onion'**
  String get nameOnion;

  /// No description provided for @nameAtta.
  ///
  /// In en, this message translates to:
  /// **'Atta'**
  String get nameAtta;

  /// No description provided for @nameMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get nameMilk;

  /// No description provided for @nameEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get nameEggs;

  /// No description provided for @familyTitle.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get familyTitle;

  /// No description provided for @whoEats.
  ///
  /// In en, this message translates to:
  /// **'Who eats at home'**
  String get whoEats;

  /// No description provided for @adults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get adults;

  /// No description provided for @childrenUnder12.
  ///
  /// In en, this message translates to:
  /// **'Children under 12'**
  String get childrenUnder12;

  /// No description provided for @spiceLevel.
  ///
  /// In en, this message translates to:
  /// **'Spice level'**
  String get spiceLevel;

  /// No description provided for @spiceMild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get spiceMild;

  /// No description provided for @spiceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get spiceMedium;

  /// No description provided for @spiceHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get spiceHot;

  /// No description provided for @spiceHelpMild.
  ///
  /// In en, this message translates to:
  /// **'Mild skips hot dishes and favours gentle ones.'**
  String get spiceHelpMild;

  /// No description provided for @spiceHelpMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium shows most dishes and skips very hot ones.'**
  String get spiceHelpMedium;

  /// No description provided for @spiceHelpHot.
  ///
  /// In en, this message translates to:
  /// **'Hot shows everything, including the spiciest dishes.'**
  String get spiceHelpHot;

  /// No description provided for @favCuisines.
  ///
  /// In en, this message translates to:
  /// **'Favourite cuisines'**
  String get favCuisines;

  /// No description provided for @cuisinePakistani.
  ///
  /// In en, this message translates to:
  /// **'Pakistani'**
  String get cuisinePakistani;

  /// No description provided for @cuisineChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get cuisineChinese;

  /// No description provided for @cuisineArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get cuisineArabic;

  /// No description provided for @cuisineItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get cuisineItalian;

  /// No description provided for @cuisineBbq.
  ///
  /// In en, this message translates to:
  /// **'BBQ'**
  String get cuisineBbq;

  /// No description provided for @anythingKnow.
  ///
  /// In en, this message translates to:
  /// **'Anything we should know?'**
  String get anythingKnow;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'For example: no mushrooms, less fried food'**
  String get notesHint;

  /// No description provided for @privacyCard.
  ///
  /// In en, this message translates to:
  /// **'The AI only sees family size, spice level and favourite cuisines. It never gets names, exact ages or your email.'**
  String get privacyCard;

  /// No description provided for @savedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get savedJustNow;

  /// No description provided for @savedOnPhone.
  ///
  /// In en, this message translates to:
  /// **'Saved on your phone'**
  String get savedOnPhone;

  /// No description provided for @couldNotSaveTry.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again'**
  String get couldNotSaveTry;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Decide dinner in a minute, from what is already in your kitchen.'**
  String get authTagline;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get labelName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Ayesha'**
  String get nameHint;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'name@gmail.com'**
  String get emailHint;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHelper;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @createMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get createMyAccount;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account…'**
  String get creatingAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get haveAccount;

  /// No description provided for @privateNote.
  ///
  /// In en, this message translates to:
  /// **'Your groceries and family details stay private to your account.'**
  String get privateNote;

  /// No description provided for @errName.
  ///
  /// In en, this message translates to:
  /// **'Please tell us your name.'**
  String get errName;

  /// No description provided for @errEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get errEmailPassword;

  /// No description provided for @errEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Add the full address, like name@gmail.com'**
  String get errEmailFormat;

  /// No description provided for @errTypeEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Type your email above first, then tap Forgot password.'**
  String get errTypeEmailFirst;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Open it to choose a new password.'**
  String resetSent(String email);

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get authInvalidEmail;

  /// No description provided for @authWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password. Please try again.'**
  String get authWrong;

  /// No description provided for @authInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Try signing in.'**
  String get authInUse;

  /// No description provided for @authWeak.
  ///
  /// In en, this message translates to:
  /// **'Please choose a password with at least 6 characters.'**
  String get authWeak;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check and try again.'**
  String get authNetwork;

  /// No description provided for @authNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email sign-up is not switched on in Firebase yet.'**
  String get authNotEnabled;

  /// No description provided for @authGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}). Please try again.'**
  String authGeneric(String code);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your groceries and family details are private to your account. The AI only sees family size, spice level and favourite cuisines. It never gets names, exact ages or your email.'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutTag.
  ///
  /// In en, this message translates to:
  /// **'Dish ideas from what is at home'**
  String get aboutTag;

  /// No description provided for @aboutNote.
  ///
  /// In en, this message translates to:
  /// **'Amounts are approximate. Dish ideas are suggestions, not guarantees.'**
  String get aboutNote;

  /// No description provided for @amountsDishes.
  ///
  /// In en, this message translates to:
  /// **'Amounts and dishes'**
  String get amountsDishes;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutQ.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQ;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your groceries and family details stay saved. Log in again any time.'**
  String get logOutBody;

  /// No description provided for @nameSaved.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get nameSaved;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUrdu.
  ///
  /// In en, this message translates to:
  /// **'اردو'**
  String get languageUrdu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
