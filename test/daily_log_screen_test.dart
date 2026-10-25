import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/meal.dart';
import 'package:what_can_i_cook/screens/daily_log_screen.dart';
import 'package:what_can_i_cook/theme.dart';

Future<void> _open(WidgetTester tester, Stream<List<MealEntry>> meals, {VoidCallback? onLog}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: DailyLogScreen(meals: meals, onLogDish: onLog ?? () {}),
  ));
  await tester.pumpAndSettle();
}

DateTime _day(int daysAgo) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - daysAgo);
}

void main() {
  testWidgets('shows what was cooked, newest first, with what was used', (tester) async {
    await _open(
      tester,
      Stream.value([
        MealEntry(
          id: '1',
          dishName: 'Chicken Pulao',
          slot: 'Dinner',
          date: _day(0),
          used: const [
            (name: 'Chicken', unit: 'kg', amount: 0.5),
            (name: 'Rice', unit: 'kg', amount: 1.0),
          ],
        ),
        MealEntry(id: '2', dishName: 'Aloo Gobi', slot: 'Lunch', date: _day(1), used: const []),
      ]),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Chicken Pulao'), findsOneWidget);
    expect(find.text('Used: Chicken 0.5 kg, Rice 1 kg'), findsOneWidget);
    expect(find.text('No ingredients recorded.'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Chicken Pulao')).dy,
        lessThan(tester.getTopLeft(find.text('Aloo Gobi')).dy));
  });

  testWidgets('says so when nothing has been logged', (tester) async {
    await _open(tester, Stream.value(const <MealEntry>[]));
    expect(find.textContaining('Nothing logged yet'), findsOneWidget);
  });

  testWidgets('the log button opens the log screen', (tester) async {
    var tapped = false;
    await _open(tester, Stream.value(const <MealEntry>[]), onLog: () => tapped = true);
    await tester.tap(find.text("Log today's dish"));
    expect(tapped, isTrue);
  });

  testWidgets('a loading problem is explained', (tester) async {
    await _open(tester, Stream<List<MealEntry>>.error(Exception('offline')));
    expect(find.textContaining('Could not load your log'), findsOneWidget);
  });
}
