// Makes "eggs", "anda" and "egg" the same thing, so what mum types matches the
// names used in `data/dishes.csv`. Implements the matching in spec.md > Components.

/// Words in the recipe book's main_ingredients that are not ingredients mum has to
/// own (styles, cooking steps, pantry basics). They never count for or against a dish.
const _ignored = {
  'tarka', 'spices', 'spice', 'whole spices', 'pickling spices', 'spices (clay pot)',
  'classic', 'achari', 'reshmi', 'haryali', 'lasooni', 'kali mirch', 'karachi', 'karak',
  'kashmiri', 'katchi', 'namkeen', 'sweet', 'mixed', 'mix', 'hot', 'double', 'dry',
  'fresh', 'boiled', 'cooked', 'mashed', 'shahi', 'sheer', 'masala', 'tikka masala',
  'boti masala', 'tandoori masala', 'nihari masala', 'chaat masala', 'chaat', 'broth',
  'yakhni', 'kebab', 'chutney', 'dough', 'crisp bread', 'pastry', 'samosa pastry',
  'patty', 'bun', 'yeast', 'oil', 'salt', 'saffron', 'poppy seeds', 'nigella', 'cumin',
  'fennel', 'pepper', 'black pepper', 'chilli', 'sulemani', 'rooh', 'meethi', 'grains',
  'daals', 'papri', 'bhel', 'gol', 'gola', 'pakoras', 'samosa', 'ras', 'qehwa', 'jaljeera',
};

/// Each key is the one name used for matching; the list holds other ways to say it.
const _aliases = <String, List<String>>{
  'egg': ['eggs', 'anda', 'anday'],
  'potato': ['potatoes', 'aloo', 'baby potatoes'],
  'tomato': ['tomatoes', 'tamatar'],
  'onion': ['onions', 'pyaz', 'pyaaz'],
  'yogurt': ['yoghurt', 'dahi', 'curd'],
  'chicken': ['murgh', 'whole chicken', 'chicken wings', 'chicken mince', 'chicken tikka'],
  'mutton': ['lamb', 'mutton leg', 'mutton shank', 'whole lamb', 'gosht', 'goat'],
  'beef': ['beef shank'],
  'mince': ['qeema', 'keema', 'beef mince', 'mutton mince', 'minced meat'],
  'fish': ['fish mince'],
  'prawns': ['prawn', 'shrimp', 'shrimps'],
  'liver': ['kaleji'],
  'rice': ['basmati rice', 'chawal'],
  'gram flour': ['besan'],
  'wheat flour': ['aata', 'atta', 'flour', 'wheat'],
  'refined flour': ['maida'],
  'chana daal': ['chana dal', 'chana'],
  'chickpeas': ['chanay', 'chole', 'cholay', 'kabuli chana'],
  'peas': ['matar', 'green peas'],
  'spinach': ['palak'],
  'cauliflower': ['gobi'],
  'cabbage': ['band gobi'],
  'carrot': ['gajar', 'carrots'],
  'eggplant': ['baingan', 'aubergine', 'brinjal'],
  'okra': ['bhindi'],
  'bottle gourd': ['lauki'],
  'ridge gourd': ['tori', 'turai'],
  'pumpkin': ['kaddu'],
  'capsicum': ['shimla mirch', 'bell pepper'],
  'bitter gourd': ['karela', 'karella'],
  'turnip': ['turnips', 'shalgam'],
  'radish': ['mooli'],
  'green beans': ['sem', 'hari phali', 'beans'],
  'mushroom': ['mushrooms'],
  'coriander': ['dhaniya', 'cilantro'],
  'mint': ['pudina'],
  'fenugreek': ['methi'],
  'tamarind': ['imli'],
  'milk': ['doodh'],
  'cream': ['malai'],
  'paneer': ['cottage cheese'],
  'garlic': ['lehsun', 'lasoon'],
  'ginger': ['adrak'],
  'green chilli': ['green chillies', 'hari mirch', 'mirch', 'green chili'],
  'lemon': ['nimbu', 'lime'],
  'sugar': ['cheeni'],
  'colocasia': ['arvi'],
  'apple gourd': ['tinda'],
  'sweet potato': ['shakarkandi'],
};

final Map<String, String> _canonical = {
  for (final entry in _aliases.entries) ...{
    entry.key: entry.key,
    for (final alias in entry.value) alias: entry.key,
  },
};

/// Returns the single name for an ingredient, or null for a word that is not an
/// ingredient mum has to own.
String? canonicalIngredient(String raw) {
  var word = raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  if (word.isEmpty || _ignored.contains(word)) return null;
  if (_canonical.containsKey(word)) return _canonical[word];
  // "onions" -> "onion", "tomatoes" -> "tomato"
  for (final singular in [
    if (word.endsWith('es')) word.substring(0, word.length - 2),
    if (word.endsWith('s')) word.substring(0, word.length - 1),
  ]) {
    if (_canonical.containsKey(singular)) return _canonical[singular];
  }
  return word;
}

/// What mum typed, as a set of canonical names ("Chicken breast" also gives "chicken").
Set<String> typedIngredients(List<String> typed) {
  final out = <String>{};
  for (final raw in typed) {
    final canon = canonicalIngredient(raw);
    if (canon == null) continue;
    out.add(canon);
    // "chicken breast" should still match a dish that needs "chicken".
    for (final part in raw.toLowerCase().split(RegExp(r'[\s/-]+'))) {
      final c = canonicalIngredient(part);
      if (c != null) out.add(c);
    }
  }
  return out;
}
