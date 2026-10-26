import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/days_left.dart';
import '../models/inventory_item.dart';
import '../models/meal.dart';
import '../services/data_service.dart';
import '../ui/app_button.dart';
import '../ui/app_card.dart';
import '../ui/context_ext.dart';
import '../ui/section_header.dart';
import '../ui/tokens.dart';
import 'add_groceries_screen.dart';
import 'daily_log_screen.dart';
import 'dish_suggestion_screen.dart';
import 'log_dish_screen.dart';
import 'settings_screen.dart';

/// Home tab: one big way to ask what to cook, how long the groceries will last, and what was
/// cooked this week. Implements prd.md > Screens and Layout (Home dashboard).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user, this.data, this.onOpenTab});

  final User user;

  /// Her saved data. Left out in the app, which makes its own; handed in by tests.
  final DataService? data;

  /// Switches the bottom tab (1 Groceries, 2 Cook, 3 Family). Without it, screens open on top instead.
  final ValueChanged<int>? onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October',
  'November', 'December',
];
const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class _HomeScreenState extends State<HomeScreen> {
  User get user => widget.user;

  // Made once, so the lists below are not reloaded every time the screen redraws.
  late final DataService _data = widget.data ?? DataService(widget.user.uid);
  late final Stream<List<InventoryItem>> _inventory = _data.inventory();
  late final Stream<ShoppingDates> _dates = _data.shoppingDates();
  late final Stream<List<MealEntry>> _meals = _data.meals();

  void _openTab(int tab, Widget fallback) {
    final go = widget.onOpenTab;
    if (go != null) {
      go(tab);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => fallback));
    }
  }

  void _openLogDish() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LogDishScreen(stock: _data.inventoryOnce(), onSave: _data.logMeal),
        ),
      );

  void _openDailyLog() => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DailyLogScreen(meals: _data.meals(), onLogDish: _openLogDish),
        ),
      );

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final name = user.displayName?.trim() ?? '';
    final now = DateTime.now();

    // One gentle entrance for the whole page, then it stays still.
    return SafeArea(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: context.motion(450),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.xl),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          Text(
                            name.isEmpty ? _greeting() : '${_greeting()}, $name',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineMedium,
                          ),
                          if (name.isEmpty)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: AlignmentDirectional.centerStart,
                              ),
                              onPressed: () => _askName(context),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Add your name'),
                            )
                          else
                            Text("What's on the menu today?",
                                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Settings',
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                      ),
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => SettingsScreen(user: user))),
                    ),
                  ],
                ),
                const SizedBox(height: Space.l),
                _Hero(onTap: () => _openTab(2, DishSuggestionScreen(data: _data))),
                const SizedBox(height: Space.l),
                _KitchenStock(
                  inventory: _inventory,
                  dates: _dates,
                  onAdd: () => widget.onOpenTab?.call(1),
                  canAdd: widget.onOpenTab != null,
                  onAddFallback: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => AddGroceriesScreen(data: _data))),
                ),
                const SizedBox(height: Space.l),
                SectionHeader('Cooked this week', actionLabel: 'Daily log', onAction: _openDailyLog),
                const SizedBox(height: Space.s),
                _CookedThisWeek(meals: _meals, onLog: _openLogDish),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The main action: asking what to cook is the heart of the app.
class _Hero extends StatelessWidget {
  const _Hero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: colors.primary, borderRadius: Corner.largeRadius),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -24,
            top: -24,
            child: ExcludeSemantics(
              child: Icon(Icons.ramen_dining_rounded, size: 150, color: colors.onPrimary.withValues(alpha: 0.16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    'What should we cook today?',
                    style: text.headlineMedium?.copyWith(color: colors.onPrimary),
                  ),
                ),
                const SizedBox(height: Space.s),
                Text(
                  "From what's at home, without repeating this week's meals.",
                  style: text.bodyMedium?.copyWith(color: colors.onPrimary),
                ),
                const SizedBox(height: Space.l),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.appColors.turmeric,
                      foregroundColor: context.appColors.onTurmeric,
                    ),
                    onPressed: onTap,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Suggest a dish'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// How long the groceries should last, the amounts, and the way to add more.
class _KitchenStock extends StatelessWidget {
  const _KitchenStock({
    required this.inventory,
    required this.dates,
    required this.onAdd,
    required this.canAdd,
    required this.onAddFallback,
  });

  final Stream<List<InventoryItem>> inventory;
  final Stream<ShoppingDates> dates;
  final VoidCallback onAdd;
  final bool canAdd;
  final VoidCallback onAddFallback;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryItem>>(
      stream: inventory,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateCard(message: 'Could not load your groceries. Please check your internet.');
        }
        if (!snapshot.hasData) {
          return const AppCard(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
        }
        final items = snapshot.data!;
        if (items.isEmpty) return _StockEmpty(onAdd: canAdd ? onAdd : onAddFallback);
        return StreamBuilder<ShoppingDates>(
          stream: dates,
          builder: (context, snap) => _StockCard(
            items: items,
            last: snap.data?.last,
            next: snap.data?.next,
            onSeeAll: canAdd ? onAdd : null,
          ),
        );
      },
    );
  }
}

/// A plain message inside a card, for failures that do not need a retry button.
class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => AppCard(
        color: context.colors.errorContainer,
        borderColor: context.colors.errorContainer,
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: context.colors.onErrorContainer),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.onErrorContainer)),
            ),
          ],
        ),
      );
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.items, required this.last, required this.next, required this.onSeeAll});

  final List<InventoryItem> items;
  final DateTime? last;
  final DateTime? next;
  final VoidCallback? onSeeAll;

  /// How far through the shopping cycle she is, 0 to 1, or null when a date is missing.
  double? get _progress {
    if (last == null || next == null) return null;
    final total = daysUntil(last!, next!);
    if (total <= 0) return null;
    return (daysUntil(last!, DateTime.now()) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final shown = items.take(5).toList();
    final progress = _progress;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('KITCHEN STOCK',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 0.8)),
              ),
              if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
          Text(daysUntilMessage(DateTime.now(), next), style: text.titleLarge),
          if (progress != null) ...[
            const SizedBox(height: Space.m),
            Semantics(
              label: 'Shopping cycle progress',
              value: '${(progress * 100).round()} percent',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, color: colors.secondary),
              ),
            ),
          ],
          const SizedBox(height: Space.m),
          for (final item in shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  Expanded(child: Text(item.name, style: text.bodyLarge)),
                  Text('${formatAmount(item.amount)} ${item.unit}',
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          if (items.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text('+ ${items.length - shown.length} more',
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            ),
          const Divider(height: Space.l),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total left', style: text.titleMedium),
              const SizedBox(width: Space.m),
              Expanded(
                child: Text(
                  describeTotals(totalsByUnit(items)),
                  textAlign: TextAlign.end,
                  style: text.titleMedium?.copyWith(color: colors.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Amounts are approximate.', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Shown until the first groceries are added (prd.md > States and Boundaries).
class _StockEmpty extends StatelessWidget {
  const _StockEmpty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_basket_rounded, color: context.colors.onSurfaceVariant),
              const SizedBox(width: Space.m),
              Expanded(child: Text('No groceries yet', style: context.text.titleLarge)),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(
            "Add this month's shopping and I will keep track of what is left and how many days until your next trip.",
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: Space.m),
          AppButton(
            label: 'Add groceries',
            icon: Icons.add_rounded,
            kind: AppButtonKind.secondary,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

/// A row of small cards, one per dish cooked in the last 7 days.
class _CookedThisWeek extends StatelessWidget {
  const _CookedThisWeek({required this.meals, required this.onLog});

  final Stream<List<MealEntry>> meals;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MealEntry>>(
      stream: meals,
      builder: (context, snapshot) {
        final text = context.text;
        final colors = context.colors;
        if (snapshot.hasError) return const SizedBox.shrink();
        if (!snapshot.hasData) return const SizedBox(height: 96);
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        final recent = snapshot.data!.where((m) => m.date.isAfter(cutoff)).toList();
        if (recent.isEmpty) {
          return AppCard(
            onTap: onLog,
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: colors.onSurfaceVariant),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text('Nothing cooked yet this week. Tap to log a dish.',
                      style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                ),
              ],
            ),
          );
        }
        return SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.s),
            itemBuilder: (context, i) {
              final m = recent[i];
              return SizedBox(
                width: 128,
                child: AppCard(
                  padding: const EdgeInsets.all(Space.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_short[m.date.weekday - 1].toUpperCase(),
                          style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: Space.xs),
                      Expanded(
                        child: Text(m.dishName,
                            maxLines: 3, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
