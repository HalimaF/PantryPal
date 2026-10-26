import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../ui/app_card.dart';
import '../ui/app_snackbar.dart';
import '../ui/confirm_dialog.dart';
import '../state/app_locale.dart';
import '../ui/context_ext.dart';
import '../ui/segmented_choice.dart';
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
        title: Text(context.l10n.askNameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: context.l10n.askNameLabel),
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
    if (context.mounted) AppSnackbar.show(context, context.l10n.nameSaved);
  }

  Future<void> _signOut(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: context.l10n.logOutQ,
      message: context.l10n.logOutBody,
      confirmLabel: context.l10n.logOut,
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
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Space.l),
              children: [
                SectionHeader(context.l10n.account),
                const SizedBox(height: Space.s),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.person_outline_rounded,
                        title: context.l10n.nameLabel,
                        value: name.isEmpty ? context.l10n.notSet : name,
                        onTap: () => _rename(context),
                        trailing: Icons.edit_outlined,
                      ),
                      const Divider(),
                      _Row(icon: Icons.email_outlined, title: context.l10n.emailLabel, value: user.email ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                SectionHeader(context.l10n.language),
                const SizedBox(height: Space.s),
                AppCard(
                  child: ValueListenableBuilder<Locale>(
                    valueListenable: appLocale,
                    builder: (context, locale, _) => SegmentedChoice(
                      label: '',
                      options: const ['en', 'ur'],
                      selected: locale.languageCode,
                      labelOf: (code) => code == 'ur' ? context.l10n.languageUrdu : context.l10n.languageEnglish,
                      onSelected: (code) => setAppLocale(Locale(code)),
                    ),
                  ),
                ),
                const SizedBox(height: Space.l),
                SectionHeader(context.l10n.privacy),
                const SizedBox(height: Space.s),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: context.colors.secondary),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Text(
                          context.l10n.privacyBody,
                          style: context.text.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                SectionHeader(context.l10n.about),
                const SizedBox(height: Space.s),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _Row(icon: Icons.soup_kitchen_rounded, title: context.l10n.appName, value: context.l10n.aboutTag),
                      const Divider(),
                      _Row(
                        icon: Icons.info_outline_rounded,
                        title: context.l10n.amountsDishes,
                        value: context.l10n.aboutNote,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.xl),
                OutlinedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(context.l10n.logOut),
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
