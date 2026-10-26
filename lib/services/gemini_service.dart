import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/dish.dart';
import '../models/inventory_item.dart';

/// Models are kept in one place so they are easy to swap (spec.md > Stack).
/// The first is tried first; the next one is used when it is busy or unavailable.
const geminiModels = ['gemini-3.8-flash', 'gemini-3.5-flash-lite'];

/// A problem we can explain to mum in plain words.
class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sends a prompt and a JSON schema, returns the raw JSON text. Replaceable in tests.
typedef Generate = Future<String> Function(String prompt, Schema schema);

/// Like [Generate], with a photo. Replaceable in tests.
typedef GenerateImage = Future<String> Function(
  String prompt,
  Schema schema,
  Uint8List image,
  String mimeType,
);

/// Models that read photos, tried in this order. The Lite model is listed on Google's pricing
/// page with image input; the other is the backup (spec.md > Stack).
const geminiImageModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];

/// How much of one grocery item Gemini thinks went into a dish.
class UsedEstimate {
  const UsedEstimate({required this.itemId, required this.amount});

  final String itemId; // the inventory document
  final double amount; // in the item's own unit
}

/// All AI calls live here. Implements spec.md > Components > Gemini service.
class GeminiService {
  GeminiService({Generate? generate, GenerateImage? generateImage})
      : _generate = generate ?? _generateWithFirebase,
        _generateImage = generateImage ?? _generateImageWithFirebase;

  final Generate _generate;
  final GenerateImage _generateImage;

  /// A rough guess of how much of each grocery item went into the dish in the photo.
  /// Only items she has are returned, never more than is left. Implements prd.md > Log today's dish.
  Future<List<UsedEstimate>> estimateUsed(
    Uint8List photo,
    String mimeType, {
    required String dishName,
    required List<InventoryItem> stock,
  }) async {
    final text = await _generateImage(
      buildEstimatePrompt(dishName, stock),
      _estimateSchema,
      photo,
      mimeType,
    );
    return parseUsedEstimates(text, stock);
  }

  /// Every grocery item in a photo: its name (with the brand if visible) and how much the
  /// packaging shows. Empty when it cannot tell what anything is.
  /// Implements prd.md > Features and Behavior > Add groceries (photo).
  Future<List<IdentifiedItem>> identifyItems(Uint8List photo, String mimeType) async {
    final text = await _generateImage(buildIdentifyPrompt(), _identifySchema, photo, mimeType);
    return parseIdentifiedItems(text);
  }

  Future<List<Dish>> suggestDishes(SuggestRequest request) async {
    final text = await _generate(buildSuggestPrompt(request), _dishesSchema);
    return parseDishes(text);
  }

  Future<Recipe> getRecipe(String dishName, List<String> ingredients) async {
    final text = await _generate(buildRecipePrompt(dishName, ingredients), _recipeSchema);
    return parseRecipe(text);
  }
}

final _dishesSchema = Schema.object(properties: {
  'dishes': Schema.array(
    items: Schema.object(properties: {
      'name': Schema.string(),
      'why': Schema.string(),
      'mainIngredients': Schema.array(items: Schema.string()),
    }),
  ),
});

final _identifySchema = Schema.object(properties: {
  'items': Schema.array(
    items: Schema.object(
      properties: {
        'name': Schema.string(),
        'amount': Schema.number(nullable: true),
        'unit': Schema.string(nullable: true),
      },
      optionalProperties: ['amount', 'unit'],
    ),
  ),
});

final _estimateSchema = Schema.object(properties: {
  'used': Schema.array(
    items: Schema.object(properties: {
      'name': Schema.string(),
      'amount': Schema.number(),
    }),
  ),
});

final _recipeSchema = Schema.object(properties: {
  'ingredients': Schema.array(items: Schema.string()),
  'steps': Schema.array(items: Schema.string()),
});

Future<String> _generateWithFirebase(String prompt, Schema schema) {
  return generateWithFallback(geminiModels, (modelName) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
    final response =
        await model.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 60));
    final text = response.text;
    if (text == null || text.trim().isEmpty) throw StateError('empty answer');
    return text;
  });
}

Future<String> _generateImageWithFirebase(
  String prompt,
  Schema schema,
  Uint8List image,
  String mimeType,
) {
  return generateWithFallback(geminiImageModels, (modelName) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
    final response = await model.generateContent([
      Content.multi([TextPart(prompt), InlineDataPart(mimeType, image)]),
    ]).timeout(const Duration(seconds: 45));
    final text = response.text;
    if (text == null || text.trim().isEmpty) throw StateError('empty answer');
    return text;
  });
}

/// Tries each model in turn. A busy, missing or slow model moves on to the next one;
/// only when every model has failed does mum see a message.
Future<String> generateWithFallback(
  List<String> models,
  Future<String> Function(String model) attempt,
) async {
  var busy = false;
  for (final model in models) {
    try {
      return await attempt(model);
    } catch (e) {
      // Technical detail goes to the log (`adb logcat -s flutter`); mum sees a kind message.
      debugPrint('Gemini model $model failed: ${e.runtimeType}: $e');
      if (e is ServiceApiNotEnabled) {
        throw GeminiException('Gemini is not switched on in Firebase yet. Open Firebase console, AI Logic, and press Get started.');
      }
      if (e is InvalidApiKey) {
        throw GeminiException('The app is not allowed to use Gemini yet. Please check the Firebase setup.');
      }
      if (e is QuotaExceeded ||
          e is FirebaseAIException ||
          e is TimeoutException ||
          e is StateError) {
        busy = true;
        continue;
      }
      throw GeminiException('Could not reach the cooking helper. Please check your internet and try again.');
    }
  }
  throw GeminiException(busy
      ? 'The cooking helper is very busy right now. Please try again in a minute.'
      : 'The cooking helper could not answer. Please try again.');
}

String buildIdentifyPrompt() => '''
This is a photo of groceries bought for a home kitchen, likely in an Asian household.
List every different grocery item you can see, up to 12. If the same item appears several times, list it once.
For each item give:
- name: what it is, in simple everyday English. If a brand is visible on the packaging, put the brand first and keep it as printed, for example "Shan Chaat Masala", "National Chaat Masala", "Olpers Milk". With no brand, use a plain name such as chicken, basmati rice, onions.
- amount and unit: how much there is.
  * If the packaging shows a quantity for something sold by volume or weight (milk, oil, flour, rice, sugar), use it, for example 1 L, 500 ml, 2 kg, 500 g.
  * Spices, masalas, tea and small packets count as packs: amount 1, unit "packs" (or the number of packs you can see).
  * If you can count identical items (eggs, bananas, tomatoes), use the count with unit "pieces".
  * If you cannot tell how much, leave amount and unit empty.
Allowed units: kg, g, L, ml, pieces, packs.
If you cannot tell what anything is, return an empty list.''';

String buildEstimatePrompt(String dishName, List<InventoryItem> stock) {
  final dish = dishName.trim().isEmpty ? 'a home-cooked dish' : '"${dishName.trim()}"';
  final have = [
    for (final i in stock) '${i.name} (${formatAmount(i.amount)} ${i.unit} left)',
  ].join('; ');
  return '''
This is a photo of $dish cooked in a home kitchen, likely in an Asian household.
Estimate roughly how much of each grocery item below was used to make everything you can see in the photo.
Only use items from this list, and give each amount in that item's own unit: $have.
Leave out items that were not used. Never give more than what is left. If you cannot tell, return an empty list.''';
}

String buildSuggestPrompt(SuggestRequest r) {
  final items = r.stockDetails.isNotEmpty ? r.stockDetails : r.ingredients;
  final have = items.isEmpty ? 'not specified' : items.join(', ');
  final base = r.base == 'Any' ? 'any staple' : r.base.toLowerCase();
  final recent = r.recentMeals.isEmpty
      ? ''
      : '\n- The family ate these recently, so do not suggest them: ${r.recentMeals.join(', ')}.';
  final aboutFamily = r.profile.summaryForAi();
  final family = aboutFamily.isEmpty ? '' : '\n- About the family: $aboutFamily';
  return '''
You are a friendly home-cooking helper for a family in an Asian household.
Suggest 5 home-style dishes for ${r.meal.toLowerCase()}.
- The meal should be ${r.weight.toLowerCase()}.
- The staple should be $base.
- Ingredients at home: $have.$recent$family
Use mostly the ingredients at home. Only add common pantry items such as oil, salt, water and basic spices.
For each dish give: name, why (one short friendly sentence on why it fits), and mainIngredients (the 3 to 6 main items used).
Keep dish names simple and familiar.''';
}

String buildRecipePrompt(String dishName, List<String> ingredients) {
  final have = ingredients.isEmpty ? 'not specified' : ingredients.join(', ');
  return '''
Write a clear home recipe for "$dishName" for a family of about four.
Ingredients at home: $have. Use them where they fit.
Give ingredients (each with a simple quantity) and steps (short, numbered in order, written for a home cook).''';
}

/// Other ways Gemini might write a unit, matched to the ones the app uses.
const _unitNames = {
  'kg': 'kg', 'kgs': 'kg', 'kilo': 'kg', 'kilos': 'kg', 'kilogram': 'kg', 'kilograms': 'kg',
  'g': 'g', 'gm': 'g', 'gms': 'g', 'gram': 'g', 'grams': 'g',
  'l': 'L', 'lt': 'L', 'ltr': 'L', 'liter': 'L', 'liters': 'L', 'litre': 'L', 'litres': 'L',
  'ml': 'ml', 'milliliter': 'ml', 'milliliters': 'ml', 'millilitre': 'ml', 'millilitres': 'ml',
  'piece': 'pieces', 'pieces': 'pieces', 'pcs': 'pieces', 'pc': 'pieces', 'count': 'pieces',
  'pack': 'packs', 'packs': 'packs', 'packet': 'packs', 'packets': 'packs', 'box': 'packs',
};

/// The unit in the app's own spelling, or null when it is not one we know.
String? normalizeUnit(String? raw) => _unitNames[(raw ?? '').trim().toLowerCase()];

/// Every item Gemini saw, tidied up. Items it could not name are dropped, and an amount is only
/// kept when it comes with a unit we know and makes sense.
List<IdentifiedItem> parseIdentifiedItems(String text) {
  try {
    final data = jsonDecode(text) as Map<String, dynamic>;
    final found = <IdentifiedItem>[];
    final seen = <String>{};
    for (final raw in data['items'] as List) {
      if (raw is! Map) continue;
      var name = (raw['name'] as String? ?? '').replaceAll('"', '').trim();
      if (name.length > 40) name = name.substring(0, 40).trim();
      const unknown = {'', 'unknown', 'n/a', 'none', 'unclear', 'unidentified', 'not sure'};
      if (unknown.contains(name.toLowerCase())) continue;

      final rawAmount = raw['amount'];
      final unit = normalizeUnit(raw['unit'] as String?);
      final amount = rawAmount is num ? rawAmount.toDouble() : null;
      final usable = amount != null && amount > 0 && amount <= 10000 && unit != null;
      // The same item twice is listed once.
      if (!seen.add('${name.toLowerCase()}|${usable ? unit : ''}')) continue;
      found.add(IdentifiedItem(
        name: name,
        amount: usable ? amount : null,
        unit: usable ? unit : null,
      ));
      if (found.length == 12) break;
    }
    return found;
  } on Object {
    throw GeminiException('We could not read the photo. Please type what it is.');
  }
}

/// Gemini's guesses, matched to her groceries by name. Names she does not have are ignored, and
/// an amount is never more than what is left or less than nothing.
List<UsedEstimate> parseUsedEstimates(String text, List<InventoryItem> stock) {
  try {
    final data = jsonDecode(text) as Map<String, dynamic>;
    final byName = {for (final i in stock) i.name.trim().toLowerCase(): i};
    final out = <UsedEstimate>[];
    final seen = <String>{};
    for (final raw in data['used'] as List) {
      if (raw is! Map) continue;
      final item = byName[(raw['name'] as String? ?? '').trim().toLowerCase()];
      final amount = raw['amount'];
      if (item == null || amount is! num || amount <= 0 || !seen.add(item.id)) continue;
      final capped = amount.toDouble() > item.amount ? item.amount : amount.toDouble();
      out.add(UsedEstimate(itemId: item.id, amount: capped));
    }
    return out;
  } on Object {
    throw GeminiException('We could not work out the amounts. Please type them.');
  }
}

List<Dish> parseDishes(String text) {
  try {
    final data = jsonDecode(text) as Map<String, dynamic>;
    final dishes = (data['dishes'] as List)
        .map((d) => Dish(
              name: (d['name'] as String).trim(),
              why: (d['why'] as String).trim(),
              mainIngredients:
                  (d['mainIngredients'] as List).map((e) => (e as String).trim()).toList(),
            ))
        .where((d) => d.name.isNotEmpty)
        .toList();
    if (dishes.isEmpty) throw const FormatException('no dishes');
    return dishes;
  } on Object {
    throw GeminiException('We could not read the dish ideas. Please try again.');
  }
}

Recipe parseRecipe(String text) {
  try {
    final data = jsonDecode(text) as Map<String, dynamic>;
    final recipe = Recipe(
      ingredients: (data['ingredients'] as List).map((e) => (e as String).trim()).toList(),
      steps: (data['steps'] as List).map((e) => (e as String).trim()).toList(),
    );
    if (recipe.steps.isEmpty) throw const FormatException('no steps');
    return recipe;
  } on Object {
    throw GeminiException('We could not read the recipe. Please try again.');
  }
}
