import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// Home hub. Slice 1 only has placeholder actions; later slices fill them in.
/// Implements prd.md > Screens and Layout (Home dashboard).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  Future<void> _askName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What should we call you?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Your name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // The controller is not disposed here: the dialog is still fading out and would crash.
    if (name != null && name.isNotEmpty) await user.updateDisplayName(name);
  }

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name is coming in the next steps.')));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = user.displayName?.trim() ?? '';

    // One gentle entrance for the whole page, then it stays still.
    return Scaffold(
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? _greeting() : '${_greeting()}, $name',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        if (name.isEmpty)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(48, 40),
                              foregroundColor: terracotta,
                            ),
                            onPressed: () => _askName(context),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Add your name'),
                          )
                        else
                          Text("What's on the menu today?",
                              style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Log out',
                    style: IconButton.styleFrom(
                      backgroundColor: creamDeep,
                      foregroundColor: inkBrown,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _CookPanel(onTap: () => _soon(context, 'Dish suggestion')),
              const SizedBox(height: 28),
              Text('Your groceries', style: text.titleLarge),
              const SizedBox(height: 12),
              _GroceriesEmpty(onAdd: () => _soon(context, 'Add groceries')),
              const SizedBox(height: 28),
              Text('More', style: text.titleLarge),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lineTan),
                ),
                child: Column(
                  children: [
                    _MoreRow(
                      icon: Icons.menu_book_rounded,
                      title: 'Daily log',
                      subtitle: 'What you cooked and used',
                      onTap: () => _soon(context, 'Daily log'),
                    ),
                    const Divider(height: 1, indent: 72, color: lineTan),
                    _MoreRow(
                      icon: Icons.family_restroom_rounded,
                      title: 'Family profile',
                      subtitle: 'Tastes, ages and habits',
                      onTap: () => _soon(context, 'Profile'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The main action: asking what to cook is the heart of the app.
class _CookPanel extends StatelessWidget {
  const _CookPanel({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: terracotta,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(Icons.ramen_dining_rounded,
                  size: 140, color: Colors.white.withValues(alpha: 0.14)),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What can I cook?',
                      style: text.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Get dish ideas from what is at home, without repeating this week\'s meals.',
                    style: text.bodyLarge?.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get ideas',
                            style: text.bodyLarge
                                ?.copyWith(color: terracotta, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: terracotta, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown until the first groceries are added (prd.md > States and Boundaries).
class _GroceriesEmpty extends StatelessWidget {
  const _GroceriesEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineTan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: creamDeep, shape: BoxShape.circle),
                child: const Icon(Icons.shopping_basket_rounded, color: mutedBrown),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text('No groceries yet', style: text.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Add this month\'s shopping and I will keep track of what is left and how many days until your next trip.',
            style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: terracottaSoft,
              foregroundColor: terracotta,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add groceries'),
          ),
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: creamDeep,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: inkBrown),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(subtitle,
                      style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: mutedBrown),
          ],
        ),
      ),
    );
  }
}
