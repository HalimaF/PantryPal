import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/dish.dart';

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

/// All AI calls live here. Implements spec.md > Components > Gemini service.
class GeminiService {
  GeminiService({Generate? generate}) : _generate = generate ?? _generateWithFirebase;

  final Generate _generate;

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
