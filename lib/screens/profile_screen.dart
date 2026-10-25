import 'dart:async';

import 'package:flutter/material.dart';

import '../models/family_profile.dart';
import '../theme.dart';

/// Who mum cooks for and what they like. Implements prd.md > Features and Behavior > Profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.load, required this.onSave});

  /// The saved profile, read once. Handed in so the screen can be tested without Firebase.
  final Future<FamilyProfile> load;
  final Future<void> Function(FamilyProfile profile) onSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _PersonRow {
  _PersonRow({String age = '', this.gender = 'Female'}) : age = TextEditingController(text: age);
  final TextEditingController age;
  String gender;
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _country = TextEditingController();
  final _habits = TextEditingController();
  final List<_PersonRow> _people = [];
  final Set<String> _cuisines = {};
  String _spice = '';

  bool _loaded = false;
  bool _busy = false;
  String? _error;

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
      _country.text = saved.country;
      _habits.text = saved.habits;
      _spice = saved.spice;
      _cuisines
        ..clear()
        ..addAll(saved.cuisines);
      for (final p in saved.people) {
        _people.add(_PersonRow(age: p.age.toString(), gender: p.gender));
      }
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _country.dispose();
    _habits.dispose();
    for (final row in _people) {
      row.age.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final people = <Person>[];
    for (var i = 0; i < _people.length; i++) {
      final age = int.tryParse(_people[i].age.text.trim());
      if (age == null || age < 0 || age > 120) {
        setState(() => _error = 'Please type an age between 0 and 120 for person ${i + 1}.');
        return;
      }
      people.add(Person(age: age, gender: _people[i].gender));
    }
    final profile = FamilyProfile(
      people: people,
      country: _country.text.trim(),
      spice: _spice,
      cuisines: profileCuisines.where(_cuisines.contains).toList(),
      habits: _habits.text.trim(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    var savedOffline = false;
    try {
      // Without internet the phone keeps the change and sends it later, so do not wait forever.
      await widget.onSave(profile).timeout(const Duration(seconds: 8));
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
            : 'Saved. Dish ideas will now follow your family\'s tastes.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Family profile')),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text('Who are you cooking for?', style: text.titleLarge),
                  const SizedBox(height: 12),
                  if (_people.isEmpty)
                    Text(
                      'Add each person you cook for, so dishes suit your family.',
                      style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 16),
                    ),
                  for (var i = 0; i < _people.length; i++) _personRow(i),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: terracotta,
                      side: const BorderSide(color: terracotta),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => setState(() => _people.add(_PersonRow())),
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Add a person'),
                  ),
                  const SizedBox(height: 28),
                  Text('Where do you live?', style: text.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _country,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Country', hintText: 'For example: Pakistan'),
                  ),
                  const SizedBox(height: 28),
                  Text('How spicy does your family like it?', style: text.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final level in const ['Mild', 'Medium', 'Hot'])
                        _chip(
                          label: level,
                          selected: _spice == level,
                          // tapping the chosen one again clears it
                          onTap: () => setState(() => _spice = _spice == level ? '' : level),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('What kind of food do they like?', style: text.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final cuisine in profileCuisines)
                        _chip(
                          label: cuisine,
                          selected: _cuisines.contains(cuisine),
                          onTap: () => setState(() {
                            if (!_cuisines.remove(cuisine)) _cuisines.add(cuisine);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Anything else?', style: text.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _habits,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'For example: The men like desi food, the kids like junk food.',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
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
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.check_rounded),
                    label: const Text('Save'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Only you can see this. When the app asks the cooking helper (AI) for ideas, it '
                    'shares your family size, spice level and tastes, but never exact ages, names or email.',
                    style: text.bodyMedium?.copyWith(color: mutedBrown, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _personRow(int i) {
    final row = _people[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lineTan),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: TextField(
                controller: row.age,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  isDense: true,
                  semanticCounterText: 'Age of person ${i + 1}',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  for (final gender in const ['Female', 'Male'])
                    _chip(
                      label: gender,
                      selected: row.gender == gender,
                      onTap: () => setState(() => row.gender = gender),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove person ${i + 1}',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => setState(() {
                final removed = _people.removeAt(i);
                removed.age.dispose();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : inkBrown,
      ),
      selectedColor: terracotta,
      backgroundColor: Colors.white,
      side: const BorderSide(color: lineTan),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
