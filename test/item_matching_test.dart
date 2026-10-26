import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/item_matching.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/services/data_service.dart';

InventoryItem _line(String id, String name, double amount, String unit) =>
    InventoryItem(id: id, name: name, amount: amount, unit: unit);

NewItem _new(String name, double amount, String unit) =>
    NewItem(name: name, amount: amount, unit: unit);

void main() {
  group('normalizeItemName', () {
    test('ignores capital letters, punctuation and word order', () {
      expect(normalizeItemName('Shan Chaat Masala'), normalizeItemName('masala, CHAAT shan!'));
    });

    test('treats chat and chaat as the same word', () {
      expect(normalizeItemName('Shan Chat Masala'), normalizeItemName('Shan Chaat Masala'));
    });

    test('ignores filler words and quantities that ended up in the name', () {
      final plain = normalizeItemName('Shan Chaat Masala');
      expect(normalizeItemName('Shan Chaat Masala Powder'), plain);
      expect(normalizeItemName('Shan Chaat Masala 50g'), plain);
      expect(normalizeItemName('Shan Chaat Masala (1 pack)'), plain);
      expect(normalizeItemName('Olpers Milk 1 L'), normalizeItemName('Olpers Milk'));
    });

    test('singular and plural match', () {
      expect(normalizeItemName('Onions'), normalizeItemName('onion'));
      expect(normalizeItemName('Tomatoes'), normalizeItemName('tomato'));
    });

    test('works for other languages', () {
      expect(normalizeItemName('مرغی'), isNotEmpty);
      expect(sameProduct('مرغی', 'مرغی'), isTrue);
    });
  });

  group('sameProduct', () {
    test('the same product spelled a little differently', () {
      expect(sameProduct('Shan Chaat Masala', 'Shan Chat Masala'), isTrue);
      expect(sameProduct('Shan Chaat Masala', 'shan chaat masala powder'), isTrue);
      expect(sameProduct('Basmati Rice', 'basmati rise'), isTrue); // one letter off
    });

    test('a different brand is a different product', () {
      expect(sameProduct('Shan Chaat Masala', 'National Chaat Masala'), isFalse);
    });

    test('a different product from the same brand is different', () {
      expect(sameProduct('Shan Chaat Masala', 'Shan Biryani Masala'), isFalse);
    });

    test('short names must match exactly, so milk is never mild', () {
      expect(sameProduct('Milk', 'Mild'), isFalse);
      expect(sameProduct('Rice', 'Rich'), isFalse);
      expect(sameProduct('Milk', 'milk'), isTrue);
    });

    test('blank names never match', () {
      expect(sameProduct('', ''), isFalse);
      expect(sameProduct('1 kg', '2 kg'), isFalse);
    });
  });

  group('convertAmount', () {
    test('weight, volume and counts convert; other mixes do not', () {
      expect(convertAmount(500, 'g', 'kg'), 0.5);
      expect(convertAmount(2, 'kg', 'g'), 2000);
      expect(convertAmount(250, 'ml', 'L'), 0.25);
      expect(convertAmount(1, 'L', 'ml'), 1000);
      expect(convertAmount(3, 'packs', 'pieces'), 3);
      expect(convertAmount(3, 'kg', 'kg'), 3);
      expect(convertAmount(1, 'kg', 'L'), isNull);
      expect(convertAmount(1, 'g', 'pieces'), isNull);
    });
  });

  group('planAdds', () {
    test('a second pack of the same product raises the first, not a new line', () {
      final plan = planAdds(
        [_line('shan', 'Shan Chaat Masala', 1, 'packs')],
        [_new('Shan Chat Masala', 1, 'packs')],
      );
      expect(plan.single.merged, isTrue);
      expect(plan.single.docId, 'shan');
      expect(plan.single.name, 'Shan Chaat Masala'); // keeps the name she already has
      expect(plan.single.newTotal, 2);
    });

    test('pack and piece are the same thing for a counted item', () {
      final plan = planAdds(
        [_line('shan', 'Shan Chaat Masala', 1, 'packs')],
        [_new('Shan Chaat Masala', 1, 'pieces')],
      );
      expect(plan.single.merged, isTrue);
      expect(plan.single.unit, 'packs');
      expect(plan.single.newTotal, 2);
    });

    test('grams are added to kilograms', () {
      final plan = planAdds([_line('rice', 'Basmati Rice', 1, 'kg')], [_new('Basmati Rice', 500, 'g')]);
      expect(plan.single.newTotal, 1.5);
      expect(plan.single.unit, 'kg');
    });

    test('a different brand becomes its own line', () {
      final plan = planAdds(
        [_line('shan', 'Shan Chaat Masala', 1, 'packs')],
        [_new('National Chaat Masala', 1, 'packs')],
      );
      expect(plan.single.merged, isFalse);
      expect(plan.single.name, 'National Chaat Masala');
    });

    test('the same name in an unrelated unit is not mixed up', () {
      final plan = planAdds([_line('milk', 'Milk', 1, 'L')], [_new('Milk', 2, 'kg')]);
      expect(plan.single.merged, isFalse);
    });

    test('two photos of one product in the same go become one line', () {
      final plan = planAdds(const [], [
        _new('Shan Chaat Masala', 1, 'packs'),
        _new('Shan Chat Masala', 1, 'packs'),
      ]);
      expect(plan[0].merged, isFalse);
      expect(plan[1].merged, isTrue);
      expect(plan[1].docId, plan[0].docId);
      expect(plan[1].newTotal, 2);
    });

    test('a new item with nothing to match gets its own line, the same each time', () {
      final plan = planAdds(const [], [_new('Chicken', 1, 'kg')]);
      expect(plan.single.merged, isFalse);
      expect(plan.single.docId, itemIdFor('Chicken', 'kg'));
      expect(plan.single.newTotal, 1);
    });

    test('exact same name and unit still merges', () {
      final id = itemIdFor('Chicken', 'kg');
      final plan = planAdds([_line(id, 'Chicken', 1.5, 'kg')], [_new('chicken', 0.5, 'kg')]);
      expect(plan.single.merged, isTrue);
      expect(plan.single.newTotal, 2);
    });
  });
}
