import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/screens/auth_screen.dart';
import 'package:what_can_i_cook/theme.dart';

// These only cover what the login screen checks before it talks to Firebase, so they need no
// account and no internet.
Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(useWebFonts: false),
    home: const AuthScreen(),
  ));
  await tester.pumpAndSettle();
}

Finder get _submit => find.byType(FilledButton);

void main() {
  group('signing up', () {
    testWidgets('needs a name first', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('Please tell us your name.'), findsOneWidget);
    });

    testWidgets('a name made only of spaces is not a name', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), '   ');
      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('Please tell us your name.'), findsOneWidget);
    });

    testWidgets('with a name but no email or password, asks for them', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Halima');
      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('an email without a password is not enough', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextField, 'Your name'), 'Halima');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'halima@example.com');
      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('reminds her the password needs 6 characters', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });
  });

  group('logging in', () {
    testWidgets('with nothing typed asks for email and password', (tester) async {
      await _open(tester);

      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('does not ask for a name', (tester) async {
      await _open(tester);

      expect(find.text('Your name'), findsNothing);
      expect(find.text('At least 6 characters'), findsNothing);
    });

    testWidgets('an old message disappears when she switches between log in and sign up', (tester) async {
      await _open(tester);
      await tester.tap(_submit);
      await tester.pump();
      expect(find.text('Please enter your email and password.'), findsOneWidget);

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.text('Please enter your email and password.'), findsNothing);
    });

    testWidgets('typed text is kept when she switches mode', (tester) async {
      await _open(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'halima@example.com');

      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.text('halima@example.com'), findsOneWidget);
    });
  });

  group('the password box', () {
    bool hidden(WidgetTester tester) =>
        tester.widget<EditableText>(find.descendant(
          of: find.widgetWithText(TextField, 'Password'),
          matching: find.byType(EditableText),
        )).obscureText;

    testWidgets('hides what is typed, and can show it', (tester) async {
      await _open(tester);
      expect(hidden(tester), isTrue);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(hidden(tester), isFalse);

      await tester.tap(find.byTooltip('Hide password'));
      await tester.pump();
      expect(hidden(tester), isTrue);
    });
  });

  group('messages for each sign-in problem', () {
    const expected = {
      'invalid-email': "doesn't look right",
      'user-not-found': 'Wrong email or password',
      'wrong-password': 'Wrong email or password',
      'invalid-credential': 'Wrong email or password',
      'email-already-in-use': 'already has an account',
      'weak-password': '6 characters',
      'network-request-failed': 'No internet',
      'operation-not-allowed': 'not switched on',
    };

    for (final entry in expected.entries) {
      test(entry.key, () {
        expect(friendlyAuthError(entry.key), contains(entry.value));
      });
    }

    test('wrong email and wrong password give the same message, so nobody can guess who has an account', () {
      expect(friendlyAuthError('user-not-found'), friendlyAuthError('wrong-password'));
    });

    test('an unknown problem still gives a message, with its code for support', () {
      expect(friendlyAuthError('too-many-requests'), contains('too-many-requests'));
    });
  });
}
