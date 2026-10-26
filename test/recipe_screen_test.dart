import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/screens/recipe_screen.dart';
import 'package:what_can_i_cook/services/data_service.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';
import 'package:what_can_i_cook/theme.dart';

const _request = SuggestRequest(
  meal: 'Dinner',
  weight: 'Light',
  base: 'Rice',
  ingredients: ['chicken', 'rice'],
);

const _fromBook = Dish(
  name: 'Chicken Pulao',
  why: 'Uses chicken, rice you have.',
  mainIngredients: ['chicken', 'rice'],
  recipe: Recipe(
    ingredients: ['Chicken 1 kg', 'Rice 2 cups'],
    steps: ['Fry the onions', 'Add the chicken', 'Add rice and cook'],
  ),
  fromDatabase: true,
);

const _fromGemini = Dish(
  name: 'Chicken Karahi',
  why: 'A quick idea.',
  mainIngredients: ['chicken'],
);

const _geminiRecipe =
    '{"ingredients":["1 kg chicken","2 tomatoes"],"steps":["Heat oil","Add chicken","Add tomatoes"]}';

Future<void> _open(
  WidgetTester tester,
  Dish dish, {
  GeminiService? gemini,
  DataService? data,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: RecipeScreen(
      dish: dish,
      request: _request,
      gemini: gemini ?? GeminiService(generate: (_, _) async => throw StateError('Gemini was not expected')),
      data: data,
    ),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  group('a dish from the recipe book', () {
    testWidgets('shows the recipe straight away, without asking Gemini', (tester) async {
      await _open(tester, _fromBook);

      expect(find.text('Chicken Pulao'), findsOneWidget);
      expect(find.text('Ingredients'), findsOneWidget);
      expect(find.text('Chicken 1 kg'), findsOneWidget);
      expect(find.text('How to make it'), findsOneWidget);
      expect(find.text('Add the chicken'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('numbers the steps in order', (tester) async {
      await _open(tester, _fromBook);

      for (final number in ['1', '2', '3']) {
        expect(find.text(number), findsOneWidget);
      }
      expect(tester.getTopLeft(find.text('Fry the onions')).dy,
          lessThan(tester.getTopLeft(find.text('Add rice and cook')).dy));
    });
  });

  group('a dish suggested by Gemini', () {
    testWidgets('waits for the recipe, then shows it', (tester) async {
      final reply = Completer<String>();
      await _open(
        tester,
        _fromGemini,
        gemini: GeminiService(generate: (_, _) => reply.future),
        settle: false,
      );
      expect(find.text('Writing the recipe…'), findsOneWidget);

      reply.complete(_geminiRecipe);
      await tester.pumpAndSettle();

      expect(find.text('Writing the recipe…'), findsNothing);
      expect(find.text('1 kg chicken'), findsOneWidget);
      expect(find.text('Add tomatoes'), findsOneWidget);
    });

    testWidgets('asks Gemini for this dish and the ingredients she has', (tester) async {
      String? prompt;
      await _open(
        tester,
        _fromGemini,
        gemini: GeminiService(generate: (p, _) async {
          prompt = p;
          return _geminiRecipe;
        }),
      );

      expect(prompt, contains('Chicken Karahi'));
      expect(prompt, contains('chicken, rice'));
    });

    testWidgets('if it fails she sees a kind message and can try again', (tester) async {
      var calls = 0;
      await _open(
        tester,
        _fromGemini,
        gemini: GeminiService(generate: (_, _) async {
          calls++;
          if (calls == 1) {
            throw GeminiException('The cooking helper is very busy right now. Please try again in a minute.');
          }
          return _geminiRecipe;
        }),
      );
      expect(find.textContaining('very busy'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('1 kg chicken'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('an unexpected error still gives a plain message, never a crash', (tester) async {
      await _open(
        tester,
        _fromGemini,
        gemini: GeminiService(generate: (_, _) async => throw StateError('something odd')),
      );

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a reply that cannot be read is explained', (tester) async {
      await _open(
        tester,
        _fromGemini,
        gemini: GeminiService(generate: (_, _) async => 'this is not json'),
      );

      expect(find.textContaining('could not read the recipe'), findsOneWidget);
    });
  });

  group('"I cooked this"', () {
    testWidgets('is not offered when there is nowhere to save it', (tester) async {
      await _open(tester, _fromBook);

      expect(find.text('I cooked this'), findsNothing);
    });

    testWidgets('opens the log with the dish already filled in', (tester) async {
      final data = DataService('u1', firestore: FakeFirebaseFirestore());
      await _open(tester, _fromBook, data: data);

      await tester.ensureVisible(find.text('I cooked this'));
      await tester.tap(find.text('I cooked this'));
      await tester.pumpAndSettle();

      expect(find.text("Log today's dish"), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Chicken Pulao'), findsOneWidget);
    });
  });
}
