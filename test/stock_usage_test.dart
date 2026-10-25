import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/stock_usage.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/models/meal.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

UsedAmount _used(String id, double amount, double left, {String unit = 'kg'}) =>
    UsedAmount(id: id, name: id, unit: unit, amount: amount, left: left);

void main() {
  group('remainingAfter', () {
    test('takes the used amount out of what was left', () {
      expect(remainingAfter([_used('chicken', 0.5, 1.5)]), {'chicken': 1.0});
    });

    test('never goes below zero', () {
      expect(remainingAfter([_used('chicken', 2, 1)]), {'chicken': 0});
    });

    test('items that were not used, or left blank, are not touched', () {
      expect(remainingAfter([_used('rice', 0, 5), _used('chicken', 1, 3)]), {'chicken': 2});
    });

    test('the same item listed twice comes out once, adding up', () {
      expect(remainingAfter([_used('rice', 1, 5), _used('rice', 1, 5)]), {'rice': 3});
    });

    test('using everything counts as finished', () {
      final left = remainingAfter([_used('eggs', 12, 12, unit: 'pieces')])['eggs']!;
      expect(isFinished(left), isTrue);
      expect(isFinished(0.0000001), isTrue);
      expect(isFinished(0.5), isFalse);
    });

    test('nothing used changes nothing', () {
      expect(remainingAfter([]), isEmpty);
    });
  });

  group('not repeating dishes', () {
    const csv =
        'name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps\n'
        'Chicken Pulao,Pakistani,both,medium,rice,chicken; rice,mild,yes,Chicken 1 kg,Cook\n'
        'Chicken Biryani,Pakistani,both,medium,rice,chicken; rice; onion,hot,no,Chicken 1 kg,Cook\n';
    const request = SuggestRequest(
      meal: 'Dinner',
      weight: 'Light',
      base: 'Rice',
      ingredients: ['chicken', 'rice', 'onion'],
    );

    test('a dish eaten recently is skipped, whatever its capital letters', () {
      final book = DishDatabase(parseDishCsv(csv));
      final names = book.suggest(request, exclude: {'chicken pulao '}).map((d) => d.name);
      expect(names, ['Chicken Biryani']);
    });

    test('the cooking helper is told what the family ate recently', () {
      const withRecent = SuggestRequest(
        meal: 'Dinner',
        weight: 'Light',
        base: 'Rice',
        ingredients: ['chicken'],
        recentMeals: ['Chicken Pulao', 'Daal Chawal'],
      );
      expect(buildSuggestPrompt(withRecent), contains('Chicken Pulao, Daal Chawal'));
      expect(buildSuggestPrompt(withRecent), contains('do not suggest them'));
    });

    test('with nothing eaten recently the prompt does not mention it', () {
      expect(buildSuggestPrompt(request), isNot(contains('ate these recently')));
    });
  });
}
