import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/days_left.dart';
import '../models/inventory_item.dart';
import '../services/data_service.dart';
import '../services/gemini_service.dart';
import '../services/photo_picker.dart';
import '../theme.dart';

/// Add the month's shopping by photo or by typing it in. Implements prd.md > Features and Behavior >
/// Add groceries. A photo only fills in the name: she still types how much, and can always correct it.
class AddGroceriesScreen extends StatefulWidget {
  const AddGroceriesScreen({super.key, required this.data, this.gemini, this.pickPhoto});

  final DataService data;
  final GeminiService? gemini;

  /// Opens the camera or gallery. Replaceable in tests.
  final PhotoPicker? pickPhoto;

  @override
  State<AddGroceriesScreen> createState() => _AddGroceriesScreenState();
}

/// One item found in a photo, still open to correction before it is added.
class _Detected {
  _Detected({required String name, double? amount, String? unit})
      : name = TextEditingController(text: name),
        amount = TextEditingController(text: amount == null ? '' : formatAmount(amount)),
        unit = unit != null && groceryUnits.contains(unit) ? unit : 'kg';

  final TextEditingController name;
  final TextEditingController amount;
  String unit;
  bool include = true;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _AddGroceriesScreenState extends State<AddGroceriesScreen> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  late final Stream<List<InventoryItem>> _inventory = widget.data.inventory();
  late final GeminiService _gemini = widget.gemini ?? GeminiService();

  PickedPhoto? _photo;
  bool _reading = false; // the photo is being looked at
  String? _photoNote;
  final List<_Detected> _detected = [];

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
    for (final d in _detected) {
      d.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  /// Takes or chooses a photo and asks Gemini what is in it. Every item found is listed so she can
  /// correct it and add them all at once.
  Future<void> _addByPhoto(PhotoSource source) async {
    PickedPhoto? photo;
    try {
      photo = await (widget.pickPhoto ?? pickPhotoFromDevice)(source);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the photos. Please type what you bought.');
      return;
    }
    if (photo == null || !mounted) return; // she backed out
    for (final d in _detected) {
      d.dispose();
    }
    setState(() {
      _photo = photo;
      _detected.clear();
      _reading = true;
      _error = null;
      _photoNote = null;
    });
    var items = const <IdentifiedItem>[];
    var failed = false;
    try {
      items = await _gemini.identifyItems(photo.bytes, photo.mimeType);
    } on GeminiException {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _reading = false;
      if (items.isNotEmpty) {
        _detected.addAll([
          for (final i in items) _Detected(name: i.name, amount: i.amount, unit: i.unit),
        ]);
        _photoNote = items.length == 1
            ? 'I found 1 item. Please check it.'
            : 'I found ${items.length} items. Please check them.';
      } else {
        _photoNote = failed
            ? 'I could not read that photo. Please type what it is.'
            : 'I could not tell what this is. Please type it.';
      }
    });
  }

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

  /// Saves the items and the shopping days together. [onSaved] clears whatever form they came from.
  Future<void> _commit(
    List<({String name, double amount, String unit})> items,
    VoidCallback onSaved,
  ) async {
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
        for (final i in items) widget.data.addItem(name: i.name, amount: i.amount, unit: i.unit),
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
    onSaved();
    setState(() => _busy = false);
    final one = items.first;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(savedOffline
            ? 'Saved on your phone. It will sync when you are online.'
            : items.length == 1
                ? 'Added ${one.name}, ${formatAmount(one.amount)} ${one.unit}.'
                : 'Added ${items.length} items.'),
      ));
  }

  void _clearPhoto() {
    for (final d in _detected) {
      d.dispose();
    }
    setState(() {
      _detected.clear();
      _photo = null;
      _photoNote = null;
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
    await _commit([(name: name, amount: amount, unit: _unit)], () {
      _name.clear();
      _amount.clear();
      _clearPhoto();
    });
  }

  /// Adds every ticked item found in the photo.
  Future<void> _addDetected() async {
    final items = <({String name, double amount, String unit})>[];
    for (final d in _detected.where((d) => d.include)) {
      final name = d.name.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'Please give every item a name, or untick it.');
        return;
      }
      final amount = parseAmount(d.amount.text);
      if (amount == null) {
        setState(() => _error = 'Please type how much $name, for example 1.5, or untick it.');
        return;
      }
      items.add((name: name, amount: amount, unit: d.unit));
    }
    if (items.isEmpty) return;
    await _commit(items, _clearPhoto);
  }

  Widget _detectedCard() {
    final text = Theme.of(context).textTheme;
    final selected = _detected.where((d) => d.include).length;
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Found in your photo', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Untick anything you do not want. Change a name or amount if it is wrong.',
            style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _detected.length; i++) ...[
            if (i > 0) const Divider(height: 20, color: lineTan),
            _detectedRow(i),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: _error!),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: (_busy || selected == 0) ? null : _addDetected,
            icon: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.add_rounded),
            label: Text(selected == 1 ? 'Add 1 item' : 'Add $selected items'),
          ),
        ],
      ),
    );
  }

  Widget _detectedRow(int i) {
    final d = _detected[i];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Checkbox(
            key: Key('detected-include-$i'),
            value: d.include,
            activeColor: terracotta,
            onChanged: (v) => setState(() => d.include = v ?? false),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              TextField(
                key: Key('detected-name-$i'),
                controller: d.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Item', isDense: true),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      key: Key('detected-amount-$i'),
                      controller: d.amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'How much', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      key: Key('detected-unit-$i'),
                      initialValue: d.unit,
                      decoration: const InputDecoration(labelText: 'Unit', isDense: true),
                      items: [
                        for (final u in groceryUnits) DropdownMenuItem(value: u, child: Text(u)),
                      ],
                      onChanged: (u) => setState(() => d.unit = u ?? d.unit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reading ? null : () => _addByPhoto(PhotoSource.camera),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Take a photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reading ? null : () => _addByPhoto(PhotoSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Choose a photo'),
                  ),
                ),
              ],
            ),
            if (_photo != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _photo!.bytes,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 64,
                        height: 64,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _reading
                        ? Row(
                            children: [
                              const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5)),
                              const SizedBox(width: 12),
                              Text('Reading your photo…', style: text.bodyMedium),
                            ],
                          )
                        : Text(_photoNote ?? '',
                            style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 15)),
                  ),
                ],
              ),
            ],
            if (_detected.isNotEmpty && !_reading) ...[
              const SizedBox(height: 12),
              _detectedCard(),
            ],
            const SizedBox(height: 16),
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
            if (_error != null && _detected.isEmpty) ...[
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: Text(message, style: const TextStyle(color: Color(0xFF7A1A14), fontSize: 15)),
          ),
        ],
      ),
    );
  }
}
