import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_can_i_cook/screens/app_shell.dart';
import 'package:what_can_i_cook/screens/auth_screen.dart';
import 'package:what_can_i_cook/screens/settings_screen.dart';
import 'package:what_can_i_cook/services/data_service.dart';
import 'package:what_can_i_cook/state/app_locale.dart';

import 'helpers/test_app.dart';

Map<String, dynamic> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => arb.keys.where((k) => !k.startsWith('@')).toSet();

const _ur = Locale('ur');

void main() {
  group('the two language files', () {
    test('Urdu has every string English has, and nothing extra', () {
      final en = _keys(_arb('app_en')), ur = _keys(_arb('app_ur'));
      expect(en.difference(ur), isEmpty, reason: 'missing from Urdu');
      expect(ur.difference(en), isEmpty, reason: 'only in Urdu');
    });

    test('no Urdu string is left as an English copy (except names and codes)', () {
      final en = _arb('app_en'), ur = _arb('app_ur');
      const sameOnPurpose = {'amountOf', 'emailHint', 'heroAltLine', 'languageEnglish', 'languageUrdu'};
      for (final key in _keys(ur)) {
        if (sameOnPurpose.contains(key)) continue;
        expect(ur[key], isNot(en[key]), reason: '$key is not translated');
      }
    });

    test('every placeholder used in English is also used in Urdu', () {
      final en = _arb('app_en'), ur = _arb('app_ur');
      final used = RegExp(r'\{(\w+)[,}]');
      for (final key in _keys(en)) {
        final a = used.allMatches(en[key] as String).map((m) => m.group(1)).toSet();
        final b = used.allMatches(ur[key] as String).map((m) => m.group(1)).toSet();
        expect(b, a, reason: 'placeholders differ in $key');
      }
    });
  });

  group('screens in Urdu', () {
    testWidgets('sign in is in Urdu and reads right to left', (tester) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(testApp(const AuthScreen(), locale: _ur));
      await tester.pumpAndSettle();

      expect(find.text('سائن ان کریں'), findsOneWidget);
      expect(find.text('نیا اکاؤنٹ بنائیں'), findsOneWidget);
      expect(find.text('پاس ورڈ بھول گئے؟'), findsOneWidget);
      expect(Directionality.of(tester.element(find.byType(AuthScreen))), TextDirection.rtl);
    });

    testWidgets('Home, Cook and Family tabs are in Urdu', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = DataService('u1', firestore: FakeFirebaseFirestore());
      await tester.pumpWidget(testApp(
        AppShell(user: MockUser(uid: 'u1', displayName: 'حلیمہ'), data: data),
        locale: _ur,
      ));
      await tester.pumpAndSettle();

      expect(find.text('ہوم'), findsOneWidget); // the bottom bar
      expect(find.text('ڈش تجویز کریں'), findsOneWidget);
      expect(find.textContaining('السلام علیکم'), findsOneWidget);
      expect(find.text('ابھی کوئی سامان نہیں'), findsOneWidget);

      await tester.tap(find.text('پکائیں'));
      await tester.pumpAndSettle();
      expect(find.text('کیا پکائیں'), findsOneWidget);
      expect(find.text('ہلکا'), findsOneWidget);

      await tester.tap(find.text('گھر والے'));
      await tester.pumpAndSettle();
      expect(find.text('گھر میں کون کھاتا ہے'), findsOneWidget);
    });

    testWidgets('the stored values stay English even when the screen is Urdu', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(900, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final data = DataService('u1', firestore: FakeFirebaseFirestore());
      await tester.pumpWidget(testApp(
        AppShell(user: MockUser(uid: 'u1', displayName: 'x'), data: data),
        locale: _ur,
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('پکائیں'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('دوپہر')); // Lunch
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cook_meal'), 'Lunch');
    });
  });

  group('the language switch', () {
    testWidgets('Settings switches the whole app to Urdu and remembers it', (tester) async {
      SharedPreferences.setMockInitialValues({});
      appLocale.value = const Locale('en');
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ValueListenableBuilder<Locale>(
        valueListenable: appLocale,
        builder: (_, locale, _) => testApp(
          SettingsScreen(user: MockUser(uid: 'u', email: 'h@example.com')),
          locale: locale,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);

      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      expect(find.text('زبان'), findsOneWidget);
      expect(find.text('Language'), findsNothing);
      expect((await SharedPreferences.getInstance()).getString('language'), 'ur');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
    });

    test('a saved choice is loaded when the app starts', () async {
      SharedPreferences.setMockInitialValues({'language': 'ur'});
      appLocale.value = const Locale('en');
      await loadAppLocale();
      expect(appLocale.value, const Locale('ur'));
      appLocale.value = const Locale('en');
    });

    test('an unknown saved value is ignored', () async {
      SharedPreferences.setMockInitialValues({'language': 'fr'});
      appLocale.value = const Locale('en');
      await loadAppLocale();
      expect(appLocale.value, const Locale('en'));
    });
  });
}
