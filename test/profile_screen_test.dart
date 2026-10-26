import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/models/family_profile.dart';
import 'package:what_can_i_cook/screens/profile_screen.dart';
import 'package:what_can_i_cook/ui/skeleton.dart';

import 'helpers/test_app.dart';

/// Opens the Family tab and returns the list that every saved profile lands in.
Future<List<FamilyProfile>> _open(
  WidgetTester tester, {
  Future<FamilyProfile>? load,
  Future<void> Function(FamilyProfile)? onSave,
}) async {
  tester.view.physicalSize = const Size(900, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final saved = <FamilyProfile>[];
  await tester.pumpWidget(testApp(ProfileScreen(
    load: load ?? Future.value(FamilyProfile.empty),
    onSave: onSave ?? (p) async => saved.add(p),
  )));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return saved;
}

/// Waits past the moment the screen holds changes before saving them.
Future<void> _waitForSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump();
}

const _saved = FamilyProfile(
  people: [Person(age: 38, gender: 'Female'), Person(age: 9, gender: 'Male'), Person(age: 6, gender: 'Male')],
  country: 'Pakistan',
  spice: 'Mild',
  cuisines: ['Chinese'],
  habits: 'Kids like junk food.',
);

void main() {
  testWidgets('shows what was saved before', (tester) async {
    await _open(tester, load: Future.value(_saved));

    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Saved just now'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Kids like junk food.'), findsOneWidget);
    expect(find.text('Mild'), findsWidgets);
    expect(find.text('Mild skips hot dishes and favours gentle ones.'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget); // only Chinese is chosen
  });

  testWidgets('counts adults and children from the saved people', (tester) async {
    await _open(tester, load: Future.value(_saved));

    expect(find.text('1'), findsOneWidget); // one adult
    expect(find.text('2'), findsOneWidget); // two children
  });

  testWidgets('nothing is saved until she changes something', (tester) async {
    final saved = await _open(tester, load: Future.value(_saved));
    await _waitForSave(tester);

    expect(saved, isEmpty);
  });

  testWidgets('adding an adult and a child saves by itself, with no Save button', (tester) async {
    final saved = await _open(tester);
    expect(find.text('Save'), findsNothing);

    await tester.tap(find.byTooltip('More: Adults'));
    await tester.tap(find.byTooltip('More: Adults'));
    await tester.tap(find.byTooltip('More: Children under 12'));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    await _waitForSave(tester);

    expect(saved, hasLength(1)); // three taps, one save
    expect(saved.single.adultCount, 2);
    expect(saved.single.childCount, 1);
    expect(find.text('Saved just now'), findsOneWidget);
  });

  testWidgets('the minus button stops at zero', (tester) async {
    await _open(tester);

    final minus = find.widgetWithIcon(IconButton, Icons.remove_rounded).first;
    expect(tester.widget<IconButton>(minus).onPressed, isNull);
  });

  testWidgets('removing a child keeps the adults and the other child', (tester) async {
    final saved = await _open(tester, load: Future.value(_saved));

    await tester.tap(find.byTooltip('Fewer: Children under 12'));
    await _waitForSave(tester);

    expect(saved.single.people.map((p) => p.age), [38, 9]);
  });

  testWidgets('the saved country is kept even though there is no box for it', (tester) async {
    final saved = await _open(tester, load: Future.value(_saved));

    await tester.tap(find.byTooltip('More: Adults'));
    await _waitForSave(tester);

    expect(saved.single.country, 'Pakistan');
  });

  testWidgets('choosing cuisines saves them, and tapping again turns one off', (tester) async {
    final saved = await _open(tester);

    await tester.tap(find.text('Pakistani'));
    await tester.tap(find.text('BBQ'));
    await tester.tap(find.text('BBQ'));
    await _waitForSave(tester);

    expect(saved.single.cuisines, ['Pakistani']);
  });

  testWidgets('only five cuisine chips are offered', (tester) async {
    await _open(tester);

    for (final c in ['Pakistani', 'Chinese', 'Arabic', 'Italian', 'BBQ']) {
      expect(find.text(c), findsOneWidget);
    }
  });

  testWidgets('the spice slider rests on Medium, saves nothing until moved, then saves the level',
      (tester) async {
    final saved = await _open(tester);
    expect(find.text('Medium shows most dishes and skips very hot ones.'), findsOneWidget);
    await _waitForSave(tester);
    expect(saved, isEmpty);

    // drag the slider thumb to the far right
    await tester.drag(find.byType(Slider), const Offset(600, 0));
    await _waitForSave(tester);

    expect(saved.single.spice, 'Hot');
    expect(find.text('Hot shows everything, including the spiciest dishes.'), findsOneWidget);
  });

  testWidgets('typing a note saves it', (tester) async {
    final saved = await _open(tester);

    await tester.enterText(find.widgetWithText(TextField, 'For example: no mushrooms, less fried food'),
        'No mushrooms');
    await _waitForSave(tester);

    expect(saved.single.habits, 'No mushrooms');
  });

  testWidgets('says so when saving fails, and tapping the chip tries again', (tester) async {
    var fail = true;
    final saved = <FamilyProfile>[];
    await _open(tester, onSave: (p) async {
      if (fail) throw Exception('offline');
      saved.add(p);
    });

    await tester.tap(find.byTooltip('More: Adults'));
    await _waitForSave(tester);
    expect(find.text('Could not save. Try again'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Could not save. Try again'));
    await tester.pump();
    await tester.pump();

    expect(saved, hasLength(1));
    expect(find.text('Saved just now'), findsOneWidget);
  });

  testWidgets('with no internet it says the change is kept on the phone', (tester) async {
    await _open(tester, onSave: (_) => Completer<void>().future); // never answers

    await tester.tap(find.byTooltip('More: Adults'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(seconds: 9));

    expect(find.text('Saved on your phone'), findsOneWidget);
  });

  testWidgets('a change made just before leaving the tab is still saved', (tester) async {
    final saved = await _open(tester);

    await tester.tap(find.byTooltip('More: Adults'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox()); // leave before the moment has passed

    expect(saved, hasLength(1));
  });

  testWidgets('if the profile never arrives she is not stuck', (tester) async {
    await _open(tester, load: Completer<FamilyProfile>().future);
    expect(find.byType(SkeletonLoader), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pump();

    expect(find.text('Who eats at home'), findsOneWidget);
  });

  testWidgets('the privacy card says exactly what the AI sees', (tester) async {
    await _open(tester);

    expect(find.textContaining('never gets names, exact ages or your email'), findsOneWidget);
  });
}
