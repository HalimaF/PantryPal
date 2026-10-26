import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ui/app_button.dart';
import '../ui/context_ext.dart';
import '../ui/tokens.dart';

/// Sign-in and sign-up on one screen. Implements prd.md > Account.
/// Errors sit next to the field that caused them and say how to fix it.
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
  String? _emailError;
  String? _error; // anything that is not about one field
  String? _info; // good news, like "we sent a reset link"

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(bool signingUp) => setState(() {
        _signingUp = signingUp;
        _error = null;
        _info = null;
        _emailError = null;
      });

  /// A cheap check so a typo is caught before the internet is used.
  static bool _looksLikeEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _error = null;
      _info = null;
      _emailError = null;
    });
    if (_signingUp && name.isEmpty) {
      setState(() => _error = 'Please tell us your name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    if (!_looksLikeEmail(email)) {
      setState(() => _emailError = 'Add the full address, like name@gmail.com');
      return;
    }
    setState(() => _busy = true);
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

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    setState(() {
      _error = null;
      _info = null;
      _emailError = null;
    });
    if (!_looksLikeEmail(email)) {
      setState(() => _emailError = 'Type your email above first, then tap Forgot password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _info = 'We sent a link to $email. Open it to choose a new password.');
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = friendlyAuthError(e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(title: 'Pantry Pal', subtitle: 'Decide dinner in a minute, from what is already in your kitchen.'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.l),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_signingUp) ...[
                          Text('Your name', style: text.labelMedium),
                          const SizedBox(height: Space.xs),
                          TextField(
                            key: const Key('name'),
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: const InputDecoration(hintText: 'For example: Ayesha'),
                          ),
                          const SizedBox(height: Space.m),
                        ],
                        Text('Email', style: text.labelMedium),
                        const SizedBox(height: Space.xs),
                        TextField(
                          key: const Key('email'),
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            hintText: 'name@gmail.com',
                            error: _emailError == null ? null : _FieldError(_emailError!),
                            enabledBorder: _emailError == null
                                ? null
                                : OutlineInputBorder(
                                    borderRadius: Corner.mediumRadius,
                                    borderSide: BorderSide(color: colors.error, width: 2),
                                  ),
                          ),
                        ),
                        const SizedBox(height: Space.m),
                        Text('Password', style: text.labelMedium),
                        const SizedBox(height: Space.xs),
                        TextField(
                          key: const Key('password'),
                          controller: _password,
                          obscureText: !_showPassword,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            helperText: _signingUp ? 'At least 6 characters' : null,
                            suffixIcon: TextButton.icon(
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                              icon: Icon(
                                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 20,
                              ),
                              label: Text(_showPassword ? 'Hide' : 'Show'),
                            ),
                          ),
                        ),
                        if (!_signingUp)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton(
                              onPressed: _busy ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: Space.s),
                          _Notice(message: _error!, error: true),
                        ],
                        if (_info != null) ...[
                          const SizedBox(height: Space.s),
                          _Notice(message: _info!, error: false),
                        ],
                        const SizedBox(height: Space.m),
                        AppButton(
                          label: _signingUp ? 'Create my account' : 'Sign in',
                          loading: _busy,
                          loadingLabel: _signingUp ? 'Creating your account…' : 'Signing in…',
                          onPressed: _submit,
                        ),
                        const SizedBox(height: Space.s),
                        AppButton(
                          label: _signingUp ? 'I already have an account' : 'Create an account',
                          kind: AppButtonKind.secondary,
                          onPressed: _busy ? null : () => _switchMode(!_signingUp),
                        ),
                        const SizedBox(height: Space.l),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 16, color: colors.onSurfaceVariant),
                            const SizedBox(width: Space.xs),
                            Flexible(
                              child: Text(
                                'Your groceries and family details stay private to your account.',
                                textAlign: TextAlign.center,
                                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The red top of the page with two dishes peeking in from the corners.
class _Hero extends StatelessWidget {
  const _Hero({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Corner.large + 4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            PositionedDirectional(
              start: -36,
              top: 8,
              child: _Plate(icon: Icons.bakery_dining_rounded, size: 112, tone: const Color(0xFFF2C77A)),
            ),
            PositionedDirectional(
              end: -8,
              top: -8,
              child: _Plate(icon: Icons.ramen_dining_rounded, size: 120, tone: const Color(0xFFFFF7EC)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 140, Space.l, Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(header: true, child: Text(title, style: text.headlineMedium?.copyWith(color: colors.onPrimary))),
                  const SizedBox(height: Space.s),
                  Text(subtitle, style: text.bodyMedium?.copyWith(color: colors.onPrimary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.icon, required this.size, required this.tone});
  final IconData icon;
  final double size;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.55, color: context.colors.primary),
      ),
    );
  }
}

/// An icon plus words, so an error never relies on colour alone.
class _FieldError extends StatelessWidget {
  const _FieldError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.error;
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 16, color: color),
        const SizedBox(width: Space.xs),
        Expanded(child: Text(message, style: context.text.bodySmall?.copyWith(color: color))),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.error});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final back = error ? colors.errorContainer : context.appColors.successContainer;
    final ink = error ? colors.onErrorContainer : context.appColors.onSuccessContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(color: back, borderRadius: Corner.mediumRadius),
        child: Row(
          children: [
            Icon(error ? Icons.error_outline_rounded : Icons.mark_email_read_outlined, color: ink),
            const SizedBox(width: Space.s),
            Expanded(child: Text(message, style: context.text.bodyMedium?.copyWith(color: ink))),
          ],
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
      return 'This email already has an account. Try signing in.';
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
