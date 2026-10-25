import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/dish.dart';
import 'package:what_can_i_cook/models/family_profile.dart';
import 'package:what_can_i_cook/services/dish_database.dart';
import 'package:what_can_i_cook/services/gemini_service.dart';

const _family = FamilyProfile(
  people: [
    Person(age: 38, gender: 'Female'),
    Person(age: 41, gender: 'Male'),
    Person(age: 9, gender: 'Female'),
  ],
  country: 'Pakistan',
  spice: 'Mild',
  cuisines: ['Pakistani', 'Chinese'],
  habits: 'The men like desi food, the kids like junk food.',
);

// Same ingredients, different spice and kid-friendliness, so only the profile can tell them apart.
const _csv =
    'name,cuisine,meal,weight,base,main_ingredients,spice,kid_friendly,ingredients_with_quantities,steps\n'
    'Hot Chicken,Pakistani,both,medium,rice,chicken; rice,hot,no,Chicken 1 kg,Cook\n'
    'Medium Chicken,Pakistani,both,medium,rice,chicken; rice; onion,medium,no,Chicken 1 kg,Cook\n'
    'Mild Chicken,Pakistani,both,medium,rice,chicken; rice; garlic,mild,no,Chicken 1 kg,Cook\n'
    'Kids Chicken,Pakistani,both,medium,rice,chicken; rice; tomato,medium,yes,Chicken 1 kg,Cook\n'
    'Chinese Chicken,Chinese,both,medium,rice,chicken; rice; egg,medium,no,Chicken 1 kg,Cook\n';

SuggestRequest _request(FamilyProfile profile) => SuggestRequest(
      meal: 'Dinner',
      weight: 'Heavy',
      base: 'Rice',
      ingredients: const ['chicken', 'rice', 'onion', 'garlic', 'tomato', 'egg'],
      profile: profile,
    );

void main() {
  group('FamilyProfile data', () {
    test('survives a round trip through the database', () {
      final back = FamilyProfile.fromMap(_family.toMap());
      expect(back.people.map((p) => p.age), [38, 41, 9]);
      expect(back.people[1].gender, 'Male');
      expect(back.country, 'Pakistan');
      expect(back.spice, 'Mild');
      expect(back.cuisines, ['Pakistani', 'Chinese']);
      expect(back.habits, contains('kids like junk food'));
    });

    test('odd or missing data is skipped, never a crash', () {
      expect(FamilyProfile.fromMap(null).isEmpty, isTrue);
      expect(FamilyProfile.fromMap('nonsense').isEmpty, isTrue);
      final odd = FamilyProfile.fromMap({
        'people': [
          {'age': 'ten', 'gender': 'Male'},
          {'age': 400, 'gender': 'Male'},
          {'age': -2},
          {'age': 7, 'gender': 'Other'},
          'not a person',
        ],
        'spice': 'Extreme',
        'cuisines': ['Indian', 5, '  '],
      });
      expect(odd.people.map((p) => p.age), [7]);
      expect(odd.people.single.gender, 'Female');
      expect(odd.spice, '');
      expect(odd.cuisines, ['Indian']);
    });

    test('counts children as under 12', () {
      expect(_family.childCount, 1);
      expect(_family.adultCount, 2);
    });
  });

  group('suggestions follow the family', () {
    final book = DishDatabase(parseDishCsv(_csv));

    String first(FamilyProfile profile) => book.suggest(_request(profile), limit: 1).single.name;

    test('someone who wants mild food is never offered hot dishes', () {
      const mild = FamilyProfile(spice: 'Mild');
      for (var i = 0; i < 10; i++) {
        expect(book.suggest(_request(mild)).map((d) => d.name), isNot(contains('Hot Chicken')));
      }
      expect(first(mild), 'Mild Chicken');
    });

    test('hot lovers get the hot dish first', () {
      expect(first(const FamilyProfile(spice: 'Hot')), 'Hot Chicken');
    });

    test('with children the kid-friendly dish comes first', () {
      const kids = FamilyProfile(people: [Person(age: 6, gender: 'Male')]);
      expect(first(kids), 'Kids Chicken');
    });

    test('adults only does not favour kid dishes', () {
      const adults = FamilyProfile(people: [Person(age: 40, gender: 'Female')]);
      expect(book.suggest(_request(adults)).length, 5);
    });

    test('a favourite cuisine comes first', () {
      expect(first(const FamilyProfile(cuisines: ['Chinese'])), 'Chinese Chicken');
    });

    test('with no profile every dish is still available', () {
      final names = book.suggest(_request(FamilyProfile.empty)).map((d) => d.name);
      expect(names, hasLength(5));
      expect(names, contains('Hot Chicken'));
    });
  });

  group('what the cooking helper (AI) is told', () {
    test('family size, spice, cuisines and notes', () {
      final summary = _family.summaryForAi();
      expect(summary, contains('family of 3 (2 adults, 1 children)'));
      expect(summary, contains('Pakistan'));
      expect(summary, contains('prefer mild spice'));
      expect(summary, contains('Pakistani, Chinese'));
      expect(summary, contains('kids like junk food'));
    });

    test('never exact ages or genders', () {
      final summary = _family.summaryForAi();
      for (final secret in ['38', '41', 'Male', 'Female']) {
        expect(summary, isNot(contains(secret)), reason: secret);
      }
    });

    test('it appears in the prompt only when there is a profile', () {
      expect(buildSuggestPrompt(_request(_family)), contains('About the family'));
      expect(buildSuggestPrompt(_request(FamilyProfile.empty)), isNot(contains('About the family')));
    });

    test('very long notes are shortened', () {
      final long = FamilyProfile(habits: 'x' * 1000);
      expect(long.summaryForAi().length, lessThan(400));
    });
  });
}
