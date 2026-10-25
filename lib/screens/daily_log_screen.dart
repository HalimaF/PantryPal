import 'package:flutter/material.dart';

import '../logic/days_left.dart';
import '../models/inventory_item.dart';
import '../models/meal.dart';
import '../theme.dart';

/// What was cooked, newest first. Implements prd.md > Features and Behavior > Daily log.
class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({super.key, required this.meals, required this.onLogDish});

  final Stream<List<MealEntry>> meals;
  final VoidCallback onLogDish;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily log')),
      body: SafeArea(
        child: StreamBuilder<List<MealEntry>>(
          stream: meals,
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                FilledButton.icon(
                  onPressed: onLogDish,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Log today's dish"),
                ),
                const SizedBox(height: 24),
                if (snapshot.hasError)
                  Text('Could not load your log. Please check your internet.',
                      style: text.bodyMedium?.copyWith(color: mutedBrown))
                else if (!snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.data!.isEmpty)
                  Text(
                    'Nothing logged yet. After you cook, tap the button above so the app knows what '
                    'your family ate and what is left in your kitchen.',
                    style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16, height: 1.4),
                  )
                else
                  ..._grouped(context, snapshot.data!),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _grouped(BuildContext context, List<MealEntry> entries) {
    final text = Theme.of(context).textTheme;
    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final entry in entries) {
      if (currentDay != entry.date) {
        currentDay = entry.date;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(_dayLabel(entry.date), style: text.titleLarge),
        ));
      }
      widgets.add(_MealCard(entry: entry));
      widgets.add(const SizedBox(height: 12));
    }
    return widgets;
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final days = daysUntil(now, day);
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    return formatShortDate(day);
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.entry});
  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final used = entry.used
        .map((u) => '${u.name} ${formatAmount(u.amount)} ${u.unit}')
        .join(', ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lineTan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry.dishName, style: text.titleMedium)),
              if (entry.slot.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: terracottaSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(entry.slot,
                      style: const TextStyle(
                          color: terracotta, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            used.isEmpty ? 'No ingredients recorded.' : 'Used: $used',
            style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 15, height: 1.35),
          ),
        ],
      ),
    );
  }
}
