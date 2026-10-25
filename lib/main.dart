import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WhatCanICookApp());
}

class WhatCanICookApp extends StatelessWidget {
  const WhatCanICookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What Can I Cook?',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      // Firebase remembers the login, so this shows Home straight away on reopen.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(), // also fires when the name is saved
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          return user != null ? HomeScreen(user: user) : const AuthScreen();
        },
      ),
    );
  }
}
