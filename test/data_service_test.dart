import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/days_left.dart';
import 'package:what_can_i_cook/logic/item_matching.dart';
import 'package:what_can_i_cook/models/family_profile.dart';
import 'package:what_can_i_cook/models/inventory_item.dart';
import 'package:what_can_i_cook/models/meal.dart';
import 'package:what_can_i_cook/services/data_service.dart';

// These run the real save logic against a stand-in Firestore, so they check what is actually
// written, not a copy of it.
void main() {
  late FakeFirebaseFirestore db;
  late DataService data;

  setUp(() {
    db = FakeFirebaseFirestore();
    data = DataService('u1', firestore: db);
  });

  NewItem item(String name, double amount, String unit) =>
      NewItem(name: name, amount: amount, unit: unit);

  Future<List<InventoryItem>> stock() => data.inventoryOnce();

  Future<InventoryItem> find(String name) async =>
      (await stock()).firstWhere((i) => i.name == name);

  UsedAmount used(InventoryItem i, double amount) =>
      UsedAmount(id: i.id, name: i.name, unit: i.unit, amount: amount, left: i.amount);

  group('adding groceries', () {
    test('a new item becomes one line with its name, unit and amount', () async {
      await data.addItems([item('Chicken', 1.5, 'kg')]);

      final lines = await stock();
      expect(lines, hasLength(1));
      expect(lines.single.name, 'Chicken');
      expect(lines.single.unit, 'kg');
      expect(lines.single.amount, 1.5);
    });

    test('the same item again raises the amount', () async {
      await data.addItems([item('Chicken', 1, 'kg')]);
      await data.addItems([item('chicken', 0.5, 'kg')]);

      final lines = await stock();
      expect(lines, hasLength(1));
      expect(lines.single.amount, 1.5);
    });

    test('a second pack spelled differently, in a related unit, is the same line', () async {
      await data.addItems([item('Shan Chaat Masala', 1, 'packs')]);
      final results = await data.addItems([item('Shan Chat Masala', 2, 'pieces')]);

      final lines = await stock();
      expect(lines, hasLength(1));
      expect(lines.single.name, 'Shan Chaat Masala'); // keeps the name she already had
      expect(lines.single.unit, 'packs');
      expect(lines.single.amount, 3);
      expect(results.single.merged, isTrue);
      expect(results.single.newTotal, 3);
    });

    test('grams are added to kilograms', () async {
      await data.addItems([item('Basmati Rice', 1, 'kg')]);
      await data.addItems([item('Basmati Rice', 500, 'g')]);

      expect((await find('Basmati Rice')).amount, 1.5);
    });

    test('a different brand is a separate line', () async {
      await data.addItems([item('Shan Chaat Masala', 1, 'packs')]);
      await data.addItems([item('National Chaat Masala', 1, 'packs')]);

      expect((await stock()).map((i) => i.name), ['National Chaat Masala', 'Shan Chaat Masala']);
    });

    test('the same unit with an unrelated product is not mixed up: milk in L and kg', () async {
      await data.addItems([item('Milk', 1, 'L')]);
      await data.addItems([item('Milk', 2, 'kg')]);

      expect(await stock(), hasLength(2));
    });

    test('several items in one go are all saved, and the same product twice becomes one line', () async {
      await data.addItems([
        item('Olpers Milk', 1, 'L'),
        item('Shan Chaat Masala', 1, 'packs'),
        item('Shan Chat Masala', 1, 'packs'),
      ]);

      final lines = await stock();
      expect(lines, hasLength(2));
      expect((await find('Shan Chaat Masala')).amount, 2);
    });

    test('works for names in other languages', () async {
      await data.addItems([item('مرغی', 1, 'kg')]);
      await data.addItems([item('مرغی', 1, 'kg')]);

      final lines = await stock();
      expect(lines.single.name, 'مرغی');
      expect(lines.single.amount, 2);
    });
  });

  group('reading groceries', () {
    test('listed A to Z whatever the capital letters', () async {
      await data.addItems([item('rice', 1, 'kg'), item('Chicken', 1, 'kg'), item('Aloo', 2, 'kg')]);

      expect((await stock()).map((i) => i.name), ['Aloo', 'Chicken', 'rice']);
    });

    test('a line with nothing left is not shown', () async {
      await data.addItems([item('Rice', 1, 'kg')]);
      await db.doc('users/u1/inventory/${itemIdFor('Eggs', 'pieces')}').set({
        'name': 'Eggs',
        'unit': 'pieces',
        'amount': 0,
      });

      expect((await stock()).map((i) => i.name), ['Rice']);
    });

    test('the live list follows changes', () async {
      final seen = <List<String>>[];
      final sub = data.inventory().listen((items) => seen.add(items.map((i) => i.name).toList()));
      await data.addItems([item('Rice', 1, 'kg')]);
      await Future<void>.delayed(Duration.zero);
      await data.addItems([item('Chicken', 1, 'kg')]);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen.last, ['Chicken', 'Rice']);
    });

    test('an item can be removed', () async {
      await data.addItems([item('Rice', 1, 'kg'), item('Chicken', 1, 'kg')]);
      await data.removeItem((await find('Rice')).id);

      expect((await stock()).map((i) => i.name), ['Chicken']);
    });

    test("one person's groceries are not another person's", () async {
      await data.addItems([item('Rice', 1, 'kg')]);
      final other = DataService('u2', firestore: db);

      expect(await other.inventoryOnce(), isEmpty);
    });
  });

  group('logging a cooked dish', () {
    setUp(() async {
      await data.addItems([
        item('Chicken', 1.5, 'kg'),
        item('Rice', 5, 'kg'),
        item('Eggs', 12, 'pieces'),
      ]);
    });

    Future<Map<String, dynamic>> onlyMeal() async {
      final meals = await db.collection('users/u1/meals').get();
      expect(meals.docs, hasLength(1));
      return meals.docs.single.data();
    }

    test('takes what was used out of the groceries and leaves the rest', () async {
      final chicken = await find('Chicken');
      final rice = await find('Rice');
      await data.logMeal(LogMealRequest(
        dishName: 'Chicken Pulao',
        slot: 'Dinner',
        used: [used(chicken, 0.5), used(rice, 1)],
      ));

      expect((await find('Chicken')).amount, 1.0);
      expect((await find('Rice')).amount, 4.0);
      expect((await find('Eggs')).amount, 12); // not used: untouched
    });

    test('an item that is used up disappears', () async {
      final eggs = await find('Eggs');
      await data.logMeal(LogMealRequest(dishName: 'Omelette', slot: 'Lunch', used: [used(eggs, 12)]));

      expect((await stock()).map((i) => i.name), ['Chicken', 'Rice']);
    });

    test('using more than was left finishes it, never going below zero', () async {
      final chicken = await find('Chicken');
      await data.logMeal(LogMealRequest(dishName: 'Karahi', slot: 'Dinner', used: [used(chicken, 9)]));

      expect((await stock()).map((i) => i.name), isNot(contains('Chicken')));
      final raw = await db.doc('users/u1/inventory/${chicken.id}').get();
      expect(raw.exists, isFalse); // gone, not stored as -7.5
    });

    test('the dish is saved in the log with its date, meal and amounts used', () async {
      final chicken = await find('Chicken');
      final eggs = await find('Eggs');
      await data.logMeal(LogMealRequest(
        dishName: '  Chicken Pulao  ',
        slot: 'Dinner',
        used: [used(chicken, 0.5), used(eggs, 0)], // blank amount: not recorded
      ));

      final meal = await onlyMeal();
      final now = DateTime.now();
      expect(meal['dishName'], 'Chicken Pulao');
      expect(meal['slot'], 'Dinner');
      expect(meal['date'], dateToKey(DateTime(now.year, now.month, now.day)));
      expect(meal['createdAt'], isNotNull);
      final recorded = meal['used'] as List;
      expect(recorded, hasLength(1));
      expect(recorded.single, {'name': 'Chicken', 'unit': 'kg', 'amount': 0.5});
    });

    test('a dish can be logged without any ingredients, and the groceries stay as they were', () async {
      await data.logMeal(const LogMealRequest(dishName: 'Daal', slot: 'Lunch', used: []));

      expect((await onlyMeal())['used'], isEmpty);
      expect((await find('Chicken')).amount, 1.5);
    });
  });

  group('the daily log and recent meals', () {
    Future<void> meal(String name, int daysAgo) {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day - daysAgo);
      return db.collection('users/u1/meals').add({
        'dishName': name,
        'slot': 'Dinner',
        'date': dateToKey(day),
        'used': <Object>[],
        'createdAt': Timestamp.fromDate(day),
      });
    }

    test('only the last 7 days count as recent', () async {
      await meal('Today', 0);
      await meal('Six days ago', 6);
      await meal('Seven days ago', 7);
      await meal('Long ago', 30);

      expect(await data.recentMealNames(), {'Today', 'Six days ago'});
    });

    test('the window can be shorter', () async {
      await meal('Today', 0);
      await meal('Yesterday', 1);
      await meal('Two days ago', 2);

      expect(await data.recentMealNames(days: 2), {'Today', 'Yesterday'});
    });

    test('nothing eaten gives an empty set', () async {
      expect(await data.recentMealNames(), isEmpty);
    });

    test('the log lists the newest day first', () async {
      await meal('Old', 5);
      await meal('New', 0);
      await meal('Middle', 2);

      final names = (await data.meals().first).map((m) => m.dishName).toList();
      expect(names, ['New', 'Middle', 'Old']);
    });
  });

  group('shopping days and the family profile', () {
    test('shopping days are saved and read back', () async {
      await data.saveShoppingDates(last: DateTime(2026, 11, 28), next: DateTime(2026, 12, 28));

      final dates = await data.shoppingDates().first;
      expect(dates.last, DateTime(2026, 11, 28));
      expect(dates.next, DateTime(2026, 12, 28));
    });

    test('with nothing saved there are no shopping days', () async {
      final dates = await data.shoppingDates().first;
      expect(dates.last, isNull);
      expect(dates.next, isNull);
    });

    test('a profile is saved and read back', () async {
      await data.saveProfile(const FamilyProfile(
        people: [Person(age: 38, gender: 'Female'), Person(age: 8, gender: 'Male')],
        country: 'Pakistan',
        spice: 'Mild',
        cuisines: ['Pakistani'],
        habits: 'Kids like junk food.',
      ));

      final back = await data.profileOnce();
      expect(back.people.map((p) => p.age), [38, 8]);
      expect(back.spice, 'Mild');
      expect(back.habits, 'Kids like junk food.');
    });

    test('with no profile saved you get an empty one', () async {
      expect((await data.profileOnce()).isEmpty, isTrue);
    });

    test('saving the profile does not erase the shopping days, and the other way round', () async {
      await data.saveShoppingDates(last: DateTime(2026, 11, 28), next: DateTime(2026, 12, 28));
      await data.saveProfile(const FamilyProfile(country: 'Pakistan'));
      expect((await data.shoppingDates().first).next, DateTime(2026, 12, 28));

      await data.saveShoppingDates(last: DateTime(2026, 12, 28), next: DateTime(2027, 1, 28));
      expect((await data.profileOnce()).country, 'Pakistan');
    });
  });
}
