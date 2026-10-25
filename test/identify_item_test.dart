import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

String _items(List<String> items) => '{"items":[${items.join(',')}]}';

void main() {
  group('parseIdentifiedItems', () {
    test('finds every item in a photo, in order', () {
      final found = parseIdentifiedItems(_items([
        '{"name":"Olpers Milk","amount":1,"unit":"L"}',
        '{"name":"Shan Chaat Masala","amount":1,"unit":"packs"}',
        '{"name":"National Chaat Masala","amount":1,"unit":"packs"}',
      ]));
      expect(found.map((i) => i.name), ['Olpers Milk', 'Shan Chaat Masala', 'National Chaat Masala']);
      expect(found[0].amount, 1);
      expect(found[0].unit, 'L');
      expect(found[1].unit, 'packs');
    });

    test('keeps the brand in the name', () {
      final found = parseIdentifiedItems(_items(['{"name":"Shan Chaat Masala","amount":1,"unit":"packs"}']));
      expect(found.single.name, 'Shan Chaat Masala');
    });

    test('other spellings of a unit are understood', () {
      for (final entry in {
        'litre': 'L', 'Liters': 'L', 'kilogram': 'kg', 'grams': 'g', 'gm': 'g',
        'millilitres': 'ml', 'packet': 'packs', 'pcs': 'pieces',
      }.entries) {
        expect(normalizeUnit(entry.key), entry.value, reason: entry.key);
      }
    });

    test('no quantity visible gives the name only', () {
      final found = parseIdentifiedItems(_items(['{"name":"Chicken","amount":null,"unit":null}']));
      expect(found.single.amount, isNull);
      expect(found.single.unit, isNull);
      expect(parseIdentifiedItems(_items(['{"name":"Chicken"}'])).single.amount, isNull);
    });

    test('an amount without a known unit is not used, so nothing wrong is filled in', () {
      expect(parseIdentifiedItems(_items(['{"name":"Rice","amount":5,"unit":"bags"}'])).single.amount, isNull);
      expect(parseIdentifiedItems(_items(['{"name":"Rice","amount":5}'])).single.amount, isNull);
    });

    test('nonsense amounts are not used', () {
      for (final amount in ['0', '-2', '999999', '"lots"']) {
        final found = parseIdentifiedItems(_items(['{"name":"Rice","amount":$amount,"unit":"kg"}']));
        expect(found.single.amount, isNull, reason: amount);
        expect(found.single.name, 'Rice');
      }
    });

    test('items it could not name are dropped, the rest are kept', () {
      final found = parseIdentifiedItems(_items([
        '{"name":"unknown","amount":1,"unit":"kg"}',
        '{"name":"Rice","amount":2,"unit":"kg"}',
        '{"name":"","amount":1,"unit":"kg"}',
      ]));
      expect(found.map((i) => i.name), ['Rice']);
    });

    test('the same item listed twice appears once', () {
      final found = parseIdentifiedItems(_items([
        '{"name":"Onions","amount":1,"unit":"kg"}',
        '{"name":"onions","amount":1,"unit":"kg"}',
      ]));
      expect(found, hasLength(1));
    });

    test('no more than 12 items', () {
      final many = _items([for (var i = 0; i < 30; i++) '{"name":"Item $i"}']);
      expect(parseIdentifiedItems(many), hasLength(12));
    });

    test('an empty list means it could not tell', () {
      expect(parseIdentifiedItems('{"items":[]}'), isEmpty);
    });

    test('tidies spaces and quotes, and shortens very long names', () {
      expect(parseIdentifiedItems(_items(['{"name":"  \\"Onions\\"  "}'])).single.name, 'Onions');
      final long = parseIdentifiedItems(_items(['{"name":"${'a' * 200}"}']));
      expect(long.single.name.length, lessThanOrEqualTo(40));
    });

    test('a broken reply gives a kind message', () {
      expect(() => parseIdentifiedItems('not json'), throwsA(isA<GeminiException>()));
      expect(() => parseIdentifiedItems('{"items":5}'), throwsA(isA<GeminiException>()));
      expect(() => parseIdentifiedItems('{"name":"Rice"}'), throwsA(isA<GeminiException>()));
    });
  });

  group('identifyItems', () {
    test('sends the photo and returns everything found', () async {
      Uint8List? sentBytes;
      String? sentMime;
      final service = GeminiService(generateImage: (prompt, schema, bytes, mime) async {
        sentBytes = bytes;
        sentMime = mime;
        return _items([
          '{"name":"Olpers Milk","amount":1,"unit":"litre"}',
          '{"name":"Eggs","amount":12,"unit":"pcs"}',
        ]);
      });
      final found = await service.identifyItems(Uint8List.fromList([1, 2, 3]), 'image/jpeg');
      expect(found.map((i) => i.name), ['Olpers Milk', 'Eggs']);
      expect(found[0].unit, 'L');
      expect(found[1].unit, 'pieces');
      expect(sentBytes, [1, 2, 3]);
      expect(sentMime, 'image/jpeg');
    });

    test('the prompt asks for every item, the brand, the quantity, and packs for masalas', () {
      final prompt = buildIdentifyPrompt();
      expect(prompt, contains('every different grocery item'));
      expect(prompt, contains('brand'));
      expect(prompt, contains('Shan Chaat Masala'));
      expect(prompt, contains('packs'));
      expect(prompt, contains('1 L'));
    });

    test('photo models are listed, the Lite one first', () {
      expect(geminiImageModels.first, 'gemini-3.5-flash-lite');
      expect(geminiImageModels.length, greaterThan(1));
    });
  });
}
