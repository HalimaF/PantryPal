import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/screens/auth_screen.dart';
import 'package:what_can_i_cook/theme.dart';

void main() {
  testWidgets('auth screen switches between log in and sign up', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(useWebFonts: false), home: const AuthScreen()),
    );

    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Create my account'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
  });

  test('friendlyAuthError gives kind messages', () {
    expect(friendlyAuthError('wrong-password'), contains('Wrong email or password'));
    expect(friendlyAuthError('weak-password'), contains('6 characters'));
    expect(friendlyAuthError('something-new'), contains('something-new'));
  });
}
