// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'پینٹری پال';

  @override
  String get retry => 'دوبارہ کوشش کریں';

  @override
  String get undo => 'واپس کریں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get remove => 'ہٹائیں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get done => 'مکمل';

  @override
  String get skip => 'چھوڑیں';

  @override
  String get next => 'اگلا';

  @override
  String get back => 'پیچھے';

  @override
  String get edit => 'ترمیم';

  @override
  String get close => 'بند کریں';

  @override
  String get loading => 'لوڈ ہو رہا ہے…';

  @override
  String get syncPending =>
      'اس فون میں محفوظ ہے۔ انٹرنیٹ ملنے پر سنک ہو جائے گا۔';

  @override
  String get syncPendingShort => 'سنک کا انتظار';

  @override
  String lessOf(String name) {
    return '$name کم کریں';
  }

  @override
  String moreOf(String name) {
    return '$name بڑھائیں';
  }

  @override
  String amountOf(String name, String amount) {
    return '$name: $amount';
  }

  @override
  String get typeExactAmount => 'درست مقدار لکھنے کے لیے دبائیں';

  @override
  String howMuchOf(String name) {
    return '$name کتنا؟';
  }

  @override
  String get amountNeedsNumber => 'براہ کرم 0 سے زیادہ عدد لکھیں۔';

  @override
  String amountTooMuch(String max) {
    return 'یہ آپ کے پاس موجود مقدار سے زیادہ ہے ($max)۔';
  }

  @override
  String get haveIt => 'موجود';

  @override
  String get missingIt => 'کم';

  @override
  String get tabHome => 'ہوم';

  @override
  String get tabGroceries => 'سامان';

  @override
  String get tabCook => 'پکائیں';

  @override
  String get tabFamily => 'گھر والے';

  @override
  String get homeMenuToday => 'آج کے مینو میں کیا ہے؟';

  @override
  String get homeAddName => 'اپنا نام شامل کریں';

  @override
  String get askNameTitle => 'ہم آپ کو کیا کہہ کر بلائیں؟';

  @override
  String get askNameLabel => 'آپ کا نام';

  @override
  String get askNameNotNow => 'ابھی نہیں';

  @override
  String get settings => 'ترتیبات';

  @override
  String get heroTitle => 'آج کیا پکائیں؟';

  @override
  String get heroAltLine => 'What should we cook today?';

  @override
  String get suggestDish => 'ڈش تجویز کریں';

  @override
  String get kitchenStock => 'کچن کا سامان';

  @override
  String get seeAll => 'سب دیکھیں';

  @override
  String get shoppingDay => 'خریداری کا دن';

  @override
  String get shoppingCycleProgress => 'خریداری کے دور کی پیش رفت';

  @override
  String percentValue(int n) {
    return '$n فیصد';
  }

  @override
  String get nothingLow => 'کوئی چیز کم نہیں ہو رہی';

  @override
  String lowLeft(String name, String amount) {
    return '$name، $amount باقی';
  }

  @override
  String get cookedThisWeek => 'اس ہفتے پکایا';

  @override
  String get dailyLog => 'روزانہ کا ریکارڈ';

  @override
  String get nothingCookedWeek =>
      'اس ہفتے ابھی کچھ نہیں پکایا۔ ڈش درج کرنے کے لیے دبائیں۔';

  @override
  String get noGroceriesYet => 'ابھی کوئی سامان نہیں';

  @override
  String get noGroceriesBody =>
      'اس مہینے کی خریداری شامل کریں، میں بچے ہوئے سامان اور اگلی خریداری میں باقی دنوں کا حساب رکھوں گی۔';

  @override
  String get addGroceries => 'سامان شامل کریں';

  @override
  String get couldNotLoadGroceries =>
      'آپ کا سامان لوڈ نہیں ہو سکا۔ براہ کرم انٹرنیٹ چیک کریں۔';

  @override
  String get saved => 'محفوظ';

  @override
  String get saving => 'محفوظ ہو رہا ہے…';

  @override
  String get daysSetDate =>
      'سامان شامل کرتے وقت اگلی خریداری کی تاریخ مقرر کریں۔';

  @override
  String daysPassed(String date) {
    return 'آپ کی خریداری کا دن ($date) گزر چکا ہے۔ نیا سامان شامل کریں۔';
  }

  @override
  String daysToday(String date) {
    return 'خریداری کا دن آج ہے ($date)۔';
  }

  @override
  String daysUntil(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'اگلی خریداری میں $n دن باقی ($date)۔',
      one: 'اگلی خریداری میں 1 دن باقی ($date)۔',
    );
    return '$_temp0';
  }

  @override
  String get cookTitle => 'کیا پکائیں';

  @override
  String get cookSubtitle => 'آپ کے کچن کے سامان کے مطابق بہترین ڈش پہلے';

  @override
  String get filterMeal => 'کھانا';

  @override
  String get filterWeight => 'وزن';

  @override
  String get filterWith => 'ساتھ';

  @override
  String get optLunch => 'دوپہر';

  @override
  String get optDinner => 'رات';

  @override
  String get optLight => 'ہلکا';

  @override
  String get optMedium => 'درمیانہ';

  @override
  String get optHeavy => 'بھاری';

  @override
  String get optRice => 'چاول';

  @override
  String get optRoti => 'روٹی';

  @override
  String get optBread => 'نان';

  @override
  String get optAny => 'کوئی بھی';

  @override
  String get hiddenRecent => 'پچھلے 7 دن میں پکائی گئی ڈشیں چھپی ہوئی ہیں۔';

  @override
  String get whatHaveHome => 'گھر میں کیا کیا موجود ہے؟';

  @override
  String get hintIngredients => 'مثلاً: مرغی، پیاز، چاول، دہی';

  @override
  String get helperCommas => 'کوما سے الگ کریں';

  @override
  String get showDishes => 'ڈشیں دکھائیں';

  @override
  String get typeSomething => 'براہ کرم گھر میں موجود چند چیزیں لکھیں۔';

  @override
  String get showDifferent => 'دوسری ڈشیں دکھائیں';

  @override
  String youHaveAll(int n) {
    return 'آپ کے پاس تمام $n موجود ہیں';
  }

  @override
  String youHaveOf(int have, int total) {
    return 'آپ کے پاس $total میں سے $have ہیں';
  }

  @override
  String missingNames(String names) {
    return 'کم ہے: $names';
  }

  @override
  String get recipeBook => 'ریسپی بک';

  @override
  String get aiSuggestion => 'اے آئی کی تجویز';

  @override
  String get bestMatch => 'بہترین انتخاب';

  @override
  String get btnRecipe => 'ترکیب';

  @override
  String get btnCookThis => 'یہ پکائیں';

  @override
  String get addSubtitle => 'اس مہینے کی خریداری، تصویر سے یا لکھ کر';

  @override
  String get takePhoto => 'تصویر لیں';

  @override
  String get typeItIn => 'لکھ کر شامل کریں';

  @override
  String get choosePhoto => 'تصویر منتخب کریں';

  @override
  String get readingPhoto => 'آپ کی تصویر پڑھی جا رہی ہے…';

  @override
  String foundItems(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'آپ کی تصویر میں $n چیزیں ملیں۔',
      one: 'آپ کی تصویر میں 1 چیز ملی۔',
    );
    return '$_temp0';
  }

  @override
  String needCheck(int c) {
    String _temp0 = intl.Intl.pluralLogic(
      c,
      locale: localeName,
      other: '$c کو دیکھنے کی ضرورت ہے۔',
      one: '1 کو دیکھنے کی ضرورت ہے۔',
    );
    return '$_temp0';
  }

  @override
  String get cannotReadPhoto =>
      'میں وہ تصویر پڑھ نہیں سکی۔ براہ کرم لکھ دیں کہ یہ کیا ہے۔';

  @override
  String get cannotTell => 'میں پہچان نہیں سکی کہ یہ کیا ہے۔ براہ کرم لکھ دیں۔';

  @override
  String get cannotOpenPhotos =>
      'تصاویر نہیں کھل سکیں۔ براہ کرم لکھ دیں کہ آپ نے کیا خریدا۔';

  @override
  String get amountUnclear => 'مقدار واضح نہیں۔ ٹھیک کرنے کے لیے دبائیں۔';

  @override
  String pleaseSayHowMuch(String name) {
    return 'براہ کرم بتائیں $name کتنا ہے، یا اسے ہٹا دیں۔';
  }

  @override
  String get oftenBought => 'اکثر خریدی جانے والی چیزیں';

  @override
  String get saveOneItem => '1 چیز محفوظ کریں';

  @override
  String saveAllItems(int n) {
    return 'تمام $n چیزیں محفوظ کریں';
  }

  @override
  String get savedOffline =>
      'آپ کے فون میں محفوظ ہو گیا۔ انٹرنیٹ ملنے پر سنک ہو جائے گا۔';

  @override
  String addedOne(String name, String amount, String unit) {
    return '$name، $amount $unit شامل ہو گیا۔';
  }

  @override
  String addedMany(int n) {
    return '$n چیزیں شامل ہو گئیں۔';
  }

  @override
  String alreadyThere(String name, String total, String unit) {
    return '$name پہلے سے آپ کے کچن میں تھا، اب آپ کے پاس $total $unit ہے۔';
  }

  @override
  String addedManyRaised(int n, String names) {
    return '$n چیزیں شامل ہو گئیں۔ $names: پہلے سے کچن میں تھیں، اس لیے مقدار بڑھ گئی۔';
  }

  @override
  String get shoppingDays => 'خریداری کے دن';

  @override
  String get iShoppedOn => 'میں نے خریداری کی';

  @override
  String get nextShopping => 'اگلی خریداری';

  @override
  String get nextAfterShopped =>
      'اگلی خریداری کا دن، خریداری کے دن کے بعد ہونا چاہیے۔';

  @override
  String get couldNotSave =>
      'محفوظ نہیں ہو سکا۔ براہ کرم انٹرنیٹ چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get inKitchenNow => 'اس وقت آپ کے کچن میں';

  @override
  String get nothingAddedYet => 'ابھی کچھ شامل نہیں کیا۔';

  @override
  String removeNamedQ(String name) {
    return '$name ہٹائیں؟';
  }

  @override
  String removeNamedTip(String name) {
    return '$name ہٹائیں';
  }

  @override
  String get removeBody => 'یہ آپ کے سامان سے ہٹ جائے گا۔';

  @override
  String get sheetTypeTitle => 'چیز لکھیں';

  @override
  String get sheetFixTitle => 'اس چیز کو ٹھیک کریں';

  @override
  String get fieldItem => 'چیز';

  @override
  String get fieldItemHint => 'مثلاً: مرغی';

  @override
  String get fieldHowMuch => 'کتنا';

  @override
  String get fieldUnit => 'اکائی';

  @override
  String get pleaseTypeWhat => 'براہ کرم لکھیں کہ آپ نے کیا خریدا، مثلاً مرغی۔';

  @override
  String get pleaseTypeHowMuch => 'براہ کرم لکھیں کتنا، مثلاً 1.5۔';

  @override
  String get addToList => 'فہرست میں شامل کریں';

  @override
  String get removeFromList => 'فہرست سے ہٹائیں';

  @override
  String get unitPieces => 'عدد';

  @override
  String get unitPacks => 'پیکٹ';

  @override
  String get nameOnion => 'پیاز';

  @override
  String get nameAtta => 'آٹا';

  @override
  String get nameMilk => 'دودھ';

  @override
  String get nameEggs => 'انڈے';

  @override
  String get familyTitle => 'گھر والے';

  @override
  String get whoEats => 'گھر میں کون کھاتا ہے';

  @override
  String get adults => 'بڑے';

  @override
  String get childrenUnder12 => '12 سال سے کم بچے';

  @override
  String get spiceLevel => 'مرچ مصالحہ';

  @override
  String get spiceMild => 'کم';

  @override
  String get spiceMedium => 'درمیانہ';

  @override
  String get spiceHot => 'تیز';

  @override
  String get spiceHelpMild =>
      'کم مرچ والی ڈشیں پہلے، تیز ڈشیں نہیں دکھائی جاتیں۔';

  @override
  String get spiceHelpMedium =>
      'درمیانہ زیادہ تر ڈشیں دکھاتا ہے اور بہت تیز ڈشیں چھوڑ دیتا ہے۔';

  @override
  String get spiceHelpHot => 'تیز سب ڈشیں دکھاتا ہے، بہت مرچ والی بھی۔';

  @override
  String get favCuisines => 'پسندیدہ کھانے';

  @override
  String get cuisinePakistani => 'پاکستانی';

  @override
  String get cuisineChinese => 'چائنیز';

  @override
  String get cuisineArabic => 'عربی';

  @override
  String get cuisineItalian => 'اطالوی';

  @override
  String get cuisineBbq => 'بی بی کیو';

  @override
  String get anythingKnow => 'کوئی اور بات جو ہمیں معلوم ہونی چاہیے؟';

  @override
  String get notesHint => 'مثلاً: مشروم نہیں، تلی ہوئی چیزیں کم';

  @override
  String get privacyCard =>
      'اے آئی صرف گھر کے افراد کی تعداد، مرچ کی سطح اور پسندیدہ کھانے دیکھتا ہے۔ اسے نام، عمریں یا آپ کی ای میل کبھی نہیں ملتی۔';

  @override
  String get savedJustNow => 'ابھی محفوظ ہوا';

  @override
  String get savedOnPhone => 'فون میں محفوظ ہے';

  @override
  String get couldNotSaveTry => 'محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں';

  @override
  String get authTagline =>
      'کچن میں جو کچھ موجود ہے اسی سے ایک منٹ میں فیصلہ کریں کہ رات کو کیا پکانا ہے۔';

  @override
  String get labelName => 'آپ کا نام';

  @override
  String get nameHint => 'مثلاً: عائشہ';

  @override
  String get labelEmail => 'ای میل';

  @override
  String get emailHint => 'name@gmail.com';

  @override
  String get labelPassword => 'پاس ورڈ';

  @override
  String get passwordHelper => 'کم از کم 6 حروف';

  @override
  String get show => 'دکھائیں';

  @override
  String get hide => 'چھپائیں';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get signIn => 'سائن ان کریں';

  @override
  String get signingIn => 'سائن ان ہو رہا ہے…';

  @override
  String get createAccount => 'نیا اکاؤنٹ بنائیں';

  @override
  String get createMyAccount => 'میرا اکاؤنٹ بنائیں';

  @override
  String get creatingAccount => 'آپ کا اکاؤنٹ بن رہا ہے…';

  @override
  String get haveAccount => 'میرا اکاؤنٹ پہلے سے ہے';

  @override
  String get privateNote =>
      'آپ کا سامان اور گھر والوں کی تفصیل صرف آپ کے اکاؤنٹ میں نجی رہتی ہے۔';

  @override
  String get errName => 'براہ کرم اپنا نام بتائیں۔';

  @override
  String get errEmailPassword => 'براہ کرم اپنی ای میل اور پاس ورڈ درج کریں۔';

  @override
  String get errEmailFormat => 'پورا پتہ لکھیں، جیسے name@gmail.com';

  @override
  String get errTypeEmailFirst =>
      'پہلے اوپر اپنی ای میل لکھیں، پھر پاس ورڈ بھول گئے؟ دبائیں۔';

  @override
  String resetSent(String email) {
    return 'ہم نے $email پر لنک بھیجا ہے۔ اسے کھول کر نیا پاس ورڈ بنائیں۔';
  }

  @override
  String get authInvalidEmail => 'یہ ای میل پتہ درست نہیں لگتا۔';

  @override
  String get authWrong =>
      'ای میل یا پاس ورڈ غلط ہے۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String get authInUse => 'اس ای میل کا اکاؤنٹ پہلے سے موجود ہے۔ سائن ان کریں۔';

  @override
  String get authWeak => 'براہ کرم کم از کم 6 حروف کا پاس ورڈ چنیں۔';

  @override
  String get authNetwork =>
      'انٹرنیٹ نہیں ہے۔ براہ کرم چیک کر کے دوبارہ کوشش کریں۔';

  @override
  String get authNotEnabled => 'فائر بیس میں ای میل سائن اپ ابھی آن نہیں ہے۔';

  @override
  String authGeneric(String code) {
    return 'کچھ غلط ہو گیا ($code)۔ براہ کرم دوبارہ کوشش کریں۔';
  }

  @override
  String get settingsTitle => 'ترتیبات';

  @override
  String get account => 'اکاؤنٹ';

  @override
  String get nameLabel => 'نام';

  @override
  String get notSet => 'مقرر نہیں';

  @override
  String get emailLabel => 'ای میل';

  @override
  String get privacy => 'رازداری';

  @override
  String get privacyBody =>
      'آپ کا سامان اور گھر والوں کی تفصیل آپ کے اکاؤنٹ تک محدود ہے۔ اے آئی صرف گھر کے افراد کی تعداد، مرچ کی سطح اور پسندیدہ کھانے دیکھتا ہے۔ اسے نام، عمریں یا آپ کی ای میل کبھی نہیں ملتی۔';

  @override
  String get about => 'کے بارے میں';

  @override
  String get aboutTag => 'گھر میں موجود سامان سے ڈش کے آئیڈیاز';

  @override
  String get aboutNote =>
      'مقداریں اندازاً ہوتی ہیں۔ ڈش کے آئیڈیاز تجاویز ہیں، ضمانت نہیں۔';

  @override
  String get amountsDishes => 'مقداریں اور ڈشیں';

  @override
  String get logOut => 'لاگ آؤٹ';

  @override
  String get logOutQ => 'لاگ آؤٹ کریں؟';

  @override
  String get logOutBody =>
      'آپ کا سامان اور گھر والوں کی تفصیل محفوظ رہے گی۔ جب چاہیں دوبارہ لاگ ان کریں۔';

  @override
  String get nameSaved => 'نام محفوظ ہو گیا';

  @override
  String get language => 'زبان';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUrdu => 'اردو';
}
