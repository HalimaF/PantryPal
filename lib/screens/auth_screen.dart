import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Sign-up / log-in on one screen. Implements prd.md > Account.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signingUp = false;
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (_signingUp && name.isEmpty) {
      setState(() => _error = 'Please tell us your name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (_signingUp) {
        final cred = await auth.createUserWithEmailAndPassword(email: email, password: password);
        try {
          await cred.user?.updateDisplayName(name);
        } catch (_) {
          // The account exists; Home offers "Add your name" if saving the name failed.
        }
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      // main.dart listens to the login state and switches to Home by itself.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = friendlyAuthError(e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: terracottaSoft, shape: BoxShape.circle),
                      child: const Icon(Icons.soup_kitchen_rounded, size: 38, color: terracotta),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('What can I cook today?', style: text.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    'Know what to make from what is already at home.',
                    style: text.bodyLarge?.copyWith(color: mutedBrown, fontSize: 18),
                  ),
                  const SizedBox(height: 32),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Log in')),
                      ButtonSegment(value: true, label: Text('Sign up')),
                    ],
                    selected: {_signingUp},
                    onSelectionChanged: _busy
                        ? null
                        : (s) => setState(() {
                              _signingUp = s.first;
                              _error = null;
                            }),
                  ),
                  const SizedBox(height: 24),
                  if (_signingUp) ...[
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: _signingUp ? 'At least 6 characters' : null,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide password' : 'Show password',
                        icon: Icon(_showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE4E1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFB3261E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: Color(0xFF7A1A14), fontSize: 15)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                        : Text(_signingUp ? 'Create my account' : 'Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Turns Firebase's error codes into short, kind messages.
String friendlyAuthError(String code) {
  switch (code) {
    case 'invalid-email':
      return 'That email address doesn\'t look right.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Wrong email or password. Please try again.';
    case 'email-already-in-use':
      return 'This email already has an account. Try logging in.';
    case 'weak-password':
      return 'Please choose a password with at least 6 characters.';
    case 'network-request-failed':
      return 'No internet connection. Please check and try again.';
    case 'operation-not-allowed':
      return 'Email sign-up is not switched on in Firebase yet.';
    default:
      return 'Something went wrong ($code). Please try again.';
  }
}
