import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/days_left.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/services/data_service.dart';

InventoryItem _item(String name, double amount, String unit) =>
    InventoryItem(id: name, name: name, amount: amount, unit: unit);

void main() {
  lowStockTests();
  group('sameDayNextMonth', () {
    test('shopping on the 28th means the 28th of next month', () {
      expect(sameDayNextMonth(DateTime(2026, 11, 28)), DateTime(2026, 12, 28));
    });

    test('December rolls into January of the next year', () {
      expect(sameDayNextMonth(DateTime(2026, 12, 15)), DateTime(2027, 1, 15));
    });

    test('a day that does not exist next month becomes its last day', () {
      expect(sameDayNextMonth(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(sameDayNextMonth(DateTime(2028, 1, 31)), DateTime(2028, 2, 29)); // leap year
      expect(sameDayNextMonth(DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
    });
  });

  group('daysUntil', () {
    test('counts whole days, 0 on the day itself, negative after it', () {
      expect(daysUntil(DateTime(2026, 11, 28), DateTime(2026, 12, 28)), 30);
      expect(daysUntil(DateTime(2026, 11, 28), DateTime(2026, 11, 28)), 0);
      expect(daysUntil(DateTime(2026, 11, 28), DateTime(2026, 11, 27)), -1);
    });

    test('the time of day does not change the answer', () {
      expect(daysUntil(DateTime(2026, 11, 28, 23, 59), DateTime(2026, 11, 29, 0, 1)), 1);
    });

    test('a clock change does not shift the count', () {
      expect(daysUntil(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    });
  });

  group('totals', () {
    test('adds up per unit and never mixes units', () {
      final totals = totalsByUnit([
        _item('Chicken', 1, 'kg'),
        _item('Rice', 2.5, 'kg'),
        _item('Eggs', 12, 'pieces'),
      ]);
      expect(totals, {'kg': 3.5, 'pieces': 12});
      expect(describeTotals(totals), '3.5 kg, 12 pieces');
    });

    test('nothing left gives an empty total', () {
      expect(describeTotals(totalsByUnit([])), '');
    });
  });

  group('typing amounts', () {
    test('accepts dots and commas', () {
      expect(parseAmount('1.5'), 1.5);
      expect(parseAmount('1,5'), 1.5);
      expect(parseAmount(' 2 '), 2);
    });

    test('rejects blank, words, zero and negative numbers', () {
      for (final bad in ['', 'abc', '0', '-1', '1e999']) {
        expect(parseAmount(bad), isNull, reason: bad);
      }
    });

    test('shows amounts without extra zeros', () {
      expect(formatAmount(2), '2');
      expect(formatAmount(1.5), '1.5');
      expect(formatAmount(1.1), '1.1');
      expect(formatAmount(0.333), '0.33');
    });
  });

  group('dates as text', () {
    test('survive a round trip', () {
      expect(dateToKey(DateTime(2026, 11, 8)), '2026-11-08');
      expect(dateFromKey('2026-11-08'), DateTime(2026, 11, 8));
    });

    test('bad text gives null instead of crashing', () {
      expect(dateFromKey(null), isNull);
      expect(dateFromKey('soon'), isNull);
      expect(dateFromKey('2026-xx-08'), isNull);
    });
  });

  group('dashboard sentence', () {
    final today = DateTime(2026, 11, 28);
    test('says how many days are left', () {
      expect(daysUntilMessage(today, DateTime(2026, 12, 28)), '30 days until your next shopping (28 Dec).');
      expect(daysUntilMessage(today, DateTime(2026, 11, 29)), '1 day until your next shopping (29 Nov).');
    });

    test('handles today, a passed date and no date', () {
      expect(daysUntilMessage(today, today), 'Shopping day is today (28 Nov).');
      expect(daysUntilMessage(today, DateTime(2026, 11, 20)), contains('has passed'));
      expect(daysUntilMessage(today, null), contains('Set your next shopping date'));
    });
  });

  group('one document per item', () {
    test('the same item always lands in the same place', () {
      expect(itemIdFor('Chicken ', 'kg'), itemIdFor('chicken', 'kg'));
    });

    test('a different unit is a different item', () {
      expect(itemIdFor('Milk', 'L'), isNot(itemIdFor('Milk', 'packs')));
    });

    test('works for any language and is safe as a document name', () {
      final id = itemIdFor('مرغی', 'kg');
      expect(id, isNotEmpty);
      expect(id.contains('/'), isFalse);
    });
  });
}

void lowStockTests() {
  group('isLowStock', () {
    InventoryItem item(double amount, String unit) =>
        InventoryItem(id: 'x', name: 'x', amount: amount, unit: unit);

    test('kg and L are low at 1 or less', () {
      expect(isLowStock(item(1, 'kg')), isTrue);
      expect(isLowStock(item(1.5, 'kg')), isFalse);
      expect(isLowStock(item(0.5, 'L')), isTrue);
    });
    test('g and ml are low at 250 or less', () {
      expect(isLowStock(item(250, 'g')), isTrue);
      expect(isLowStock(item(500, 'ml')), isFalse);
    });
    test('pieces and packs are low at 2 or less', () {
      expect(isLowStock(item(2, 'pieces')), isTrue);
      expect(isLowStock(item(3, 'packs')), isFalse);
    });
  });
}
