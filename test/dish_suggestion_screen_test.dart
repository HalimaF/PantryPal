import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/screens/dish_suggestion_screen.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';
import 'package:what_can_i_cook/state/cook_choices.dart';
import 'package:what_can_i_cook/ui/skeleton.dart';

import 'helpers/test_app.dart';

const _csv = '''name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps
Chicken Pulao,Pakistani,both,medium,rice,chicken; rice; onion,mild,yes,Chicken 1 kg; Rice 2 cups,Fry onions|Add chicken|Add rice
''';

const _stock = [
  InventoryItem(id: '1', name: 'Chicken', amount: 1.5, unit: 'kg'),
  InventoryItem(id: '2', name: 'Rice', amount: 5, unit: 'kg'),
];

GeminiService _noGemini() => GeminiService(generate: (_, _) async => throw StateError('Gemini was not expected'));

Future<void> _open(
  WidgetTester tester, {
  Future<List<InventoryItem>>? stock,
  Future<Set<String>>? recent,
  GeminiService? gemini,
  Map<String, Object> saved = const {'cook_base': 'Rice'},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  tester.view.physicalSize = const Size(900, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(testApp(DishSuggestionScreen(
    stock: stock,
    recentMeals: recent,
    database: DishDatabase(parseDishCsv(_csv)),
    gemini: gemini ?? _noGemini(),
  )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with groceries saved, dishes appear at once and nothing is asked', (tester) async {
    await _open(tester, stock: Future.value(_stock));

    expect(find.text('What to cook'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Chicken Pulao'), findsOneWidget);
    expect(find.text('Recipe book'), findsOneWidget);
    expect(find.text('Best match'), findsOneWidget);
    expect(find.text('Dishes cooked in the last 7 days are hidden.'), findsOneWidget);
  });

  testWidgets('shows how much of the dish she already has, and what is missing', (tester) async {
    await _open(tester, stock: Future.value(_stock));

    expect(find.text('You have 2 of 3'), findsOneWidget);
    expect(find.text('Missing: onion'), findsOneWidget);
  });

  testWidgets('says "You have all" when nothing is missing', (tester) async {
    await _open(tester, stock: Future.value([..._stock, const InventoryItem(id: '3', name: 'Onion', amount: 2, unit: 'kg')]));

    expect(find.text('You have all 3'), findsOneWidget);
    expect(find.textContaining('Missing'), findsNothing);
  });

  testWidgets('with no groceries saved it asks what she has', (tester) async {
    await _open(tester, stock: Future.value(const <InventoryItem>[]));

    expect(find.text('What do you have at home?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('Show me dishes'));
    await tester.pump();
    expect(find.text('Please type a few things you have at home.'), findsOneWidget);
  });

  testWidgets('typed ingredients still work without any saved groceries', (tester) async {
    await _open(tester, stock: Future.value(const <InventoryItem>[]));

    await tester.enterText(find.byType(TextField), 'chicken, rice, onion');
    await tester.tap(find.text('Show me dishes'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken Pulao'), findsOneWidget);
  });

  testWidgets('when the recipe book has nothing, Gemini is asked and the card says AI suggestion',
      (tester) async {
    String? prompt;
    final gemini = GeminiService(generate: (p, _) async {
      prompt = p;
      return '{"dishes":[{"name":"Chicken Toast","why":"Quick.","mainIngredients":["chicken"]}]}';
    });
    await _open(tester, stock: Future.value(_stock), gemini: gemini);

    await tester.tap(find.text('Bread')); // the recipe book has no bread dishes
    await tester.pumpAndSettle();

    expect(find.text('Chicken Toast'), findsOneWidget);
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(prompt, contains('Chicken 1.5 kg'));
    expect(prompt, contains('Rice 5 kg'));
  });

  testWidgets('a dish eaten recently is not suggested again', (tester) async {
    String? prompt;
    final gemini = GeminiService(generate: (p, _) async {
      prompt = p;
      return '{"dishes":[{"name":"Chicken Karahi","why":"New.","mainIngredients":["chicken"]}]}';
    });
    await _open(tester,
        stock: Future.value(_stock), recent: Future.value({'chicken pulao'}), gemini: gemini);

    expect(find.text('Chicken Pulao'), findsNothing);
    expect(find.text('Chicken Karahi'), findsOneWidget);
    expect(prompt, contains('chicken pulao'));
  });

  testWidgets('changing a filter shows new dishes and remembers the choice', (tester) async {
    await _open(tester, stock: Future.value(_stock));
    expect(find.text('Chicken Pulao'), findsOneWidget);

    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken Pulao'), findsOneWidget); // dishes marked "both" suit lunch too

    final saved = await CookChoices.load();
    expect(saved.meal, 'Lunch');
    expect(saved.base, 'Rice');
  });

  testWidgets('starts from the last choices she made', (tester) async {
    await _open(tester,
        stock: Future.value(_stock), saved: {'cook_base': 'Rice', 'cook_weight': 'Medium', 'cook_meal': 'Lunch'});

    // one tick per chosen filter: Lunch, Medium, Rice
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
  });

  testWidgets('an old saved base that is no longer offered falls back to the default', (tester) async {
    SharedPreferences.setMockInitialValues({'cook_base': 'Noodles'});
    expect((await CookChoices.load()).base, 'Roti');
  });

  testWidgets('if groceries cannot be read it falls back to asking', (tester) async {
    await _open(tester, stock: Future<List<InventoryItem>>(() => throw Exception('offline')));

    expect(find.text('What do you have at home?'), findsOneWidget);
  });

  testWidgets('if the groceries never arrive she is not stuck', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(900, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(testApp(DishSuggestionScreen(
      stock: Completer<List<InventoryItem>>().future, // never completes
      database: DishDatabase(parseDishCsv(_csv)),
    )));
    await tester.pump();
    expect(find.byType(SkeletonLoader), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.text('What do you have at home?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
