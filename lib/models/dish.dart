import 'family_profile.dart';

/// One suggested dish. Implements prd.md > Dish suggestion.
class Dish {
  const Dish({
    required this.name,
    required this.why,
    required this.mainIngredients,
    this.recipe,
    this.fromDatabase = false,
  });

  final String name;
  final String why; // one friendly line on why it fits today
  final List<String> mainIngredients;

  /// Set for dishes from the learner's own recipe book, so no waiting for Gemini.
  final Recipe? recipe;
  final bool fromDatabase;
}

/// The full recipe shown after tapping a dish.
class Recipe {
  const Recipe({required this.ingredients, required this.steps});

  final List<String> ingredients;
  final List<String> steps;
}

/// What mum answered on the questions page.
class SuggestRequest {
  const SuggestRequest({
    required this.meal,
    required this.weight,
    required this.base,
    required this.ingredients,
    this.stockDetails = const [],
    this.recentMeals = const [],
    this.profile = FamilyProfile.empty,
  });

  final String meal; // Lunch or Dinner
  final String weight; // Heavy or Light
  final String base; // Rice, Roti, Bread, Noodles or Any
  final List<String> ingredients; // what she has at home

  /// The same items with amounts ("Chicken 1.5 kg"), so Gemini can see how much is left.
  final List<String> stockDetails;

  /// Dishes the family ate in the last week; they are not suggested again.
  final List<String> recentMeals;

  /// Who she cooks for and what they like.
  final FamilyProfile profile;
}
