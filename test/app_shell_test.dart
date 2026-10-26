import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_can_i_cook/screens/app_shell.dart';
import 'package:what_can_i_cook/services/data_service.dart';

import 'helpers/test_app.dart';

Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final data = DataService('u1', firestore: FakeFirebaseFirestore());
  await tester.pumpWidget(testApp(
    AppShell(user: MockUser(uid: 'u1', displayName: 'Halima'), data: data),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Home with four tabs', (tester) async {
    await _open(tester);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.textContaining(', Halima'), findsOneWidget);
  });

  testWidgets('each tab opens its screen and Home keeps its place', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping days'), findsOneWidget);

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Who are you cooking for?'), findsOneWidget);

    await tester.tap(find.text('Cook'));
    await tester.pumpAndSettle();
    expect(find.text('Tell me about today'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining(', Halima'), findsOneWidget);
  });

  testWidgets('Suggest a dish on Home switches to the Cook tab', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Suggest a dish'));
    await tester.pumpAndSettle();
    expect(find.text('Tell me about today'), findsOneWidget);
  });

  testWidgets('Add groceries on an empty Home switches to the Groceries tab', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Add groceries'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping days'), findsOneWidget);
  });
}
