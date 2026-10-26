import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ui/app_card.dart';
import '../ui/app_snackbar.dart';
import '../ui/confirm_dialog.dart';
import '../ui/context_ext.dart';
import '../ui/section_header.dart';
import '../ui/tokens.dart';

/// Her account and what the app does with her data. Opened from the gear on Home.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user, this.onSignOut});

  final User user;

  /// Replaceable in tests; the app signs out of Firebase.
  final Future<void> Function()? onSignOut;

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: user.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('What should we call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await user.updateDisplayName(name);
    if (context.mounted) AppSnackbar.show(context, 'Name saved');
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Log out?',
      message: 'Your groceries and family details stay saved. Log in again any time.',
      confirmLabel: 'Log out',
      destructive: false,
    );
    if (!ok) return;
    await (onSignOut ?? FirebaseAuth.instance.signOut)();
    if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final name = user.displayName?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Space.l),
              children: [
                const SectionHeader('Account'),
                const SizedBox(height: Space.s),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.person_outline_rounded,
                        title: 'Name',
                        value: name.isEmpty ? 'Not set' : name,
                        onTap: () => _rename(context),
                        trailing: Icons.edit_outlined,
                      ),
                      const Divider(),
                      _Row(icon: Icons.email_outlined, title: 'Email', value: user.email ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                const SectionHeader('Privacy'),
                const SizedBox(height: Space.s),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: context.colors.secondary),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Text(
                          'Your groceries and family details are private to your account. The AI only sees '
                          'family size, spice level and favourite cuisines. It never gets names, exact ages or your email.',
                          style: context.text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                const SectionHeader('About'),
                const SizedBox(height: Space.s),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      _Row(icon: Icons.soup_kitchen_rounded, title: 'Pantry Pal', value: 'Dish ideas from what is at home'),
                      Divider(),
                      _Row(
                        icon: Icons.info_outline_rounded,
                        title: 'Amounts and dishes',
                        value: 'Amounts are approximate. Dish ideas are suggestions, not guarantees.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xl),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.value, this.onTap, this.trailing});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minTouchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
          child: Row(
            children: [
              Icon(icon, color: colors.onSurfaceVariant),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    Text(value, style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null) Icon(trailing, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
