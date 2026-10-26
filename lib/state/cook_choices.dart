import 'package:shared_preferences/shared_preferences.dart';

/// Meal, weight and base she picked last time, so the filters start where she left them
/// (recognition rather than recall). Falls back to Dinner, Light, Roti when nothing is saved.
class CookChoices {
  const CookChoices({this.meal = 'Dinner', this.weight = 'Light', this.base = 'Roti'});

  static const meals = ['Lunch', 'Dinner'];
  static const weights = ['Light', 'Medium', 'Heavy'];
  static const bases = ['Rice', 'Roti', 'Bread', 'Any'];

  final String meal;
  final String weight;
  final String base;

  CookChoices copyWith({String? meal, String? weight, String? base}) =>
      CookChoices(meal: meal ?? this.meal, weight: weight ?? this.weight, base: base ?? this.base);

  /// A saved value that is no longer offered (like the old "Noodles") becomes the default.
  static String _pick(String? saved, List<String> allowed, String fallback) =>
      allowed.contains(saved) ? saved! : fallback;

  static Future<CookChoices> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return CookChoices(
        meal: _pick(prefs.getString('cook_meal'), meals, 'Dinner'),
        weight: _pick(prefs.getString('cook_weight'), weights, 'Light'),
        base: _pick(prefs.getString('cook_base'), bases, 'Roti'),
      );
    } catch (_) {
      return const CookChoices(); // remembering is a convenience, never a reason to fail
    }
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cook_meal', meal);
      await prefs.setString('cook_weight', weight);
      await prefs.setString('cook_base', base);
    } catch (_) {}
  }
}
