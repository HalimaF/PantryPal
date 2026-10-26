import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/models/meal.dart';
import 'package:what_can_i_cook/screens/log_dish_screen.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';
import 'package:what_can_i_cook/services/photo_picker.dart';
import 'package:what_can_i_cook/theme.dart';

const _stock = [
  InventoryItem(id: 'rice', name: 'Rice', amount: 5, unit: 'kg'),
  InventoryItem(id: 'chicken', name: 'Chicken', amount: 1.5, unit: 'kg'),
  InventoryItem(id: 'eggs', name: 'Eggs', amount: 12, unit: 'pieces'),
];

/// Opens the log screen and returns the list that every saved log lands in.
Future<List<LogMealRequest>> _open(
  WidgetTester tester, {
  Future<List<InventoryItem>>? stock,
  String dishName = '',
  List<String> dishIngredients = const [],
  Future<void> Function(LogMealRequest)? onSave,
  GenerateImage? generateImage,
  PhotoPicker? pickPhoto,
  bool settle = true, // a spinner never finishes animating, so some tests step time by hand
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saved = <LogMealRequest>[];
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => LogDishScreen(
                stock: stock ?? Future.value(_stock),
                onSave: onSave ?? (r) async => saved.add(r),
                dishName: dishName,
                dishIngredients: dishIngredients,
                pickPhoto: pickPhoto ?? (_) async => PickedPhoto(Uint8List.fromList([1, 2, 3]), 'image/jpeg'),
                gemini: GeminiService(
                  generateImage: generateImage ?? (_, _, _, _) async => '{"used":[]}',
                ),
              ),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(); // start the page change
    await tester.pump(const Duration(milliseconds: 400)); // finish it
  }
  return saved;
}

void main() {
  testWidgets('things in the dish come first and are marked', (tester) async {
    await _open(tester, dishName: 'Chicken Pulao', dishIngredients: ['chicken', 'basmati rice']);

    expect(find.text('Chicken Pulao'), findsOneWidget); // prefilled name
    expect(find.text('1.5 kg left · in this dish'), findsOneWidget);
    expect(find.text('5 kg left · in this dish'), findsOneWidget); // rice matches basmati rice
    expect(find.text('12 pieces left'), findsOneWidget); // eggs: not in this dish

    final chickenAt = tester.getTopLeft(find.text('Chicken')).dy;
    final eggsAt = tester.getTopLeft(find.text('Eggs')).dy;
    expect(chickenAt, lessThan(eggsAt));
  });

  testWidgets('saving hands over only what was used', (tester) async {
    final saved = await _open(tester, dishName: 'Chicken Pulao');

    final fields = find.byType(TextField);
    // name, then one amount box per item in the order shown: Chicken, Eggs, Rice
    await tester.enterText(fields.at(1), '0,5'); // Chicken, comma accepted
    await tester.enterText(fields.at(3), '1'); // Rice
    await tester.tap(find.text('Save to my log'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.dishName, 'Chicken Pulao');
    expect(saved.single.slot, 'Dinner');
    final byName = {for (final u in saved.single.used) u.name: u};
    expect(byName.keys, unorderedEquals(['Chicken', 'Rice']));
    expect(byName['Chicken']!.amount, 0.5);
    expect(byName['Chicken']!.left, 1.5);
    expect(byName['Rice']!.amount, 1);
    expect(find.text('Save to my log'), findsNothing); // went back
  });

  testWidgets('a dish with no name is not saved', (tester) async {
    final saved = await _open(tester);

    await tester.tap(find.text('Save to my log'));
    await tester.pump();

    expect(find.text('Please type the name of the dish you cooked.'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('an amount that is not a number is explained, not saved', (tester) async {
    final saved = await _open(tester, dishName: 'Daal');

    await tester.enterText(find.byType(TextField).at(1), 'lots');
    await tester.tap(find.text('Save to my log'));
    await tester.pump();

    expect(find.textContaining('Please check the amount for Chicken'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('with no groceries she can still log the dish', (tester) async {
    final saved = await _open(tester, stock: Future.value(const <InventoryItem>[]), dishName: 'Daal');

    expect(find.textContaining('You have no groceries saved'), findsOneWidget);
    await tester.tap(find.text('Save to my log'));
    await tester.pumpAndSettle();

    expect(saved.single.used, isEmpty);
  });

  testWidgets('if saving fails she sees a kind message and stays', (tester) async {
    await _open(tester, dishName: 'Daal', onSave: (_) async => throw Exception('denied'));

    await tester.tap(find.text('Save to my log'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('Save to my log'), findsOneWidget);
  });

  testWidgets('if the groceries never arrive she is not stuck', (tester) async {
    await _open(tester,
        stock: Completer<List<InventoryItem>>().future, dishName: 'Daal', settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.textContaining('You have no groceries saved'), findsOneWidget);
  });

  testWidgets('a photo of the dish fills in a guess, which she can still change', (tester) async {
    final saved = await _open(
      tester,
      dishName: 'Chicken Pulao',
      generateImage: (prompt, _, _, _) async {
        expect(prompt, contains('Chicken Pulao'));
        return '{"used":[{"name":"Chicken","amount":0.75},{"name":"Rice","amount":1}]}';
      },
    );

    await tester.tap(find.text('Photo of the dish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('I guessed these amounts from your photo'), findsOneWidget);
    final fields = find.byType(TextField);
    // name, then Chicken, Eggs, Rice
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, '0.75');
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, isEmpty);
    expect(tester.widget<TextField>(fields.at(3)).controller!.text, '1');

    await tester.enterText(fields.at(1), '0.5'); // she corrects the chicken
    await tester.ensureVisible(find.text('Save to my log'));
    await tester.tap(find.text('Save to my log'));
    await tester.pumpAndSettle();

    final byName = {for (final u in saved.single.used) u.name: u.amount};
    expect(byName, {'Chicken': 0.5, 'Rice': 1.0});
  });

  testWidgets('when the amounts cannot be worked out, she is asked to type them', (tester) async {
    await _open(tester, dishName: 'Daal');

    await tester.tap(find.text('Photo of the dish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('I could not work out the amounts'), findsOneWidget);
  });

  testWidgets('when the photo cannot be read at all, she is asked to type the amounts', (tester) async {
    await _open(
      tester,
      dishName: 'Daal',
      generateImage: (_, _, _, _) async => throw GeminiException('busy'),
    );

    await tester.tap(find.text('Photo of the dish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('I could not read that photo'), findsOneWidget);
  });

  testWidgets('backing out of the camera changes nothing', (tester) async {
    await _open(tester, dishName: 'Daal', pickPhoto: (_) async => null);

    await tester.tap(find.text('Photo of the dish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('I guessed'), findsNothing);
    expect(find.textContaining('I could not'), findsNothing);
  });

  testWidgets('no photo buttons when there are no groceries to estimate', (tester) async {
    await _open(tester, stock: Future.value(const <InventoryItem>[]), dishName: 'Daal');

    expect(find.text('Photo of the dish'), findsNothing);
  });
}
