import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/family_profile.dart';
import '../ui/app_card.dart';
import '../ui/context_ext.dart';
import '../ui/labels.dart';
import '../ui/haptics.dart';
import '../ui/skeleton.dart';
import '../ui/status_chip.dart';
import '../ui/tokens.dart';

/// Who mum cooks for and what they like. Implements prd.md > Features and Behavior > Profile.
/// There is no Save button: every change is saved a moment later, and the chip at the top says so.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.load, required this.onSave});

  /// The saved profile, read once. Handed in so the screen can be tested without Firebase.
  final Future<FamilyProfile> load;
  final Future<void> Function(FamilyProfile profile) onSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _Saving { saved, saving, offline, failed }

const _spiceLevels = ['Mild', 'Medium', 'Hot'];
String _spiceHelp(AppLocalizations l10n, String level) => switch (level) {
      'Mild' => l10n.spiceHelpMild,
      'Hot' => l10n.spiceHelpHot,
      _ => l10n.spiceHelpMedium,
    };

class _ProfileScreenState extends State<ProfileScreen> {
  final _habits = TextEditingController();
  final List<Person> _people = [];
  final Set<String> _cuisines = {};
  String _spice = '';
  String _country = ''; // no box for it any more, but a saved value is kept

  bool _loaded = false;
  _Saving _state = _Saving.saved;
  bool _touched = false; // nothing is written until she changes something
  Timer? _debounce;

  int get _adults => _people.where((p) => p.age >= 12).length;
  int get _children => _people.where((p) => p.age < 12).length;

  @override
  void initState() {
    super.initState();
    // Never leave her stuck: if the profile does not arrive, she can still fill in a new one.
    widget.load
        .timeout(const Duration(seconds: 8))
        .then(_apply)
        .catchError((_) => _apply(FamilyProfile.empty));
  }

  void _apply(FamilyProfile saved) {
    if (!mounted) return;
    setState(() {
      _habits.text = saved.habits;
      _spice = saved.spice;
      _country = saved.country;
      _cuisines
        ..clear()
        ..addAll(saved.cuisines.where(profileCuisines.contains));
      _people
        ..clear()
        ..addAll(saved.people);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    // A change made in the last moment is still sent.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(widget.onSave(_build()).catchError((_) {}));
    }
    _habits.dispose();
    super.dispose();
  }

  FamilyProfile _build() => FamilyProfile(
        people: List.of(_people),
        country: _country,
        spice: _spice,
        cuisines: profileCuisines.where(_cuisines.contains).toList(),
        habits: _habits.text.trim(),
      );

  /// Called after every change: waits a moment for more changes, then saves once.
  void _changed() {
    _touched = true;
    _debounce?.cancel();
    setState(() => _state = _Saving.saving);
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    if (!_touched) return;
    setState(() => _state = _Saving.saving);
    try {
      // Without internet the phone keeps the change and sends it later, so do not wait forever.
      await widget.onSave(_build()).timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _state = _Saving.saved);
    } on TimeoutException {
      if (mounted) setState(() => _state = _Saving.offline);
    } catch (_) {
      if (mounted) setState(() => _state = _Saving.failed);
    }
  }

  void _setCount({required bool child, required int delta}) {
    Haptics.tick();
    setState(() {
      final isKind = child ? (Person p) => p.age < 12 : (Person p) => p.age >= 12;
      if (delta > 0) {
        _people.add(Person(age: child ? 8 : 35, gender: 'Female'));
      } else {
        final at = _people.lastIndexWhere(isKind);
        if (at >= 0) _people.removeAt(at);
      }
    });
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.xl),
            children: [
              Row(
                children: [
                  Expanded(child: Text(context.l10n.familyTitle, style: text.headlineMedium)),
                  _SaveChip(state: _state, onRetry: _save),
                ],
              ),
              const SizedBox(height: Space.m),
              if (!_loaded)
                SkeletonLoader.list(count: 3, itemHeight: 120)
              else ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.whoEats, style: text.titleLarge),
                      const SizedBox(height: Space.m),
                      Row(
                        children: [
                          Expanded(
                            child: _CountStepper(
                              label: context.l10n.adults,
                              value: _adults,
                              onLess: () => _setCount(child: false, delta: -1),
                              onMore: () => _setCount(child: false, delta: 1),
                            ),
                          ),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: _CountStepper(
                              label: context.l10n.childrenUnder12,
                              value: _children,
                              onLess: () => _setCount(child: true, delta: -1),
                              onMore: () => _setCount(child: true, delta: 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.m),
                AppCard(child: _spiceSection(context)),
                const SizedBox(height: Space.m),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.favCuisines, style: text.titleLarge),
                      const SizedBox(height: Space.m),
                      Wrap(
                        spacing: Space.s,
                        runSpacing: Space.s,
                        children: [
                          for (final cuisine in profileCuisines)
                            _CuisineChip(
                              label: cuisine,
                              shown: context.l10n.option(cuisine),
                              selected: _cuisines.contains(cuisine),
                              onTap: () {
                                Haptics.tick();
                                setState(() {
                                  if (!_cuisines.remove(cuisine)) _cuisines.add(cuisine);
                                });
                                _changed();
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.m),
                Text(context.l10n.anythingKnow, style: text.titleMedium),
                const SizedBox(height: Space.s),
                TextField(
                  controller: _habits,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _changed(),
                  decoration: InputDecoration(hintText: context.l10n.notesHint),
                ),
                const SizedBox(height: Space.s),
                AppCard(
                  color: colors.surfaceContainer,
                  borderColor: colors.surfaceContainer,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline_rounded, color: colors.primary),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Text(
                          context.l10n.privacyCard,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _spiceSection(BuildContext context) {
    final text = context.text;
    final colors = context.colors;
    // Until she chooses, the slider rests on Medium but nothing is saved for her.
    final shown = _spice.isEmpty ? 'Medium' : _spice;
    final index = _spiceLevels.indexOf(shown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(context.l10n.spiceLevel, style: text.titleLarge)),
            Text(context.l10n.option(shown), style: text.titleMedium?.copyWith(color: colors.primary)),
          ],
        ),
        Slider(
          value: index.toDouble(),
          min: 0,
          max: 2,
          divisions: 2,
          semanticFormatterCallback: (v) => _spiceLevels[v.round()],
          onChanged: (v) {
            final level = _spiceLevels[v.round()];
            if (level == shown && _spice.isNotEmpty) return;
            Haptics.tick();
            setState(() => _spice = level);
            _changed();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < _spiceLevels.length; i++)
              Row(
                children: [
                  for (var f = 0; f <= i; f++)
                    Icon(Icons.local_fire_department_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: Space.xs),
                  Text(context.l10n.option(_spiceLevels[i]), style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
          ],
        ),
        const SizedBox(height: Space.s),
        Text(_spiceHelp(context.l10n, shown), style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.state, required this.onRetry});
  final _Saving state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _Saving.saved:
        return StatusChip(label: context.l10n.savedJustNow, icon: Icons.cloud_done_outlined, tone: StatusTone.success);
      case _Saving.saving:
        return StatusChip(label: context.l10n.saving, icon: Icons.cloud_upload_outlined, tone: StatusTone.warning);
      case _Saving.offline:
        return StatusChip(
            label: context.l10n.savedOnPhone, icon: Icons.cloud_off_rounded, tone: StatusTone.warning);
      case _Saving.failed:
        return ActionChip(
          avatar: Icon(Icons.refresh_rounded, size: 18, color: context.colors.onErrorContainer),
          label: Text(context.l10n.couldNotSaveTry, style: TextStyle(color: context.colors.onErrorContainer)),
          backgroundColor: context.colors.errorContainer,
          onPressed: onRetry,
        );
    }
  }
}

/// A label, then minus, the number, and plus: tapping is easier than typing and cannot be wrong.
class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.label, required this.value, required this.onLess, required this.onMore});

  final String label;
  final int value;
  final VoidCallback onLess;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Semantics(
      container: true,
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              IconButton.outlined(
                tooltip: context.l10n.lessOf(label),
                onPressed: value > 0 ? onLess : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: ExcludeSemantics(
                  child: Text('$value', textAlign: TextAlign.center, style: text.titleLarge),
                ),
              ),
              IconButton.filledTonal(
                tooltip: context.l10n.moreOf(label),
                onPressed: value < 20 ? onMore : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CuisineChip extends StatelessWidget {
  const _CuisineChip({required this.label, required this.shown, required this.selected, required this.onTap});
  final String label;
  final String shown;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: shown,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: Corner.smallRadius,
          side: BorderSide(color: selected ? colors.primary : colors.outlineVariant, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: Corner.smallRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.m),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 18, color: colors.onPrimaryContainer),
                    const SizedBox(width: Space.xs),
                  ],
                  Text(shown,
                      style: context.text.labelLarge
                          ?.copyWith(color: selected ? colors.onPrimaryContainer : colors.onSurface)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
