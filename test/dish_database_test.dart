import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/ingredient_matcher.dart';

const _csv = '''name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps
Chicken Pulao,Pakistani,both,medium,rice,chicken; rice; onion,mild,yes,Chicken 1 kg; Rice 2 cups,Fry onions|Add chicken|Add rice
Egg Curry,Pakistani,both,light,roti,eggs; onion; tomato,medium,no,Eggs 6; Onions 2,Fry onions|Add eggs
Aloo Gobi,Pakistani,both,light,roti,aloo; gobi; tarka,medium,no,Potatoes 3,Fry|Cook
Sweet Kheer,Pakistani,dessert,heavy,none,rice; milk,mild,yes,Milk 1 litre,Boil milk
Broken Row,Pakistani,both
Mutton Biryani,Pakistani,both,heavy,rice,mutton; rice; yogurt,hot,no,Mutton 1 kg,Cook mutton
''';

SuggestRequest _request({
  String meal = 'Dinner',
  String weight = 'Light',
  String base = 'Any',
  List<String> have = const [],
}) =>
    SuggestRequest(meal: meal, weight: weight, base: base, ingredients: have);

void main() {
  group('parseDishCsv', () {
    test('reads good rows and skips broken ones', () {
      final records = parseDishCsv(_csv);
      expect(records.map((r) => r.name), [
        'Chicken Pulao', 'Egg Curry', 'Aloo Gobi', 'Sweet Kheer', 'Mutton Biryani',
      ]);
      final pulao = records.first;
      expect(pulao.steps, ['Fry onions', 'Add chicken', 'Add rice']);
      expect(pulao.ingredientsWithQuantities, ['Chicken 1 kg', 'Rice 2 cups']);
      expect(pulao.kidFriendly, isTrue);
    });

    test('returns nothing for a file with the wrong header', () {
      expect(parseDishCsv('a,b\n1,2'), isEmpty);
    });
  });

  group('ingredient names', () {
    test('different ways to say the same thing match', () {
      expect(canonicalIngredient('Eggs'), 'egg');
      expect(canonicalIngredient('anda'), 'egg');
      expect(canonicalIngredient('Aloo'), 'potato');
      expect(canonicalIngredient('basmati rice'), 'rice');
      expect(canonicalIngredient('Tomatoes'), 'tomato');
    });

    test('non-ingredients are ignored', () {
      expect(canonicalIngredient('tarka'), isNull);
      expect(canonicalIngredient('spices'), isNull);
    });

    test('"chicken breast" still counts as chicken', () {
      expect(typedIngredients(['Chicken breast']), contains('chicken'));
    });
  });

  group('suggest', () {
    final book = DishDatabase(parseDishCsv(_csv), random: Random(1));

    test('matches typed ingredients and explains why', () {
      final dishes = book.suggest(_request(have: ['chicken', 'rice', 'onion'], weight: 'Heavy'));
      expect(dishes.first.name, 'Chicken Pulao');
      expect(dishes.first.why, contains('chicken'));
      expect(dishes.first.fromDatabase, isTrue);
      expect(dishes.first.recipe!.steps, isNotEmpty);
    });

    test('never offers desserts as a meal', () {
      final dishes = book.suggest(_request(have: ['rice', 'milk'], weight: 'Heavy'));
      expect(dishes.map((d) => d.name), isNot(contains('Sweet Kheer')));
    });

    test('Light accepts light and medium, Heavy accepts medium and heavy', () {
      final all = ['chicken', 'rice', 'onion', 'eggs', 'tomato', 'mutton', 'yogurt'];
      final light = book.suggest(_request(have: all, weight: 'Light')).map((d) => d.name);
      expect(light, containsAll(['Egg Curry', 'Chicken Pulao']));
      expect(light, isNot(contains('Mutton Biryani')));
      final heavy = book.suggest(_request(have: all, weight: 'Heavy')).map((d) => d.name);
      expect(heavy, containsAll(['Mutton Biryani', 'Chicken Pulao']));
      expect(heavy, isNot(contains('Egg Curry')));
    });

    test('base filters: Rice, Roti, and noodles which the book does not have', () {
      final all = ['chicken', 'rice', 'onion', 'eggs', 'tomato', 'aloo', 'gobi'];
      expect(book.suggest(_request(have: all, base: 'Rice')).map((d) => d.name), ['Chicken Pulao']);
      expect(book.suggest(_request(have: all, base: 'Roti')).map((d) => d.name),
          containsAll(['Egg Curry', 'Aloo Gobi']));
      expect(book.suggest(_request(have: all, base: 'Noodles')), isEmpty);
    });

    test('needs at least half of the main ingredients', () {
      // Egg Curry needs egg, onion, tomato: only tomato is not enough.
      expect(book.suggest(_request(have: ['tomato'], base: 'Roti')), isEmpty);
      // Two of three is enough.
      expect(book.suggest(_request(have: ['eggs', 'onion'], base: 'Roti')).first.name, 'Egg Curry');
    });

    test('dishes already shown are skipped', () {
      final request = _request(have: ['eggs', 'onion', 'aloo', 'gobi'], base: 'Roti');
      final first = book.suggest(request, limit: 1).single.name;
      final next = book.suggest(request, exclude: {first});
      expect(next.map((d) => d.name), isNot(contains(first)));
    });

    test('returns nothing when no ingredients were typed', () {
      expect(book.suggest(_request()), isEmpty);
    });
  });

  group('variety', () {
    const manyBiryanis = '''name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps
Sindhi Chicken Biryani,Pakistani,both,medium,rice,chicken; rice; onion,hot,no,Chicken 1 kg,Cook
Karachi Chicken Biryani,Pakistani,both,medium,rice,chicken; rice; onion,hot,no,Chicken 1 kg,Cook
Memoni Chicken Biryani,Pakistani,both,medium,rice,chicken; rice; onion,hot,no,Chicken 1 kg,Cook
Bombay Chicken Biryani,Pakistani,both,medium,rice,chicken; rice; onion,hot,no,Chicken 1 kg,Cook
Chicken Pulao,Pakistani,both,medium,rice,chicken; rice,mild,yes,Chicken 1 kg,Cook
''';
    test('no more than two dishes with the same main ingredients', () {
      final book = DishDatabase(parseDishCsv(manyBiryanis), random: Random(3));
      final dishes = book.suggest(_request(have: ['chicken', 'rice', 'onion'], base: 'Rice'));
      final biryanis = dishes.where((d) => d.name.contains('Biryani'));
      expect(biryanis.length, lessThanOrEqualTo(2));
      expect(dishes.map((d) => d.name), contains('Chicken Pulao'));
    });

    test('the "why" line never repeats an ingredient', () {
      const twice = '''name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps
Aloo Tamatar,Pakistani,both,light,roti,potato; tomato; onion; tomato,mild,yes,Potatoes 4,Cook
''';
      final book = DishDatabase(parseDishCsv(twice));
      final why = book.suggest(_request(have: ['potato', 'tomato', 'onion'], base: 'Roti')).single.why;
      expect(why, 'Uses potato, tomato, onion you have.');
    });
  });

  group('the real recipe book', () {
    final records = parseDishCsv(File('data/dishes.csv').readAsStringSync());
    final book = DishDatabase(records, random: Random(7));

    test('loads every dish with ingredients and steps', () {
      expect(records.length, greaterThanOrEqualTo(1000));
      expect(records.every((r) => r.steps.isNotEmpty && r.ingredientsWithQuantities.isNotEmpty), isTrue);
      expect(records.map((r) => r.name).toSet().length, records.length, reason: 'names are unique');
    });

    test('a typical request gives five dishes quickly', () {
      final watch = Stopwatch()..start();
      final dishes = book.suggest(_request(
        weight: 'Light',
        base: 'Rice',
        have: ['chicken', 'onion', 'rice', 'yogurt'],
      ));
      watch.stop();
      expect(dishes.length, 5);
      expect(watch.elapsedMilliseconds, lessThan(200));
    });
  });
}
