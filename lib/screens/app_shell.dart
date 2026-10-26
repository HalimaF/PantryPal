import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/data_service.dart';
import '../ui/context_ext.dart';
import 'add_groceries_screen.dart';
import 'dish_suggestion_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// The four places she goes, always one tap away at thumb height (Hick's law: four tabs, no menus).
/// Each tab is built the first time it is opened and then kept, so nothing reloads when she switches.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user, this.data});

  final User user;
  final DataService? data;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final DataService _data = widget.data ?? DataService(widget.user.uid);
  int _index = 0;
  final _opened = <int>{0};

  void _go(int i) => setState(() {
        _index = i;
        _opened.add(i);
      });

  Widget _tab(int i) {
    if (!_opened.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => HomeScreen(user: widget.user, data: _data, onOpenTab: _go),
      1 => AddGroceriesScreen(data: _data),
      2 => DishSuggestionScreen(data: _data),
      _ => ProfileScreen(load: _data.profileOnce(), onSave: _data.saveProfile),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(index: _index, children: [for (var i = 0; i < 4; i++) _tab(i)]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.tabHome),
          NavigationDestination(
              icon: const Icon(Icons.shopping_basket_outlined),
              selectedIcon: const Icon(Icons.shopping_basket_rounded),
              label: l10n.tabGroceries),
          NavigationDestination(
              icon: const Icon(Icons.soup_kitchen_outlined),
              selectedIcon: const Icon(Icons.soup_kitchen_rounded),
              label: l10n.tabCook),
          NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: const Icon(Icons.people_rounded),
              label: l10n.tabFamily),
        ],
      ),
    );
  }
}
