import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/logic/days_left.dart';
import 'package:what_can_i_cook/logic/item_matching.dart';
import 'package:what_can_i_cook/screens/home_screen.dart';
import 'package:what_can_i_cook/services/data_service.dart';
import 'package:what_can_i_cook/theme.dart';

late FakeFirebaseFirestore _db;
late DataService _data;

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _inDays(int days) {
  final t = _today();
  return DateTime(t.year, t.month, t.day + days);
}

Future<void> _open(WidgetTester tester, {String? name = 'Halima'}) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: HomeScreen(
      user: MockUser(uid: 'u1', displayName: name, email: 'halima@example.com'),
      data: _data,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _db = FakeFirebaseFirestore();
    _data = DataService('u1', firestore: _db);
  });

  group('the greeting', () {
    testWidgets('uses her name', (tester) async {
      await _open(tester);

      expect(find.textContaining(', Halima'), findsOneWidget);
      expect(find.text("What's on the menu today?"), findsOneWidget);
      expect(find.text('Add your name'), findsNothing);
    });

    testWidgets('never shows her email address', (tester) async {
      await _open(tester);

      expect(find.textContaining('halima@example.com'), findsNothing);
    });

    testWidgets('with no name saved it offers to add one', (tester) async {
      await _open(tester, name: null);

      expect(find.text('Add your name'), findsOneWidget);
      // just "Good morning/afternoon/evening", with no ", name" after it
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && const {'Good morning', 'Good afternoon', 'Good evening'}.contains(w.data),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the name box opens, and can be dismissed without saving', (tester) async {
      await _open(tester, name: null);

      await tester.tap(find.text('Add your name'));
      await tester.pumpAndSettle();
      expect(find.text('What should we call you?'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('What should we call you?'), findsNothing);
    });
  });

  group('the groceries dashboard', () {
    testWidgets('with nothing saved it explains and offers to add', (tester) async {
      await _open(tester);

      expect(find.text('No groceries yet'), findsOneWidget);
      expect(find.text('Add groceries'), findsOneWidget);
      expect(find.text('Total left'), findsNothing);
    });

    testWidgets('shows the days until shopping, every item and the total', (tester) async {
      await _data.addItems([
        const NewItem(name: 'Chicken', amount: 1.5, unit: 'kg'),
        const NewItem(name: 'Rice', amount: 5, unit: 'kg'),
        const NewItem(name: 'Eggs', amount: 12, unit: 'pieces'),
      ]);
      await _data.saveShoppingDates(last: _today(), next: _inDays(10));
      await _open(tester);

      expect(find.textContaining('10 days until your next shopping'), findsOneWidget);
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('1.5 kg'), findsOneWidget);
      expect(find.text('5 kg'), findsOneWidget);
      expect(find.text('12 pieces'), findsOneWidget);
      expect(find.text('6.5 kg, 12 pieces'), findsOneWidget); // units are never mixed
      expect(find.text('Amounts are approximate.'), findsOneWidget);
      expect(find.text('No groceries yet'), findsNothing);
    });

    testWidgets('says so when the shopping day is today, tomorrow, or has passed', (tester) async {
      await _data.addItems([const NewItem(name: 'Rice', amount: 5, unit: 'kg')]);

      await _data.saveShoppingDates(last: _inDays(-20), next: _today());
      await _open(tester);
      expect(find.textContaining('Shopping day is today'), findsOneWidget);

      await _data.saveShoppingDates(last: _inDays(-20), next: _inDays(1));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 day until your next shopping'), findsOneWidget);

      await _data.saveShoppingDates(last: _inDays(-30), next: _inDays(-3));
      await tester.pumpAndSettle();
      expect(find.textContaining('has passed'), findsOneWidget);
    });

    testWidgets('with groceries but no shopping day it asks her to set one', (tester) async {
      await _data.addItems([const NewItem(name: 'Rice', amount: 5, unit: 'kg')]);
      await _open(tester);

      expect(find.textContaining('Set your next shopping date'), findsOneWidget);
    });

    testWidgets('updates by itself when a grocery is added', (tester) async {
      await _data.addItems([const NewItem(name: 'Rice', amount: 5, unit: 'kg')]);
      await _data.saveShoppingDates(last: _today(), next: _inDays(5));
      await _open(tester);
      expect(find.text('Chicken'), findsNothing);

      await _data.addItems([const NewItem(name: 'Chicken', amount: 1, unit: 'kg')]);
      await tester.pumpAndSettle();

      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('6 kg'), findsOneWidget);
    });

    testWidgets('an item that is used up disappears from the list', (tester) async {
      await _data.addItems([const NewItem(name: 'Rice', amount: 5, unit: 'kg')]);
      await _data.saveShoppingDates(last: _today(), next: _inDays(5));
      await _open(tester);
      expect(find.text('Rice'), findsOneWidget);

      await _db.doc('users/u1/inventory/${itemDocId('Rice', 'kg')}').delete();
      await tester.pumpAndSettle();

      expect(find.text('Rice'), findsNothing);
      expect(find.text('No groceries yet'), findsOneWidget);
    });

    testWidgets('a copy of the dates she sees matches the maths', (tester) async {
      await _data.addItems([const NewItem(name: 'Rice', amount: 5, unit: 'kg')]);
      await _data.saveShoppingDates(last: _today(), next: _inDays(30));
      await _open(tester);

      expect(find.textContaining(daysUntilMessage(DateTime.now(), _inDays(30))), findsOneWidget);
    });
  });

  group('getting around', () {
    testWidgets('the big panel opens the dish questions', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Suggest a dish'));
      await tester.pumpAndSettle();

      expect(find.text('Tell me about today'), findsOneWidget);
    });

    testWidgets('Add groceries opens its page', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Add groceries'));
      await tester.pumpAndSettle();

      expect(find.text('Shopping days'), findsOneWidget);
    });

    testWidgets('Daily log opens its page', (tester) async {
      await _open(tester);

      await tester.tap(find.text('Daily log'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing logged yet'), findsOneWidget);
    });

    testWidgets('has a way to open settings', (tester) async {
      await _open(tester);

      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });
}
