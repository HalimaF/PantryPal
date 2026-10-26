import 'dart:async';

import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../models/meal.dart';
import '../services/gemini_service.dart';
import '../services/ingredient_matcher.dart';
import '../services/photo_picker.dart';
import '../theme.dart';

/// Say what you cooked and how much of each thing went in. Implements prd.md > Features and
/// Behavior > Log today's dish (the photo estimate comes later).
class LogDishScreen extends StatefulWidget {
  const LogDishScreen({
    super.key,
    required this.stock,
    required this.onSave,
    this.dishName = '',
    this.dishIngredients = const [],
    this.slot = 'Dinner',
    this.gemini,
    this.pickPhoto,
  });

  /// Her groceries, read once. Handed in so the screen can be tested without Firebase.
  final Future<List<InventoryItem>> stock;

  /// Saves the log and takes the amounts out of her groceries.
  final Future<void> Function(LogMealRequest request) onSave;

  final String dishName;
  final List<String> dishIngredients; // main ingredients of the dish, to put those first
  final String slot;
  final GeminiService? gemini;

  /// Opens the camera or gallery. Replaceable in tests.
  final PhotoPicker? pickPhoto;

  @override
  State<LogDishScreen> createState() => _LogDishScreenState();
}

class _LogDishScreenState extends State<LogDishScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.dishName);
  final Map<String, TextEditingController> _amounts = {};
  late String _slot = widget.slot == 'Lunch' ? 'Lunch' : 'Dinner';

  late final GeminiService _gemini = widget.gemini ?? GeminiService();

  bool _estimating = false;
  String? _estimateNote;

  List<InventoryItem>? _items; // null while loading
  Set<String> _inDish = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inDish = {
      for (final i in widget.dishIngredients) ?canonicalIngredient(i),
    };
    // Never leave her stuck on a spinner: with no groceries she can still log the dish.
    widget.stock.timeout(const Duration(seconds: 8)).then((items) {
      if (!mounted) return;
      _setItems(items);
    }).catchError((_) {
      if (mounted) _setItems(const []);
    });
  }

  void _setItems(List<InventoryItem> items) {
    // Things in this dish come first, so the likely ones are at the top.
    final sorted = [...items]..sort((a, b) {
        final aIn = _inDish.contains(canonicalIngredient(a.name)) ? 0 : 1;
        final bIn = _inDish.contains(canonicalIngredient(b.name)) ? 0 : 1;
        if (aIn != bIn) return aIn.compareTo(bIn);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    for (final item in sorted) {
      _amounts[item.id] = TextEditingController();
    }
    setState(() => _items = sorted);
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Looks at a photo of the cooked dish and fills in a guess for each item. She checks it.
  Future<void> _estimate(PhotoSource source) async {
    final items = _items ?? const <InventoryItem>[];
    PickedPhoto? photo;
    try {
      photo = await (widget.pickPhoto ?? pickPhotoFromDevice)(source);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the photos. Please type the amounts.');
      return;
    }
    if (photo == null || !mounted) return; // she backed out
    setState(() {
      _estimating = true;
      _error = null;
      _estimateNote = null;
    });
    var guesses = const <UsedEstimate>[];
    var failed = false;
    try {
      guesses = await _gemini.estimateUsed(
        photo.bytes,
        photo.mimeType,
        dishName: _name.text,
        stock: items,
      );
    } on GeminiException {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _estimating = false;
      for (final g in guesses) {
        _amounts[g.itemId]?.text = formatAmount(g.amount);
      }
      _estimateNote = guesses.isNotEmpty
          ? 'I guessed these amounts from your photo. Please check them.'
          : failed
              ? 'I could not read that photo. Please type the amounts.'
              : 'I could not work out the amounts from that photo. Please type them.';
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please type the name of the dish you cooked.');
      return;
    }
    final used = <UsedAmount>[];
    for (final item in _items ?? const <InventoryItem>[]) {
      final raw = _amounts[item.id]!.text.trim();
      if (raw.isEmpty) continue;
      final amount = parseAmount(raw);
      if (amount == null) {
        setState(() => _error = 'Please check the amount for ${item.name}. Use a number like 0.5.');
        return;
      }
      used.add(UsedAmount(
        id: item.id,
        name: item.name,
        unit: item.unit,
        amount: amount,
        left: item.amount,
      ));
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var savedOffline = false;
    try {
      // Without internet the phone keeps the change and sends it later, so do not wait forever.
      await widget
          .onSave(LogMealRequest(dishName: name, slot: _slot, used: used))
          .timeout(const Duration(seconds: 8));
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
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(savedOffline
            ? 'Saved on your phone. It will sync when you are online.'
            : 'Logged $name. Your groceries are updated.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: const Text("Log today's dish")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'What did you cook?',
                hintText: 'For example: Chicken pulao',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final option in const ['Lunch', 'Dinner'])
                  ChoiceChip(
                    label: Text(option),
                    selected: _slot == option,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _slot = option),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _slot == option ? Colors.white : inkBrown,
                    ),
                    selectedColor: terracotta,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: lineTan),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            Text('How much did you use?', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'An estimate is fine. Leave blank anything you did not use.',
              style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 15),
            ),
            if (items != null && items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _estimating ? null : () => _estimate(PhotoSource.camera),
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Photo of the dish'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _estimating ? null : () => _estimate(PhotoSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose a photo'),
                    ),
                  ),
                ],
              ),
              if (_estimating || _estimateNote != null) ...[
                const SizedBox(height: 10),
                _estimating
                    ? Row(
                        children: [
                          const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5)),
                          const SizedBox(width: 12),
                          Text('Estimating from your photo…', style: text.bodyMedium),
                        ],
                      )
                    : Text(_estimateNote!,
                        style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 15)),
              ],
            ],
            const SizedBox(height: 14),
            if (items == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Text(
                'You have no groceries saved, so nothing will be taken out. '
                'You can still add this dish to your log.',
                style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16, height: 1.4),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: lineTan),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 16, color: lineTan),
                      _UsedRow(
                        item: items[i],
                        controller: _amounts[items[i].id]!,
                        inDish: _inDish.contains(canonicalIngredient(items[i].name)),
                      ),
                    ],
                  ],
                ),
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
            FilledButton.icon(
              onPressed: (_busy || items == null) ? null : _save,
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              label: const Text('Save to my log'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsedRow extends StatelessWidget {
  const _UsedRow({required this.item, required this.controller, required this.inDish});

  final InventoryItem item;
  final TextEditingController controller;
  final bool inDish;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: text.titleMedium),
                Text(
                  inDish
                      ? '${formatAmount(item.amount)} ${item.unit} left · in this dish'
                      : '${formatAmount(item.amount)} ${item.unit} left',
                  style: text.bodyMedium?.copyWith(
                    color: inDish ? leafGreen : mutedBrown,
                    fontSize: 14,
                    fontWeight: inDish ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 112,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Used',
                suffixText: item.unit,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
