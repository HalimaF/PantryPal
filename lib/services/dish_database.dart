import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/dish.dart';
import '../models/family_profile.dart';
import 'ingredient_matcher.dart';

/// One row of the learner's own recipe book (`data/dishes.csv`).
class DishRecord {
  DishRecord({
    required this.name,
    required this.cuisine,
    required this.meal,
    required this.weight,
    required this.base,
    required this.mainIngredients,
    required this.spice,
    required this.kidFriendly,
    required this.ingredientsWithQuantities,
    required this.steps,
  });

  final String name;
  final String cuisine;
  final String meal; // both, breakfast, snack, dessert or drink
  final String weight; // light, medium or heavy
  final String base; // rice, roti, naan, bread, paratha or none
  final List<String> mainIngredients;
  final String spice; // mild, medium or hot
  final bool kidFriendly;
  final List<String> ingredientsWithQuantities;
  final List<String> steps;

  /// Main ingredients that mum has to own, under their matching names.
  late final Set<String> coreIngredients = {
    for (final i in mainIngredients) ?canonicalIngredient(i),
  };
}

const _columns = [
  'name', 'cuisine', 'meal', 'weight', 'base', 'main_ingredients', 'spice',
  'kid_friendly', 'ingredients_with_quantities', 'steps',
];

/// Reads the CSV text. Rows that are broken or have no name, ingredients or steps are
/// skipped, so one bad row never stops the app.
List<DishRecord> parseDishCsv(String text) {
  final rows = Csv().decode(text);
  if (rows.isEmpty) return [];
  final header = rows.first.map((c) => c.toString().trim().toLowerCase()).toList();
  final index = {for (final c in _columns) c: header.indexOf(c)};
  if (index.values.any((i) => i < 0)) return [];

  List<String> split(String cell, Pattern separator) =>
      cell.split(separator).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  final out = <DishRecord>[];
  for (final row in rows.skip(1)) {
    if (row.length < header.length) continue;
    String cell(String column) => row[index[column]!].toString().trim();
    final record = DishRecord(
      name: cell('name'),
      cuisine: cell('cuisine'),
      meal: cell('meal').toLowerCase(),
      weight: cell('weight').toLowerCase(),
      base: cell('base').toLowerCase(),
      mainIngredients: split(cell('main_ingredients'), ';'),
      spice: cell('spice').toLowerCase(),
      kidFriendly: cell('kid_friendly').toLowerCase() == 'yes',
      ingredientsWithQuantities: split(cell('ingredients_with_quantities'), ';'),
      steps: split(cell('steps'), '|'),
    );
    if (record.name.isEmpty || record.steps.isEmpty || record.mainIngredients.isEmpty) continue;
    out.add(record);
  }
  return out;
}

/// The recipe book. Picks dishes instantly, with no waiting for Gemini.
class DishDatabase {
  DishDatabase(this.records, {Random? random}) : _random = random ?? Random();

  final List<DishRecord> records;
  final Random _random;

  static Future<DishDatabase>? _loading;

  /// Loads the bundled recipe book once and keeps it for later requests.
  static Future<DishDatabase> load() => _loading ??= () async {
        final text = await rootBundle.loadString('data/dishes.csv');
        return DishDatabase(parseDishCsv(text));
      }();

  /// Lunch and dinner use dishes marked "both"; breakfast, snacks, desserts and drinks
  /// are never offered as a meal.
  static bool _mealFits(DishRecord d) => d.meal == 'both';

  /// "Light" accepts light and medium; "Medium" only medium; "Heavy" accepts medium and heavy.
  static bool _weightFits(String wanted, DishRecord d) {
    if (wanted == 'Medium') return d.weight == 'medium';
    if (wanted == 'Light') return d.weight == 'light' || d.weight == 'medium';
    if (wanted == 'Heavy') return d.weight == 'medium' || d.weight == 'heavy';
    return true;
  }

  static bool _baseFits(String wanted, DishRecord d) {
    switch (wanted) {
      case 'Rice':
        return d.base == 'rice';
      case 'Roti':
        return d.base == 'roti';
      case 'Bread':
        return d.base == 'naan' || d.base == 'bread' || d.base == 'paratha';
      case 'Noodles':
        return d.base == 'noodles';
      default:
        return true;
    }
  }

  /// How well a dish suits the family: spice level, kids, and favourite cuisines.
  /// Only used to order dishes that are equally good on ingredients.
  static int _profileFit(DishRecord d, FamilyProfile profile) {
    var fit = 0;
    switch (profile.spice) {
      case 'Mild':
        fit += d.spice == 'mild' ? 2 : (d.spice == 'medium' ? 1 : 0);
      case 'Medium':
        fit += d.spice == 'medium' ? 2 : (d.spice == 'mild' ? 1 : 0);
      case 'Hot':
        fit += d.spice == 'hot' ? 2 : (d.spice == 'medium' ? 1 : 0);
    }
    if (profile.childCount > 0 && d.kidFriendly) fit += 2;
    if (profile.cuisines.any((c) => c.toLowerCase() == d.cuisine.toLowerCase())) fit += 1;
    return fit;
  }

  /// Dishes that fit the answers, best match first. A dish needs at least half of its
  /// main ingredients to be available. [exclude] holds names already shown.
  List<Dish> suggest(SuggestRequest request, {Set<String> exclude = const {}, int limit = 5}) {
    final have = typedIngredients(request.ingredients);
    final skip = {for (final name in exclude) name.trim().toLowerCase()};
    final profile = request.profile;
    final scored =
        <({DishRecord record, double coverage, int matched, bool exactWeight, int fit})>[];

    for (final d in records) {
      if (skip.contains(d.name.toLowerCase())) continue;
      if (!_mealFits(d) || !_weightFits(request.weight, d) || !_baseFits(request.base, d)) continue;
      final core = d.coreIngredients;
      if (core.isEmpty) continue;
      // Someone who wants mild food is never offered the hot dishes.
      if (profile.spice == 'Mild' && d.spice == 'hot') continue;
      final matched = core.where(have.contains).length;
      if (matched == 0) continue;
      final coverage = matched / core.length;
      if (coverage < 0.5) continue;
      final exactWeight = request.weight.toLowerCase() == d.weight;
      scored.add((
        record: d,
        coverage: coverage,
        matched: matched,
        exactWeight: exactWeight,
        fit: _profileFit(d, profile),
      ));
    }

    // Shuffle first so equally good dishes change each time; the sort keeps the best on top.
    scored.shuffle(_random);
    scored.sort((a, b) {
      final byCoverage = b.coverage.compareTo(a.coverage);
      if (byCoverage != 0) return byCoverage;
      final byFit = b.fit.compareTo(a.fit);
      if (byFit != 0) return byFit;
      final byWeight = (b.exactWeight ? 1 : 0).compareTo(a.exactWeight ? 1 : 0);
      if (byWeight != 0) return byWeight;
      return b.matched.compareTo(a.matched);
    });

    // Variety: many dishes share the same main ingredients (all the biryani variants), so
    // at most two of them are offered at once.
    final perIngredientSet = <String, int>{};
    final picked = <DishRecord>[];
    for (final s in scored) {
      final key = (s.record.coreIngredients.toList()..sort()).join('|');
      if ((perIngredientSet[key] ?? 0) >= 2) continue;
      perIngredientSet[key] = (perIngredientSet[key] ?? 0) + 1;
      picked.add(s.record);
      if (picked.length == limit) break;
    }
    return [for (final d in picked) _toDish(d, have)];
  }

  Dish _toDish(DishRecord d, Set<String> have) {
    final seen = <String>{};
    final used = [
      for (final i in d.mainIngredients)
        if (canonicalIngredient(i) case final c? when have.contains(c) && seen.add(c)) i,
    ];
    return Dish(
      name: d.name,
      why: used.isEmpty ? 'From your recipe book.' : 'Uses ${used.join(', ')} you have.',
      mainIngredients: [
        for (final i in d.mainIngredients)
          if (canonicalIngredient(i) != null) i,
      ],
      recipe: Recipe(ingredients: d.ingredientsWithQuantities, steps: d.steps),
      fromDatabase: true,
    );
  }
}
