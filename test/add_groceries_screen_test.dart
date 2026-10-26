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
import 'package:what_can_i_cook/theme.dart';

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
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: AddGroceriesScreen(
      data: data,
      pickPhoto: pickPhoto ?? (_) async => PickedPhoto(Uint8List.fromList(_tinyPng), 'image/png'),
      gemini: GeminiService(
        generateImage: generateImage ?? (_, _, _, _) async => _found([_milk]),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return data;
}

Future<void> _takePhoto(WidgetTester tester) async {
  await tester.tap(find.text('Take a photo'));
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!.text;

Finder get _manualName => find.widgetWithText(TextField, 'Item').first;

void main() {
  testWidgets('a photo of one item shows it for checking, with the amount filled in', (tester) async {
    String? sentMime;
    await _open(tester, generateImage: (prompt, _, bytes, mime) async {
      sentMime = mime;
      expect(bytes, isNotEmpty);
      return _found([_milk]);
    });

    await _takePhoto(tester);

    expect(find.text('Found in your photo'), findsOneWidget);
    expect(find.text('I found 1 item. Please check it.'), findsOneWidget);
    expect(_text(tester, const Key('detected-name-0')), 'Olpers Milk');
    expect(_text(tester, const Key('detected-amount-0')), '1');
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Add 1 item'), findsOneWidget);
    expect(sentMime, 'image/png');
  });

  testWidgets('a photo with several items lists every one, and adds them all at once', (tester) async {
    final data = await _open(
      tester,
      generateImage: (_, _, _, _) async => _found([_milk, _shan, _national]),
    );

    await _takePhoto(tester);

    expect(find.text('I found 3 items. Please check them.'), findsOneWidget);
    expect(_text(tester, const Key('detected-name-0')), 'Olpers Milk');
    expect(_text(tester, const Key('detected-name-1')), 'Shan Chaat Masala');
    expect(_text(tester, const Key('detected-name-2')), 'National Chaat Masala');
    expect(find.text('Add 3 items'), findsOneWidget);

    await tester.ensureVisible(find.text('Add 3 items'));
    await tester.tap(find.text('Add 3 items'));
    await tester.pumpAndSettle();

    expect(data.added, [
      (name: 'Olpers Milk', amount: 1.0, unit: 'L'),
      (name: 'Shan Chaat Masala', amount: 1.0, unit: 'packs'),
      (name: 'National Chaat Masala', amount: 1.0, unit: 'packs'),
    ]);
    expect(find.text('Found in your photo'), findsNothing); // cleared for the next photo
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an item can be unticked and is then not added', (tester) async {
    final data = await _open(
      tester,
      generateImage: (_, _, _, _) async => _found([_milk, _shan, _national]),
    );
    await _takePhoto(tester);

    await tester.ensureVisible(find.byKey(const Key('detected-include-1')));
    await tester.tap(find.byKey(const Key('detected-include-1')));
    await tester.pump();
    expect(find.text('Add 2 items'), findsOneWidget);

    await tester.ensureVisible(find.text('Add 2 items'));
    await tester.tap(find.text('Add 2 items'));
    await tester.pumpAndSettle();

    expect(data.added.map((i) => i.name), ['Olpers Milk', 'National Chaat Masala']);
  });

  testWidgets('names, amounts and units can be corrected before adding', (tester) async {
    final data = await _open(tester, generateImage: (_, _, _, _) async => _found([_milk]));
    await _takePhoto(tester);

    await tester.enterText(find.byKey(const Key('detected-name-0')), 'Haleeb Milk');
    await tester.enterText(find.byKey(const Key('detected-amount-0')), '2,5');
    await tester.ensureVisible(find.text('Add 1 item'));
    await tester.tap(find.text('Add 1 item'));
    await tester.pumpAndSettle();

    expect(data.added, [(name: 'Haleeb Milk', amount: 2.5, unit: 'L')]);
  });

  testWidgets('when the amount is not visible she must type it before adding', (tester) async {
    final data = await _open(tester, generateImage: (_, _, _, _) async => _found(['{"name":"Chicken"}']));
    await _takePhoto(tester);

    expect(_text(tester, const Key('detected-amount-0')), isEmpty);
    await tester.ensureVisible(find.text('Add 1 item'));
    await tester.tap(find.text('Add 1 item'));
    await tester.pump();

    expect(find.textContaining('Please type how much Chicken'), findsOneWidget);
    expect(data.added, isEmpty);

    await tester.enterText(find.byKey(const Key('detected-amount-0')), '1');
    await tester.tap(find.text('Add 1 item'));
    await tester.pumpAndSettle();
    expect(data.added.single.name, 'Chicken');
    expect(data.added.single.amount, 1);
  });

  testWidgets('every item unticked leaves nothing to add', (tester) async {
    await _open(tester, generateImage: (_, _, _, _) async => _found([_milk]));
    await _takePhoto(tester);

    await tester.ensureVisible(find.byKey(const Key('detected-include-0')));
    await tester.tap(find.byKey(const Key('detected-include-0')));
    await tester.pump();

    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Add 0 items'));
    expect(button.onPressed, isNull);
  });

  testWidgets('when Gemini cannot tell, she is asked to type it', (tester) async {
    await _open(tester, generateImage: (_, _, _, _) async => _found([]));

    await _takePhoto(tester);

    expect(find.textContaining('I could not tell what this is'), findsOneWidget);
    expect(find.text('Found in your photo'), findsNothing);
  });

  testWidgets('when the photo cannot be read at all, she is asked to type it', (tester) async {
    await _open(tester, generateImage: (_, _, _, _) async => throw GeminiException('busy'));

    await _takePhoto(tester);

    expect(find.textContaining('I could not read that photo'), findsOneWidget);
    expect(find.text('Found in your photo'), findsNothing);
  });

  testWidgets('backing out of the camera changes nothing', (tester) async {
    await _open(tester, pickPhoto: (_) async => null);

    await _takePhoto(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.text('Found in your photo'), findsNothing);
  });

  testWidgets('if the camera cannot open she is told, and can still type', (tester) async {
    final data = await _open(tester, pickPhoto: (_) async => throw Exception('no camera'));

    await _takePhoto(tester);

    expect(find.textContaining('Could not open the photos'), findsOneWidget);
    await tester.enterText(_manualName, 'Rice');
    await tester.enterText(find.widgetWithText(TextField, 'How much'), '5');
    await tester.ensureVisible(find.text('Add to my groceries'));
    await tester.tap(find.text('Add to my groceries'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Add 1 item'));
    await tester.tap(find.text('Add 1 item'));
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
    await tester.ensureVisible(find.text('Add 1 item'));
    await tester.tap(find.text('Add 1 item'));
    await tester.pump();

    expect(find.text('Added National Chaat Masala, 1 packs.'), findsOneWidget);
  });

  testWidgets('a second photo replaces the first list', (tester) async {
    var photos = 0;
    await _open(tester, generateImage: (_, _, _, _) async {
      photos++;
      return photos == 1 ? _found([_milk, _shan]) : _found([_national]);
    });

    await _takePhoto(tester);
    expect(find.text('I found 2 items. Please check them.'), findsOneWidget);
    await _takePhoto(tester);

    expect(find.text('I found 1 item. Please check it.'), findsOneWidget);
    expect(_text(tester, const Key('detected-name-0')), 'National Chaat Masala');
    expect(find.byKey(const Key('detected-name-1')), findsNothing);
  });
}
