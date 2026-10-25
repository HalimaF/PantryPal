import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/days_left.dart';
import '../models/inventory_item.dart';
import '../services/data_service.dart';
import '../theme.dart';

/// Add the month's shopping by typing it in. Implements prd.md > Features and Behavior > Add groceries
/// (the by-picture option comes in a later step).
class AddGroceriesScreen extends StatefulWidget {
  const AddGroceriesScreen({super.key, required this.data});

  final DataService data;

  @override
  State<AddGroceriesScreen> createState() => _AddGroceriesScreenState();
}

class _AddGroceriesScreenState extends State<AddGroceriesScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late final Stream<List<InventoryItem>> _inventory = widget.data.inventory();

  String _unit = 'kg';
  late DateTime _shopped = _today();
  late DateTime _next = sameDayNextMonth(_shopped);
  bool _nextEdited = false;
  bool _busy = false;
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    // Keep the dates she already set, as long as the next shopping is still ahead.
    widget.data.shoppingDates().first.then((saved) {
      if (!mounted) return;
      final next = saved.next;
      if (next != null && daysUntil(_today(), next) >= 0) {
        setState(() {
          _shopped = saved.last ?? _today();
          _next = next;
          _nextEdited = true;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  Future<void> _pickShopped() async {
    final picked = await _pick(_shopped);
    if (picked == null) return;
    setState(() {
      _shopped = picked;
      if (!_nextEdited) _next = sameDayNextMonth(picked);
    });
  }

  Future<void> _pickNext() async {
    final picked = await _pick(_next);
    if (picked == null) return;
    setState(() {
      _next = picked;
      _nextEdited = true;
    });
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final amount = parseAmount(_amount.text);
    if (name.isEmpty) {
      setState(() => _error = 'Please type what you bought, for example chicken.');
      return;
    }
    if (amount == null) {
      setState(() => _error = 'Please type how much, for example 1.5.');
      return;
    }
    if (daysUntil(_shopped, _next) <= 0) {
      setState(() => _error = 'The next shopping day must come after the day you shopped.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var savedOffline = false;
    try {
      // With no internet the phone keeps the change and sends it later, so do not wait forever.
      await Future.wait([
        widget.data.addItem(name: name, amount: amount, unit: _unit),
        widget.data.saveShoppingDates(last: _shopped, next: _next),
      ]).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      savedOffline = true;
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not save. Please check your internet and try again.';
          _busy = false;
        });
      }
      return;
    }
    if (!mounted) return;
    _name.clear();
    _amount.clear();
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(savedOffline
            ? 'Saved on your phone. It will sync when you are online.'
            : 'Added $name, ${formatAmount(amount)} $_unit.'),
      ));
  }

  Future<void> _confirmRemove(InventoryItem item) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${item.name}?'),
        content: const Text('It will disappear from your groceries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove == true) await widget.data.removeItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add groceries')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shopping days', style: text.titleLarge),
                  const SizedBox(height: 12),
                  _DateRow(label: 'I shopped on', date: _shopped, onTap: _pickShopped),
                  const Divider(height: 24, color: lineTan),
                  _DateRow(label: 'Next shopping', date: _next, onTap: _pickNext),
                  const SizedBox(height: 4),
                  Text(
                    daysUntilMessage(_shopped, _next),
                    style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('What did you buy?', style: text.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Item', hintText: 'For example: Chicken'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'How much', hintText: '1.5'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final u in groceryUnits) DropdownMenuItem(value: u, child: Text(u)),
                    ],
                    onChanged: (u) => setState(() => _unit = u ?? _unit),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _add,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.add_rounded),
              label: const Text('Add to my groceries'),
            ),
            const SizedBox(height: 10),
            const OutlinedButton(
              onPressed: null,
              child: Text('Add by picture (coming soon)'),
            ),
            const SizedBox(height: 28),
            Text('In your kitchen now', style: text.titleLarge),
            const SizedBox(height: 12),
            StreamBuilder<List<InventoryItem>>(
              stream: _inventory,
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <InventoryItem>[];
                if (snapshot.hasError) {
                  return Text('Could not load your groceries. Please check your internet.',
                      style: text.bodyMedium?.copyWith(color: mutedBrown));
                }
                if (items.isEmpty) {
                  return Text('Nothing added yet.',
                      style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16));
                }
                return _Card(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 16, color: lineTan),
                        ListTile(
                          title: Text(items[i].name, style: text.titleMedium),
                          subtitle: Text('${formatAmount(items[i].amount)} ${items[i].unit}'),
                          trailing: IconButton(
                            tooltip: 'Remove ${items[i].name}',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _confirmRemove(items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineTan),
      ),
      child: child,
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.date, required this.onTap});
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.titleMedium)),
            Text(formatShortDate(date),
                style: text.titleMedium?.copyWith(color: terracotta, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_month_rounded, color: terracotta),
          ],
        ),
      ),
    );
  }
}
