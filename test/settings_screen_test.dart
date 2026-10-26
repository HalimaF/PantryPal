import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/screens/settings_screen.dart';

import 'helpers/test_app.dart';

Future<void> _open(WidgetTester tester, MockUser user, {Future<void> Function()? onSignOut}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(testApp(SettingsScreen(user: user, onSignOut: onSignOut)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows name, email, privacy and about', (tester) async {
    await _open(tester, MockUser(uid: 'u', displayName: 'Halima', email: 'h@example.com'));
    expect(find.text('Halima'), findsOneWidget);
    expect(find.text('h@example.com'), findsOneWidget);
    expect(find.textContaining('never gets names'), findsOneWidget);
    expect(find.text('Pantry Pal'), findsOneWidget);
  });

  testWidgets('says Not set when there is no name', (tester) async {
    await _open(tester, MockUser(uid: 'u', email: 'h@example.com'));
    expect(find.text('Not set'), findsOneWidget);
  });

  testWidgets('log out asks first, and Cancel keeps her signed in', (tester) async {
    var signedOut = false;
    await _open(tester, MockUser(uid: 'u', email: 'h@example.com'), onSignOut: () async => signedOut = true);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(signedOut, isFalse);
  });

  testWidgets('confirming log out signs out', (tester) async {
    var signedOut = false;
    await _open(tester, MockUser(uid: 'u', email: 'h@example.com'), onSignOut: () async => signedOut = true);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Log out')));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  testWidgets('tapping Name opens the rename dialog', (tester) async {
    await _open(tester, MockUser(uid: 'u', displayName: 'Halima', email: 'h@example.com'));
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.text('What should we call you?'), findsOneWidget);
  });
}
