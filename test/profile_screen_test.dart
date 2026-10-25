import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/family_profile.dart';
import 'package:what_can_i_cook/screens/profile_screen.dart';
import 'package:what_can_i_cook/theme.dart';

/// Opens the profile screen and returns the list that every saved profile lands in.
Future<List<FamilyProfile>> _open(
  WidgetTester tester, {
  Future<FamilyProfile>? load,
  Future<void> Function(FamilyProfile)? onSave,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saved = <FamilyProfile>[];
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ProfileScreen(
                load: load ?? Future.value(FamilyProfile.empty),
                onSave: onSave ?? (p) async => saved.add(p),
              ),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  return saved;
}

void main() {
  testWidgets('shows what was saved before', (tester) async {
    await _open(
      tester,
      load: Future.value(const FamilyProfile(
        people: [Person(age: 9, gender: 'Male')],
        country: 'Pakistan',
        spice: 'Mild',
        cuisines: ['Chinese'],
        habits: 'Kids like junk food.',
      )),
    );

    expect(find.widgetWithText(TextField, '9'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Pakistan'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kids like junk food.'), findsOneWidget);
  });

  testWidgets('a family can be filled in and saved', (tester) async {
    final saved = await _open(tester);

    await tester.tap(find.text('Add a person'));
    await tester.pump();
    await tester.tap(find.text('Add a person'));
    await tester.pump();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '38'); // first person's age
    await tester.enterText(fields.at(1), '8'); // second person's age
    await tester.tap(find.text('Male').last); // the second person is a boy
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Country'), 'Pakistan');
    await tester.tap(find.text('Mild'));
    await tester.tap(find.text('Chinese'));
    await tester.tap(find.text('Indian'));
    await tester.tap(find.text('Indian')); // tapped twice: off again
    await tester.pump();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    final profile = saved.single;
    expect(profile.people.map((p) => p.age), [38, 8]);
    expect(profile.people.map((p) => p.gender), ['Female', 'Male']);
    expect(profile.country, 'Pakistan');
    expect(profile.spice, 'Mild');
    expect(profile.cuisines, ['Chinese']);
    expect(profile.childCount, 1);
  });

  testWidgets('tapping the chosen spice again clears it', (tester) async {
    final saved = await _open(tester, load: Future.value(const FamilyProfile(spice: 'Hot')));

    await tester.tap(find.text('Hot'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved.single.spice, '');
  });

  testWidgets('a person can be removed', (tester) async {
    final saved = await _open(
      tester,
      load: Future.value(const FamilyProfile(
        people: [Person(age: 30, gender: 'Female'), Person(age: 5, gender: 'Male')],
      )),
    );

    await tester.tap(find.byTooltip('Remove person 2'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved.single.people.map((p) => p.age), [30]);
  });

  testWidgets('an age that is not a number is explained, not saved', (tester) async {
    final saved = await _open(tester);

    await tester.tap(find.text('Add a person'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'ten');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.textContaining('Please type an age between 0 and 120 for person 1'), findsOneWidget);
    expect(saved, isEmpty);
  });

  testWidgets('if saving fails she sees a kind message and stays', (tester) async {
    await _open(tester, onSave: (_) async => throw Exception('denied'));

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not save'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('if the profile never arrives she can still fill in a new one', (tester) async {
    await _open(tester, load: Completer<FamilyProfile>().future, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.text('Add a person'), findsOneWidget);
  });

  testWidgets('it tells her what is shared with the AI', (tester) async {
    await _open(tester);
    expect(find.textContaining('never exact ages, names or email'), findsOneWidget);
  });
}
