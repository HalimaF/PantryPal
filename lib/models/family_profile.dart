/// One person mum cooks for. Implements prd.md > Features and Behavior > Profile.
class Person {
  const Person({required this.age, required this.gender});

  final int age;
  final String gender; // Female or Male

  Map<String, dynamic> toMap() => {'age': age, 'gender': gender};
}

/// Who she cooks for and what they like, stored in users/{uid}.profile (spec.md > Data Model).
class FamilyProfile {
  const FamilyProfile({
    this.people = const [],
    this.country = '',
    this.spice = '',
    this.cuisines = const [],
    this.habits = '',
  });

  static const empty = FamilyProfile();

  final List<Person> people;
  final String country;
  final String spice; // '', Mild, Medium or Hot
  final List<String> cuisines;
  final String habits; // free text: "men like desi food, kids like junk food"

  /// Under 12 counts as a child.
  int get childCount => people.where((p) => p.age < 12).length;
  int get adultCount => people.length - childCount;

  bool get isEmpty =>
      people.isEmpty && country.isEmpty && spice.isEmpty && cuisines.isEmpty && habits.isEmpty;

  Map<String, dynamic> toMap() => {
        'people': [for (final p in people) p.toMap()],
        'country': country.trim(),
        'spice': spice,
        'cuisines': cuisines,
        'habits': habits.trim(),
      };

  /// Reads what Firestore returned. Anything missing or odd is skipped, never a crash.
  factory FamilyProfile.fromMap(Object? raw) {
    if (raw is! Map) return empty;
    final people = <Person>[];
    for (final p in (raw['people'] as List?) ?? const []) {
      if (p is! Map) continue;
      final age = p['age'];
      if (age is! num || age < 0 || age > 120) continue;
      final gender = p['gender'] == 'Male' ? 'Male' : 'Female';
      people.add(Person(age: age.toInt(), gender: gender));
    }
    final spice = raw['spice'];
    return FamilyProfile(
      people: people,
      country: (raw['country'] as String?) ?? '',
      spice: const ['Mild', 'Medium', 'Hot'].contains(spice) ? spice as String : '',
      cuisines: [
        for (final c in (raw['cuisines'] as List?) ?? const [])
          if (c is String && c.trim().isNotEmpty) c.trim(),
      ],
      habits: (raw['habits'] as String?) ?? '',
    );
  }

  /// A short description for the cooking helper (Gemini). It carries the family size and tastes,
  /// but never exact ages, genders, names or email.
  String summaryForAi() {
    if (isEmpty) return '';
    final parts = <String>[];
    if (people.isNotEmpty) {
      final children = childCount;
      parts.add('A family of ${people.length} ($adultCount adults, $children children)');
    }
    if (country.trim().isNotEmpty) parts.add('living in ${country.trim()}');
    final first = parts.join(' ');
    final extras = <String>[
      if (first.isNotEmpty) first,
      if (spice.isNotEmpty) 'They prefer ${spice.toLowerCase()} spice',
      if (cuisines.isNotEmpty) 'They like ${cuisines.join(', ')} food',
      if (habits.trim().isNotEmpty) 'Notes: ${_short(habits.trim(), 300)}',
    ];
    return '${extras.join('. ')}.';
  }

  static String _short(String text, int max) => text.length <= max ? text : text.substring(0, max);
}

const profileCuisines = ['Pakistani', 'Indian', 'Chinese', 'Arabic', 'Continental', 'Fast food'];
