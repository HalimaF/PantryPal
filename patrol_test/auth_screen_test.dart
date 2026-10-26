import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart' show FilledButton, Icons, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:what_can_i_cook/firebase_options.dart';
import 'package:what_can_i_cook/main.dart';

void main() {
  // Runs the real app on the phone. Starts logged out (see clearPackageData in build.gradle.kts),
  // and only taps around the login screen, so it needs no account and writes nothing.
  patrolTest('the login screen switches to sign up and asks for a name', ($) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await $.pumpWidgetAndSettle(const WhatCanICookApp());

    expect($('What can I cook today?'), findsOneWidget);
    expect($('Your name'), findsNothing);

    await $('Sign up').tap();
    expect($('Your name'), findsOneWidget);
    expect($('Create my account'), findsOneWidget);

    await $('Log in').tap();
    expect($('Your name'), findsNothing);
  });

  patrolTest('logging in with nothing typed explains what is missing', ($) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await $.pumpWidgetAndSettle(const WhatCanICookApp());

    await $(FilledButton).tap();
    expect($('Please enter your email and password.'), findsOneWidget);
  });

  patrolTest('signing up needs a name first', ($) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await $.pumpWidgetAndSettle(const WhatCanICookApp());

    await $('Sign up').tap();
    await $('Create my account').tap();
    expect($('Please tell us your name.'), findsOneWidget);
  });

  patrolTest('with a name typed, signing up still needs an email and password', ($) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await $.pumpWidgetAndSettle(const WhatCanICookApp());

    await $('Sign up').tap();
    await $(TextField).at(0).enterText('Halima'); // the first box is the name
    await $('Create my account').tap();
    expect($('Please enter your email and password.'), findsOneWidget);
  });

  patrolTest('the eye icon shows and hides the password', ($) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await $.pumpWidgetAndSettle(const WhatCanICookApp());

    expect($(Icons.visibility_outlined), findsOneWidget);
    await $(Icons.visibility_outlined).tap();
    expect($(Icons.visibility_off_outlined), findsOneWidget);
    await $(Icons.visibility_off_outlined).tap();
    expect($(Icons.visibility_outlined), findsOneWidget);
  });
}
