import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/screens/dish_suggestion_screen.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/ingredient_matcher.dart';

const _header =
    'name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps';
const _row = 'Chicken Pulao,Pakistani,both,medium,rice,chicken; rice,mild,yes,Chicken 1 kg; Rice 2 cups,Fry|Cook';

SuggestRequest _ask(List<String> have, {String base = 'Any', String weight = 'Heavy'}) =>
    SuggestRequest(meal: 'Dinner', weight: weight, base: base, ingredients: have);

void main() {
  group('reading the recipe book file', () {
    test('a file saved on Windows (CRLF line endings) reads the same', () {
      final records = parseDishCsv('$_header\r\n$_row\r\n');
      expect(records.single.name, 'Chicken Pulao');
      expect(records.single.steps, ['Fry', 'Cook']);
    });

    test('a file saved from Excel as "CSV UTF-8" (it starts with an invisible marker) still reads', () {
      final records = parseDishCsv('﻿$_header\n$_row\n');
      expect(records, hasLength(1), reason: 'otherwise every dish silently disappears');
    });

    test('columns may be in any order and in any capital letters', () {
      const shuffled =
          'STEPS,Name,spice,base,weight,meal,cuisine,main_ingredients,kid_friendly,ingredients_with_quantities\n'
          'Fry|Cook,Egg Curry,mild,roti,light,both,Pakistani,egg; onion,no,Eggs 6\n';
      final record = parseDishCsv(shuffled).single;
      expect(record.name, 'Egg Curry');
      expect(record.base, 'roti');
      expect(record.steps, ['Fry', 'Cook']);
    });

    test('a field with commas inside quotes stays in one piece', () {
      const quoted = '$_header\n'
          'Karahi,Pakistani,both,medium,naan,chicken; tomato,hot,no,"Chicken 1 kg, cut up; Tomatoes 3","Heat oil, then fry|Add tomatoes"\n';
      final record = parseDishCsv(quoted).single;
      expect(record.ingredientsWithQuantities, ['Chicken 1 kg, cut up', 'Tomatoes 3']);
      expect(record.steps, ['Heat oil, then fry', 'Add tomatoes']);
    });

    test('blank lines and a missing final line break are fine', () {
      final records = parseDishCsv('$_header\n\n$_row\n\n\n');
      expect(records, hasLength(1));
      expect(parseDishCsv('$_header\n$_row'), hasLength(1));
    });

    test('a broken or half-empty row is skipped and the good rows still load', () {
      final text = '$_header\n'
          'Broken Row,Pakistani,both\n'
          ',Pakistani,both,medium,rice,chicken,mild,yes,Chicken,Cook\n' // no name
          'No Steps,Pakistani,both,medium,rice,chicken,mild,yes,Chicken,\n'
          'No Main,Pakistani,both,medium,rice,,mild,yes,Chicken,Cook\n'
          '$_row\n';
      expect(parseDishCsv(text).map((r) => r.name), ['Chicken Pulao']);
    });

    test('a missing column means no dishes rather than a crash', () {
      expect(parseDishCsv('name,cuisine\nA,B\n'), isEmpty);
      expect(parseDishCsv(''), isEmpty);
      expect(parseDishCsv(_header), isEmpty);
    });

    test('capital letters and spaces in the values do not matter', () {
      final record = parseDishCsv(
        '$_header\nEgg Curry,Pakistani, BOTH ,Light,ROTI,egg; onion,Mild,YES,Eggs 6,Fry\n',
      ).single;
      expect(record.meal, 'both');
      expect(record.weight, 'light');
      expect(record.base, 'roti');
      expect(record.kidFriendly, isTrue);
    });

    test('names in other languages work', () {
      final record = parseDishCsv('$_header\nمرغ کڑاہی,Pakistani,both,medium,naan,chicken,hot,no,Chicken,Cook\n').single;
      expect(record.name, 'مرغ کڑاہی');
    });

    test('extra spaces and empty pieces in lists are ignored', () {
      final record = parseDishCsv(
        '$_header\nA,Pakistani,both,medium,rice,chicken ;  ; rice ,mild,yes,Chicken 1 kg;;,  Fry  | |Cook \n',
      ).single;
      expect(record.mainIngredients, ['chicken', 'rice']);
      expect(record.steps, ['Fry', 'Cook']);
    });
  });

  group('suggesting from the recipe book', () {
    test('an empty recipe book gives nothing, not a crash', () {
      expect(DishDatabase(const []).suggest(_ask(['chicken'])), isEmpty);
    });

    test('a dish whose main ingredients are all style words is never suggested', () {
      final book = DishDatabase(parseDishCsv(
        '$_header\nMystery,Pakistani,both,medium,rice,tarka; spices; classic,mild,yes,Salt,Cook\n',
      ));
      expect(book.suggest(_ask(['tarka', 'spices', 'rice'])), isEmpty);
    });

    test('never more dishes than asked for', () {
      final rows = [for (var i = 0; i < 30; i++) 'Dish $i,Pakistani,both,medium,rice,item$i; chicken,mild,yes,Chicken,Cook'];
      final book = DishDatabase(parseDishCsv('$_header\n${rows.join('\n')}\n'), random: Random(1));
      expect(book.suggest(_ask(['chicken']), limit: 3), hasLength(3));
      expect(book.suggest(_ask(['chicken'])), hasLength(lessThanOrEqualTo(5)));
    });

    test('asking again gives different dishes until they run out', () {
      final rows = [for (var i = 0; i < 6; i++) 'Dish $i,Pakistani,both,medium,rice,chicken$i; rice,mild,yes,Chicken,Cook'];
      final book = DishDatabase(parseDishCsv('$_header\n${rows.join('\n')}\n'), random: Random(2));
      final request = _ask(['chicken0', 'chicken1', 'chicken2', 'chicken3', 'chicken4', 'chicken5', 'rice']);

      final first = book.suggest(request).map((d) => d.name).toSet();
      final second = book.suggest(request, exclude: first).map((d) => d.name).toSet();
      final third = book.suggest(request, exclude: {...first, ...second});

      expect(first, hasLength(5));
      expect(second, hasLength(1));
      expect(first.intersection(second), isEmpty);
      expect(third, isEmpty, reason: 'then Gemini is asked instead');
    });

    test('typing ingredients in capitals, with plurals or in another word still matches', () {
      final book = DishDatabase(parseDishCsv('$_header\n$_row\n'));
      expect(book.suggest(_ask(['CHICKEN', 'Basmati Rice'])), hasLength(1));
      expect(book.suggest(_ask(['Murgh', 'chawal'])), hasLength(1));
    });

    test('a dish is not offered when she has almost none of it', () {
      final book = DishDatabase(parseDishCsv(
        '$_header\nBig Feast,Pakistani,both,medium,rice,chicken; rice; onion; tomato; yogurt; peas,mild,yes,x,Cook\n',
      ));
      expect(book.suggest(_ask(['chicken'])), isEmpty);
      expect(book.suggest(_ask(['chicken', 'rice', 'onion'])), hasLength(1));
    });
  });

  group('what mum types', () {
    test('commas, new lines, semicolons and the Urdu comma all separate items', () {
      expect(splitIngredients('chicken, onion\nrice;egg،milk'), ['chicken', 'onion', 'rice', 'egg', 'milk']);
    });

    test('blanks give nothing', () {
      expect(splitIngredients(''), isEmpty);
      expect(splitIngredients(' , ; \n '), isEmpty);
    });

    test('words are tidied to one name', () {
      expect(canonicalIngredient('  EGGS '), 'egg');
      expect(canonicalIngredient('Anda'), 'egg');
      expect(canonicalIngredient('yoghurt'), 'yogurt');
      expect(canonicalIngredient('Tomatoes'), 'tomato');
      expect(canonicalIngredient('Murgh'), 'chicken');
    });

    test('words that are not ingredients are dropped', () {
      expect(canonicalIngredient('tarka'), isNull);
      expect(canonicalIngredient(''), isNull);
      expect(canonicalIngredient('   '), isNull);
    });

    test('a word it does not know is kept as it is', () {
      expect(canonicalIngredient('Dragonfruit'), 'dragonfruit');
    });

    test('a described item still gives its main ingredient', () {
      expect(typedIngredients(['Chicken breast']), containsAll(['chicken', 'chicken breast']));
      expect(typedIngredients(['Basmati rice 5kg']), contains('rice'));
    });
  });
}
