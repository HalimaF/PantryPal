import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/days_left.dart';
import '../logic/item_matching.dart';
import '../models/inventory_item.dart';
import '../services/data_service.dart';
import '../services/gemini_service.dart';
import '../services/photo_picker.dart';
import '../ui/app_button.dart';
import '../ui/app_card.dart';
import '../ui/app_snackbar.dart';
import '../ui/confirm_dialog.dart';
import '../ui/context_ext.dart';
import '../ui/haptics.dart';
import '../ui/quantity_stepper.dart';
import '../ui/section_header.dart';
import '../ui/tokens.dart';

/// Add the month's shopping by photo or by typing it in. Everything goes onto one list first, she
/// checks it, and one button saves it all. Implements prd.md > Features and Behavior > Add groceries.
class AddGroceriesScreen extends StatefulWidget {
  const AddGroceriesScreen({super.key, required this.data, this.gemini, this.pickPhoto});

  final DataService data;
  final GeminiService? gemini;

  /// Opens the camera or gallery. Replaceable in tests.
  final PhotoPicker? pickPhoto;

  @override
  State<AddGroceriesScreen> createState() => _AddGroceriesScreenState();
}

/// One line on the list, still open to correction before it is saved.
class _Line {
  _Line({required this.name, this.amount, required String unit, this.fromPhoto = false})
      : unit = groceryUnits.contains(unit) ? unit : 'kg';

  String name;
  double? amount; // null: the photo did not show how much, so she must say
  String unit;
  final bool fromPhoto; // a new photo replaces the items the last photo added

  bool get needsCheck => amount == null;

  /// How much one tap on + or - changes the amount.
  double get step => switch (unit) {
        'g' || 'ml' => 50,
        'kg' || 'L' => 0.5,
        _ => 1,
      };
}

/// The things bought most often, one tap each. A starting amount she can change.
const _oftenBought = [
  (name: 'Onion', amount: 1.0, unit: 'kg'),
  (name: 'Atta', amount: 5.0, unit: 'kg'),
  (name: 'Milk', amount: 1.0, unit: 'L'),
  (name: 'Eggs', amount: 12.0, unit: 'pieces'),
];

class _AddGroceriesScreenState extends State<AddGroceriesScreen> {
  late final Stream<List<InventoryItem>> _inventory = widget.data.inventory();
  late final GeminiService _gemini = widget.gemini ?? GeminiService();

  final List<_Line> _draft = [];
  PickedPhoto? _photo;
  bool _reading = false; // the photo is being looked at
  String? _photoNote;

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

  /// Takes or chooses a photo and asks Gemini what is in it. Every item found goes onto the list
  /// so she can correct it.
  Future<void> _addByPhoto(PhotoSource source) async {
    PickedPhoto? photo;
    try {
      photo = await (widget.pickPhoto ?? pickPhotoFromDevice)(source);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the photos. Please type what you bought.');
      return;
    }
    if (photo == null || !mounted) return; // she backed out
    setState(() {
      _photo = photo;
      _draft.removeWhere((l) => l.fromPhoto); // a new photo replaces the last photo's items
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
        _draft.addAll([
          for (final i in items) _Line(name: i.name, amount: i.amount, unit: i.unit ?? 'kg', fromPhoto: true),
        ]);
        final check = items.where((i) => i.amount == null).length;
        _photoNote = 'We found ${items.length} ${items.length == 1 ? 'item' : 'items'} in your photo.'
            '${check == 0 ? '' : ' $check ${check == 1 ? 'needs' : 'need'} a check.'}';
      } else {
        _photoNote = failed
            ? 'I could not read that photo. Please type what it is.'
            : 'I could not tell what this is. Please type it.';
      }
    });
  }

  void _addLine(_Line line) {
    Haptics.success();
    setState(() {
      _draft.add(line);
      _error = null;
    });
  }

  /// Opens the form for typing one item, or for correcting a line already on the list.
  Future<void> _editLine({_Line? line}) async {
    final result = await showModalBottomSheet<_LineEdit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LineSheet(line: line),
    );
    if (result == null || !mounted) return;
    if (result.remove && line != null) {
      setState(() => _draft.remove(line));
      return;
    }
    setState(() {
      if (line == null) {
        _draft.add(_Line(name: result.name, amount: result.amount, unit: result.unit));
      } else {
        line
          ..name = result.name
          ..amount = result.amount
          ..unit = result.unit;
      }
      _error = null;
    });
  }

  /// Saves every line and the shopping days together.
  Future<void> _saveAll() async {
    final missing = _draft.where((l) => l.needsCheck).toList();
    if (missing.isNotEmpty) {
      setState(() => _error = 'Please say how much ${missing.first.name}, or remove it.');
      return;
    }
    if (daysUntil(_shopped, _next) <= 0) {
      setState(() => _error = 'The next shopping day must come after the day you shopped.');
      return;
    }
    final items = [for (final l in _draft) (name: l.name.trim(), amount: l.amount!, unit: l.unit)];
    setState(() {
      _busy = true;
      _error = null;
    });
    var savedOffline = false;
    var results = const <AddResult>[];
    try {
      // With no internet the phone keeps the change and sends it later, so do not wait forever.
      await Future.wait([
        widget.data
            .addItems([for (final i in items) NewItem(name: i.name, amount: i.amount, unit: i.unit)])
            .then((r) => results = r),
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
    Haptics.success();
    setState(() {
      _busy = false;
      _draft.clear();
      _photo = null;
      _photoNote = null;
    });
    AppSnackbar.show(context, _savedMessage(items, results, savedOffline));
  }

  /// What she is told after saving. When something was already in her kitchen, she is told its
  /// amount went up, so a second pack never looks like it was lost or duplicated.
  String _savedMessage(
    List<({String name, double amount, String unit})> items,
    List<AddResult> results,
    bool savedOffline,
  ) {
    if (savedOffline) return 'Saved on your phone. It will sync when you are online.';
    final raised = results.where((r) => r.merged).toList();
    if (items.length == 1) {
      if (raised.length == 1) {
        final r = raised.single;
        return '${r.name} was already in your kitchen, so now you have ${formatAmount(r.newTotal)} ${r.unit}.';
      }
      final one = items.first;
      return 'Added ${one.name}, ${formatAmount(one.amount)} ${one.unit}.';
    }
    if (raised.isEmpty) return 'Added ${items.length} items.';
    final names = raised.map((r) => r.name).toSet().join(', ');
    return 'Added ${items.length} items. $names ${raised.length == 1 ? 'was' : 'were'} already in your kitchen, so the amount went up.';
  }

  Future<void> _confirmRemove(InventoryItem item) async {
    final remove = await confirmAction(
      context,
      title: 'Remove ${item.name}?',
      message: 'It will disappear from your groceries.',
      confirmLabel: 'Remove',
    );
    if (remove) await widget.data.removeItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final needCheck = _draft.where((l) => l.needsCheck).length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _draft.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                child: AppButton(
                  label: _draft.length == 1 ? 'Save 1 item' : 'Save all ${_draft.length} items',
                  icon: Icons.check_rounded,
                  loading: _busy,
                  loadingLabel: 'Saving…',
                  onPressed: _saveAll,
                ),
              ),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
              children: [
                Text('Add groceries', style: text.headlineMedium),
                const SizedBox(height: Space.xs),
                Text("This month's shopping, by photo or by typing",
                    style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Expanded(
                      child: _BigChoice(
                        icon: Icons.photo_camera_rounded,
                        label: 'Take a photo',
                        highlighted: true,
                        onTap: _reading ? null : () => _addByPhoto(PhotoSource.camera),
                      ),
                    ),
                    const SizedBox(width: Space.s),
                    Expanded(
                      child: _BigChoice(
                        icon: Icons.edit_outlined,
                        label: 'Type it in',
                        onTap: () => _editLine(),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _reading ? null : () => _addByPhoto(PhotoSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Choose a photo'),
                  ),
                ),
                if (_reading && _photo != null) ...[
                  const SizedBox(height: Space.s),
                  _ReadingCard(photo: _photo!),
                ] else if (_photoNote != null) ...[
                  const SizedBox(height: Space.s),
                  _Banner(
                    message: _photoNote!,
                    warning: needCheck > 0 || _draft.isEmpty,
                    photo: _photo,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: Space.s),
                  _Banner(message: _error!, error: true),
                ],
                const SizedBox(height: Space.s),
                for (var i = 0; i < _draft.length; i++) ...[
                  _LineCard(
                    key: ObjectKey(_draft[i]),
                    line: _draft[i],
                    onEdit: () => _editLine(line: _draft[i]),
                    onAmount: (v) => setState(() => _draft[i].amount = v),
                  ),
                  const SizedBox(height: Space.s),
                ],
                const SizedBox(height: Space.s),
                Text('OFTEN BOUGHT',
                    style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, letterSpacing: 0.8)),
                const SizedBox(height: Space.s),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final o in _oftenBought)
                      ActionChip(
                        avatar: Icon(Icons.add_rounded, size: 18, color: colors.primary),
                        label: Text(o.name),
                        onPressed: () => _addLine(_Line(name: o.name, amount: o.amount, unit: o.unit)),
                      ),
                  ],
                ),
                const SizedBox(height: Space.l),
                const SectionHeader('Shopping days'),
                const SizedBox(height: Space.s),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateRow(label: 'I shopped on', date: _shopped, onTap: _pickShopped),
                      const Divider(height: Space.l),
                      _DateRow(label: 'Next shopping', date: _next, onTap: _pickNext),
                      const SizedBox(height: Space.xs),
                      Text(daysUntilMessage(_shopped, _next),
                          style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(height: Space.l),
                const SectionHeader('In your kitchen now'),
                const SizedBox(height: Space.s),
                StreamBuilder<List<InventoryItem>>(
                  stream: _inventory,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const <InventoryItem>[];
                    if (snapshot.hasError) {
                      return Text('Could not load your groceries. Please check your internet.',
                          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant));
                    }
                    if (items.isEmpty) {
                      return Text('Nothing added yet.',
                          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant));
                    }
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const Divider(),
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
        ),
      ),
    );
  }
}

/// A large tappable card with an icon above its label: "Take a photo", "Type it in".
class _BigChoice extends StatelessWidget {
  const _BigChoice({required this.icon, required this.label, required this.onTap, this.highlighted = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      semanticsLabel: label,
      borderColor: highlighted ? colors.primary : colors.outlineVariant,
      padding: const EdgeInsets.symmetric(vertical: Space.m, horizontal: Space.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: highlighted ? colors.primary : colors.onSurfaceVariant),
          const SizedBox(height: Space.xs),
          Text(label, textAlign: TextAlign.center, style: context.text.labelLarge),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.photo});
  final PickedPhoto photo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _Thumb(photo: photo),
          const SizedBox(width: Space.m),
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(width: Space.m),
          Expanded(child: Text('Reading your photo…', style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photo});
  final PickedPhoto photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: Corner.smallRadius,
      child: Image.memory(
        photo.bytes,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported_outlined)),
      ),
    );
  }
}

/// A message that says what happened and what to do: warm for "please check", red for a problem.
class _Banner extends StatelessWidget {
  const _Banner({required this.message, this.warning = false, this.error = false, this.photo});

  final String message;
  final bool warning;
  final bool error;
  final PickedPhoto? photo;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final app = context.appColors;
    final back = error ? colors.errorContainer : (warning ? app.warningContainer : app.successContainer);
    final ink = error ? colors.onErrorContainer : (warning ? app.onWarningContainer : app.onSuccessContainer);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(color: back, borderRadius: Corner.mediumRadius),
        child: Row(
          children: [
            if (photo != null) ...[_Thumb(photo: photo!), const SizedBox(width: Space.m)],
            Icon(
              error ? Icons.error_outline_rounded : (warning ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded),
              color: ink,
            ),
            const SizedBox(width: Space.s),
            Expanded(child: Text(message, style: context.text.bodyMedium?.copyWith(color: ink))),
          ],
        ),
      ),
    );
  }
}

/// One item with a stepper for how much. The ones that need a check are boxed in amber and say so.
class _LineCard extends StatelessWidget {
  const _LineCard({super.key, required this.line, required this.onEdit, required this.onAmount});

  final _Line line;
  final VoidCallback onEdit;
  final ValueChanged<double> onAmount;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    final app = context.appColors;
    final check = line.needsCheck;
    return AppCard(
      onTap: onEdit,
      semanticsLabel: check ? '${line.name}. Amount unclear. Tap to fix.' : null,
      color: check ? app.warningContainer : null,
      borderColor: check ? app.warning : null,
      padding: const EdgeInsets.all(Space.m),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: Corner.smallRadius),
            child: Icon(Icons.shopping_basket_rounded, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (check)
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: app.onWarningContainer),
                      const SizedBox(width: Space.xs),
                      Expanded(
                        child: Text('Amount unclear. Tap to fix.',
                            style: text.bodySmall?.copyWith(color: app.onWarningContainer)),
                      ),
                    ],
                  )
                else
                  Text(line.unit, style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (!check)
            QuantityStepper(
              value: line.amount!,
              onChanged: onAmount,
              unitLabel: line.unit,
              itemName: line.name,
              min: line.step,
              step: line.step,
            ),
        ],
      ),
    );
  }
}

class _LineEdit {
  const _LineEdit({required this.name, required this.amount, required this.unit, this.remove = false});
  final String name;
  final double? amount;
  final String unit;
  final bool remove;
}

/// The form for typing an item, or fixing one. Opens above the keyboard.
class _LineSheet extends StatefulWidget {
  const _LineSheet({this.line});
  final _Line? line;

  @override
  State<_LineSheet> createState() => _LineSheetState();
}

class _LineSheetState extends State<_LineSheet> {
  late final _name = TextEditingController(text: widget.line?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.line?.amount == null ? '' : formatAmount(widget.line!.amount!),
  );
  late String _unit = widget.line?.unit ?? 'kg';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _done() {
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
    Navigator.pop(context, _LineEdit(name: name, amount: amount, unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.line != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.l, 0, Space.l, MediaQuery.viewInsetsOf(context).bottom + Space.l),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Fix this item' : 'Type an item', style: context.text.titleLarge),
            const SizedBox(height: Space.m),
            TextField(
              key: const Key('line-name'),
              controller: _name,
              autofocus: !editing,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Item', hintText: 'For example: Chicken'),
            ),
            const SizedBox(height: Space.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    key: const Key('line-amount'),
                    controller: _amount,
                    autofocus: editing,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'How much', hintText: '1.5'),
                    onSubmitted: (_) => _done(),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    key: const Key('line-unit'),
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [for (final u in groceryUnits) DropdownMenuItem(value: u, child: Text(u))],
                    onChanged: (u) => setState(() => _unit = u ?? _unit),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: Space.s),
              _Banner(message: _error!, error: true),
            ],
            const SizedBox(height: Space.m),
            AppButton(label: editing ? 'Done' : 'Add to list', icon: Icons.add_rounded, onPressed: _done),
            if (editing)
              AppButton(
                label: 'Remove from list',
                kind: AppButtonKind.text,
                onPressed: () => Navigator.pop(
                  context,
                  _LineEdit(name: '', amount: null, unit: _unit, remove: true),
                ),
              ),
          ],
        ),
      ),
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
    final text = context.text;
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: Corner.smallRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minTouchTarget),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.titleMedium)),
            Text(formatShortDate(date), style: text.titleMedium?.copyWith(color: colors.primary)),
            const SizedBox(width: Space.s),
            Icon(Icons.calendar_month_rounded, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
