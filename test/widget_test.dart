import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/screens/auth_screen.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('auth screen switches between sign in and create an account', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(const AuthScreen()),
    );

    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Create my account'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(find.byKey(const Key('name')), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  test('friendlyAuthError gives kind messages', () {
    expect(friendlyAuthError('wrong-password'), contains('Wrong email or password'));
    expect(friendlyAuthError('weak-password'), contains('6 characters'));
    expect(friendlyAuthError('something-new'), contains('something-new'));
  });
}
