import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/item_matching.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/screens/add_groceries_screen.dart';
import 'package:what_can_i_cook/services/data_service.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';
import 'package:what_can_i_cook/services/photo_picker.dart';

import 'helpers/test_app.dart';

/// Stands in for Firestore: remembers what was added.
class _FakeData extends DataService {
  _FakeData() : super('test-user');

  final added = <({String name, double amount, String unit})>[];

  // Like a Firestore feed: every new listener gets the current list, even after a scroll.
  @override
  Stream<List<InventoryItem>> inventory() =>
      Stream<List<InventoryItem>>.multi((c) => c.add(const <InventoryItem>[]));

  @override
  Stream<ShoppingDates> shoppingDates() =>
      Stream<ShoppingDates>.multi((c) => c.add(const ShoppingDates()));

  /// What she already has, so a second pack can be matched to it like the real thing does.
  List<InventoryItem> existing = [];

  @override
  Future<List<AddResult>> addItems(List<NewItem> items) async {
    for (final i in items) {
      added.add((name: i.name, amount: i.amount, unit: i.unit));
    }
    return planAdds(existing, items);
  }

  @override
  Future<void> saveShoppingDates({required DateTime last, required DateTime next}) async {}
}

// A real 1x1 picture, so the thumbnail can be drawn.
final _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

String _found(List<String> items) => '{"items":[${items.join(',')}]}';

const _milk = '{"name":"Olpers Milk","amount":1,"unit":"L"}';
const _shan = '{"name":"Shan Chaat Masala","amount":1,"unit":"packs"}';
const _national = '{"name":"National Chaat Masala","amount":1,"unit":"packs"}';

Future<_FakeData> _open(
  WidgetTester tester, {
  PhotoPicker? pickPhoto,
  GenerateImage? generateImage,
}) async {
  tester.view.physicalSize = const Size(900, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final data = _FakeData();
  await tester.pumpWidget(testApp(AddGroceriesScreen(
    data: data,
    pickPhoto: pickPhoto ?? (_) async => PickedPhoto(Uint8List.fromList(_tinyPng), 'image/png'),
    gemini: GeminiService(
      generateImage: generateImage ?? (_, _, _, _) async => _found([_milk]),
    ),
  )));
  await tester.pumpAndSettle();
  return data;
}

Future<void> _takePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();
}

Future<void> _saveAll(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Types an item through "Type it in".
Future<void> _typeItem(WidgetTester tester, String name, String amount) async {
  await tester.tap(find.text('Type it in'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('line-name')), name);
  await tester.enterText(find.byKey(const Key('line-amount')), amount);
  await tester.tap(find.text('Add to list'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a photo of one item puts it on the list with the amount filled in', (tester) async {
    String? sentMime;
    await _open(tester, generateImage: (prompt, _, bytes, mime) async {
      sentMime = mime;
      expect(bytes, isNotEmpty);
      return _found([_milk]);
    });

    await _takePhoto(tester);

    expect(find.text('We found 1 item in your photo.'), findsOneWidget);
    expect(find.text('Olpers Milk'), findsOneWidget);
    expect(find.text('1 L'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Save 1 item'), findsOneWidget);
    expect(sentMime, 'image/png');
  });

  testWidgets('a photo with several items lists every one, and saves them all at once', (tester) async {
    final data = await _open(
      tester,
      generateImage: (_, _, _, _) async => _found([_milk, _shan, _national]),
    );

    await _takePhoto(tester);

    expect(find.text('We found 3 items in your photo.'), findsOneWidget);
    expect(find.text('Olpers Milk'), findsOneWidget);
    expect(find.text('Shan Chaat Masala'), findsOneWidget);
    expect(find.text('National Chaat Masala'), findsOneWidget);
    expect(find.text('Save all 3 items'), findsOneWidget);

    await _saveAll(tester, 'Save all 3 items');

    expect(data.added, [
      (name: 'Olpers Milk', amount: 1.0, unit: 'L'),
      (name: 'Shan Chaat Masala', amount: 1.0, unit: 'packs'),
      (name: 'National Chaat Masala', amount: 1.0, unit: 'packs'),
    ]);
    expect(find.text('Save all 3 items'), findsNothing); // the list is cleared for next time
    expect(find.text('Olpers Milk'), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('the plus and minus buttons change the amount that is saved', (tester) async {
    final data = await _open(tester, generateImage: (_, _, _, _) async => _found([_milk]));
    await _takePhoto(tester);

    await tester.tap(find.byTooltip('More Olpers Milk'));
    await tester.pump();
    expect(find.text('1.5 L'), findsOneWidget);

    await _saveAll(tester, 'Save 1 item');
    expect(data.added.single.amount, 1.5);
  });

  testWidgets('when the amount is not visible the card says so and she must fix it before saving',
      (tester) async {
    final data = await _open(tester, generateImage: (_, _, _, _) async => _found(['{"name":"Chicken"}']));
    await _takePhoto(tester);

    expect(find.text('We found 1 item in your photo. 1 needs a check.'), findsOneWidget);
    expect(find.text('Amount unclear. Tap to fix.'), findsOneWidget);

    await _saveAll(tester, 'Save 1 item');
    expect(find.textContaining('Please say how much Chicken'), findsOneWidget);
    expect(data.added, isEmpty);

    await tester.tap(find.text('Chicken'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('line-amount')), '1');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Amount unclear. Tap to fix.'), findsNothing);

    await _saveAll(tester, 'Save 1 item');
    expect(data.added.single.name, 'Chicken');
    expect(data.added.single.amount, 1);
  });

  testWidgets('names, amounts and units can be corrected before saving', (tester) async {
    final data = await _open(tester, generateImage: (_, _, _, _) async => _found([_milk]));
    await _takePhoto(tester);

    await tester.tap(find.text('Olpers Milk'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('line-name')), 'Haleeb Milk');
    await tester.enterText(find.byKey(const Key('line-amount')), '2,5');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await _saveAll(tester, 'Save 1 item');
    expect(data.added, [(name: 'Haleeb Milk', amount: 2.5, unit: 'L')]);
  });

  testWidgets('an item can be removed from the list and is then not saved', (tester) async {
    final data = await _open(
      tester,
      generateImage: (_, _, _, _) async => _found([_milk, _shan, _national]),
    );
    await _takePhoto(tester);

    await tester.tap(find.text('Shan Chaat Masala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from list'));
    await tester.pumpAndSettle();
    expect(find.text('Save all 2 items'), findsOneWidget);

    await _saveAll(tester, 'Save all 2 items');
    expect(data.added.map((i) => i.name), ['Olpers Milk', 'National Chaat Masala']);
  });

  testWidgets('typing an item adds it to the list, and Save puts it in the kitchen', (tester) async {
    final data = await _open(tester);

    await _typeItem(tester, 'Rice', '5');
    expect(find.text('Rice'), findsOneWidget);
    expect(data.added, isEmpty); // nothing is saved until she says so

    await _saveAll(tester, 'Save 1 item');
    expect(data.added.single.name, 'Rice');
    expect(data.added.single.amount, 5);
  });

  testWidgets('typing needs a name and an amount, and says what is missing', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Type it in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to list'));
    await tester.pump();
    expect(find.textContaining('Please type what you bought'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('line-name')), 'Rice');
    await tester.tap(find.text('Add to list'));
    await tester.pump();
    expect(find.textContaining('Please type how much'), findsOneWidget);
  });

  testWidgets('the often-bought chips add a starting amount to the list', (tester) async {
    final data = await _open(tester);

    await tester.tap(find.widgetWithText(ActionChip, 'Milk'));
    await tester.pump();
    expect(find.text('Save 1 item'), findsOneWidget);

    await _saveAll(tester, 'Save 1 item');
    expect(data.added.single, (name: 'Milk', amount: 1.0, unit: 'L'));
  });

  testWidgets('with nothing on the list there is no Save button', (tester) async {
    await _open(tester);

    expect(find.textContaining('Save'), findsNothing);
  });

  testWidgets('when Gemini cannot tell, she is asked to type it', (tester) async {
    await _open(tester, generateImage: (_, _, _, _) async => _found([]));

    await _takePhoto(tester);

    expect(find.textContaining('I could not tell what this is'), findsOneWidget);
    expect(find.textContaining('Save'), findsNothing);
  });

  testWidgets('when the photo cannot be read at all, she is asked to type it', (tester) async {
    await _open(tester, generateImage: (_, _, _, _) async => throw GeminiException('busy'));

    await _takePhoto(tester);

    expect(find.textContaining('I could not read that photo'), findsOneWidget);
  });

  testWidgets('backing out of the camera changes nothing', (tester) async {
    await _open(tester, pickPhoto: (_) async => null);

    await _takePhoto(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('found'), findsNothing);
  });

  testWidgets('if the camera cannot open she is told, and can still type', (tester) async {
    final data = await _open(tester, pickPhoto: (_) async => throw Exception('no camera'));

    await _takePhoto(tester);

    expect(find.textContaining('Could not open the photos'), findsOneWidget);
    await _typeItem(tester, 'Rice', '5');
    await _saveAll(tester, 'Save 1 item');
    expect(data.added.single.name, 'Rice');
  });

  testWidgets('a second pack of the same product raises the amount and says so', (tester) async {
    final data = await _open(
      tester,
      // Gemini spelled it differently this time.
      generateImage: (_, _, _, _) async =>
          _found(['{"name":"Shan Chat Masala","amount":1,"unit":"packs"}']),
    );
    data.existing = const [
      InventoryItem(id: 'shan', name: 'Shan Chaat Masala', amount: 1, unit: 'packs'),
    ];

    await _takePhoto(tester);
    await tester.tap(find.text('Save 1 item'));
    await tester.pump();

    expect(
      find.text('Shan Chaat Masala was already in your kitchen, so now you have 2 packs.'),
      findsOneWidget,
    );
  });

  testWidgets('a different brand is a new line, not added to the first', (tester) async {
    final data = await _open(
      tester,
      generateImage: (_, _, _, _) async => _found([_national]),
    );
    data.existing = const [
      InventoryItem(id: 'shan', name: 'Shan Chaat Masala', amount: 1, unit: 'packs'),
    ];

    await _takePhoto(tester);
    await tester.tap(find.text('Save 1 item'));
    await tester.pump();

    expect(find.text('Added National Chaat Masala, 1 packs.'), findsOneWidget);
  });

  testWidgets("a second photo replaces the first photo's items but keeps what she typed", (tester) async {
    var photos = 0;
    await _open(tester, generateImage: (_, _, _, _) async {
      photos++;
      return photos == 1 ? _found([_milk, _shan]) : _found([_national]);
    });

    await _typeItem(tester, 'Rice', '5');
    await _takePhoto(tester);
    expect(find.text('We found 2 items in your photo.'), findsOneWidget);
    expect(find.text('Save all 3 items'), findsOneWidget);
    await _takePhoto(tester);

    expect(find.text('We found 1 item in your photo.'), findsOneWidget);
    expect(find.text('National Chaat Masala'), findsOneWidget);
    expect(find.text('Olpers Milk'), findsNothing);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Save all 2 items'), findsOneWidget);
  });
}
