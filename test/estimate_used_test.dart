import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

const _stock = [
  InventoryItem(id: 'chicken', name: 'Chicken', amount: 1.5, unit: 'kg'),
  InventoryItem(id: 'rice', name: 'Basmati Rice', amount: 5, unit: 'kg'),
  InventoryItem(id: 'eggs', name: 'Eggs', amount: 12, unit: 'pieces'),
];

String _used(List<String> items) => '{"used":[${items.join(',')}]}';

void main() {
  group('parseUsedEstimates', () {
    test('matches guesses to her groceries by name, ignoring capital letters', () {
      final found = parseUsedEstimates(
        _used(['{"name":"chicken","amount":0.5}', '{"name":"BASMATI RICE","amount":1}']),
        _stock,
      );
      expect(found.map((e) => e.itemId), ['chicken', 'rice']);
      expect(found.map((e) => e.amount), [0.5, 1.0]);
    });

    test('never more than what is left', () {
      final found = parseUsedEstimates(_used(['{"name":"Chicken","amount":9}']), _stock);
      expect(found.single.amount, 1.5);
    });

    test('things she does not have are ignored', () {
      final found = parseUsedEstimates(
        _used(['{"name":"Saffron","amount":1}', '{"name":"Eggs","amount":3}']),
        _stock,
      );
      expect(found.map((e) => e.itemId), ['eggs']);
    });

    test('zero, negative and non-number amounts are ignored', () {
      final found = parseUsedEstimates(
        _used([
          '{"name":"Chicken","amount":0}',
          '{"name":"Eggs","amount":-2}',
          '{"name":"Basmati Rice","amount":"lots"}',
        ]),
        _stock,
      );
      expect(found, isEmpty);
    });

    test('the same item twice counts once', () {
      final found = parseUsedEstimates(
        _used(['{"name":"Eggs","amount":2}', '{"name":"eggs","amount":4}']),
        _stock,
      );
      expect(found, hasLength(1));
      expect(found.single.amount, 2);
    });

    test('an empty list means it could not tell', () {
      expect(parseUsedEstimates('{"used":[]}', _stock), isEmpty);
    });

    test('a broken reply gives a kind message', () {
      expect(() => parseUsedEstimates('nonsense', _stock), throwsA(isA<GeminiException>()));
      expect(() => parseUsedEstimates('{"used":5}', _stock), throwsA(isA<GeminiException>()));
    });
  });

  group('estimateUsed', () {
    test('sends the photo, the dish and only her groceries', () async {
      String? sentPrompt;
      Uint8List? sentBytes;
      final service = GeminiService(generateImage: (prompt, schema, bytes, mime) async {
        sentPrompt = prompt;
        sentBytes = bytes;
        return _used(['{"name":"Chicken","amount":0.75}']);
      });

      final found = await service.estimateUsed(
        Uint8List.fromList([9, 8]),
        'image/jpeg',
        dishName: 'Chicken Pulao',
        stock: _stock,
      );

      expect(found.single.itemId, 'chicken');
      expect(found.single.amount, 0.75);
      expect(sentBytes, [9, 8]);
      expect(sentPrompt, contains('Chicken Pulao'));
      expect(sentPrompt, contains('Chicken (1.5 kg left)'));
      expect(sentPrompt, contains('Basmati Rice (5 kg left)'));
      expect(sentPrompt, contains('Eggs (12 pieces left)'));
      expect(sentPrompt, contains('Never give more than what is left'));
    });

    test('works without a dish name', () {
      expect(buildEstimatePrompt('  ', _stock), contains('a home-cooked dish'));
    });
  });
}
