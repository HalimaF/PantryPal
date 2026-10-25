import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/screens/dish_suggestion_screen.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';
import 'package:what_can_i_cook/theme.dart';

const _csv = '''name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps
Chicken Pulao,Pakistani,both,medium,rice,chicken; rice; onion,mild,yes,Chicken 1 kg; Rice 2 cups,Fry onions|Add chicken|Add rice
''';

const _stock = [
  InventoryItem(id: '1', name: 'Chicken', amount: 1.5, unit: 'kg'),
  InventoryItem(id: '2', name: 'Rice', amount: 5, unit: 'kg'),
];

Future<void> _open(
  WidgetTester tester, {
  Future<List<InventoryItem>>? stock,
  GeminiService? gemini,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: DishSuggestionScreen(
      stock: stock,
      database: DishDatabase(parseDishCsv(_csv)),
      gemini: gemini ?? GeminiService(generate: (_, _) async => throw StateError('Gemini was not expected')),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with groceries saved it does not ask what she has', (tester) async {
    await _open(tester, stock: Future.value(_stock));

    expect(find.text('Using what is in your kitchen'), findsOneWidget);
    expect(find.text('Chicken, Rice'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Show me dishes'));
    await tester.pumpAndSettle();

    expect(find.text('From your own recipe book'), findsOneWidget);
    expect(find.text('Chicken Pulao'), findsOneWidget);
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

  testWidgets('when the recipe book has nothing, Gemini is asked with the amounts left',
      (tester) async {
    String? prompt;
    final gemini = GeminiService(generate: (p, _) async {
      prompt = p;
      return '{"dishes":[{"name":"Chicken Noodles","why":"Quick.","mainIngredients":["chicken"]}]}';
    });
    await _open(tester, stock: Future.value(_stock), gemini: gemini);

    await tester.tap(find.text('Noodles')); // the recipe book has no noodle dishes
    await tester.tap(find.text('Show me dishes'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken Noodles'), findsOneWidget);
    expect(find.text('Ideas from the cooking helper'), findsOneWidget);
    expect(prompt, contains('Chicken 1.5 kg'));
    expect(prompt, contains('Rice 5 kg'));
  });

  testWidgets('if groceries cannot be read it falls back to asking', (tester) async {
    await _open(tester, stock: Future<List<InventoryItem>>(() => throw Exception('offline')));

    expect(find.text('What do you have at home?'), findsOneWidget);
  });

  testWidgets('if the groceries never arrive she is not stuck', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(useWebFonts: false),
      home: DishSuggestionScreen(
        stock: Completer<List<InventoryItem>>().future, // never completes
        database: DishDatabase(parseDishCsv(_csv)),
      ),
    ));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.text('What do you have at home?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
