import 'dart:convert';
import 'dart:math';

import '../models/inventory_item.dart';

// Deciding when something she adds is something she already has, so a second pack of the same
// product raises the amount instead of making a second line. Plain code, no AI.
// Implements prd.md > Features and Behavior > Add groceries.

/// Words that do not make it a different product: "Shan Chaat Masala Powder" is "Shan Chaat Masala".
const _filler = {'powder', 'pack', 'packs', 'packet', 'packets', 'pkt', 'the', 'of', 'and'};

/// Different spellings of the same word.
const _spellings = {'chat': 'chaat', 'chatt': 'chaat', 'masalah': 'masala', 'masaala': 'masala'};

/// "500g", "1 L", "2.5kg", "ltr": amounts that sometimes end up inside a name.
final _quantityLike = RegExp(r'^\d+([.,]\d+)?(kg|kgs|g|gm|gms|l|ltr|litre|liter|ml)?$');
const _unitWords = {'kg', 'kgs', 'g', 'gm', 'gms', 'l', 'ltr', 'litre', 'liter', 'ml'};

String _tidyWord(String word) {
  var w = _spellings[word] ?? word;
  // "onions" and "onion", "tomatoes" and "tomato" are the same.
  if (w.length > 5 && w.endsWith('es')) {
    w = w.substring(0, w.length - 2);
  } else if (w.length > 3 && w.endsWith('s')) {
    w = w.substring(0, w.length - 1);
  }
  return w;
}

/// A name made comparable: lower case, no punctuation, no filler or quantities, words sorted.
/// "Shan Chat Masala (50g)" and "masala chaat SHAN" come out the same.
String normalizeItemName(String raw) {
  final cleaned = raw.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}.,]+', unicode: true), ' ');
  final words = [
    for (final word in cleaned.split(' '))
      if (word.isNotEmpty &&
          !_quantityLike.hasMatch(word) &&
          !_unitWords.contains(word) &&
          !_filler.contains(word))
        _tidyWord(word.replaceAll(RegExp(r'^[.,]+|[.,]+$'), '')),
  ]..removeWhere((w) => w.isEmpty);
  words.sort();
  return words.join(' ');
}

/// How many single-letter changes turn [a] into [b].
int editDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = min(min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
    }
    previous = current;
  }
  return previous[b.length];
}

/// True when two names are the same product, allowing a small spelling difference.
/// Short names must match exactly, so "milk" is never mistaken for "mild".
bool sameProduct(String a, String b) {
  final x = normalizeItemName(a);
  final y = normalizeItemName(b);
  if (x.isEmpty || y.isEmpty) return false;
  if (x == y) return true;
  final longest = max(x.length, y.length);
  if (longest < 8) return false;
  return editDistance(x, y) <= (longest <= 14 ? 1 : 2);
}

/// [amount] changed from one unit to another, or null when they cannot be added together
/// (kilograms and litres, for example).
double? convertAmount(double amount, String from, String to) {
  if (from == to) return amount;
  const weight = {'kg': 1.0, 'g': 0.001};
  const volume = {'L': 1.0, 'ml': 0.001};
  for (final family in [weight, volume]) {
    if (family.containsKey(from) && family.containsKey(to)) {
      return amount * family[from]! / family[to]!;
    }
  }
  const count = {'pieces', 'packs'};
  if (count.contains(from) && count.contains(to)) return amount;
  return null;
}

/// Something to add to her groceries.
class NewItem {
  const NewItem({required this.name, required this.amount, required this.unit});

  final String name;
  final double amount;
  final String unit;
}

/// What happened to one [NewItem]: made a new line, or raised an existing one.
class AddResult {
  const AddResult({
    required this.docId,
    required this.name,
    required this.unit,
    required this.added,
    required this.merged,
    required this.newTotal,
  });

  final String docId; // the grocery line that is changed
  final String name; // the name on that line (the existing name when merged)
  final String unit; // the unit of that line
  final double added; // in [unit]
  final bool merged; // true when it was already there
  final double newTotal; // what the line holds afterwards
}

/// The grocery line for a name and unit, the same every time and safe in any language.
String itemDocId(String name, String unit) =>
    base64Url.encode(utf8.encode('${name.toLowerCase()}|$unit')).replaceAll('=', '');

/// Works out what each new item does to what she already has. Items added in the same go count as
/// "already there" for each other, so two photos of one product in one go become one line.
List<AddResult> planAdds(List<InventoryItem> existing, List<NewItem> incoming) {
  final pool = [...existing];
  final results = <AddResult>[];
  for (final item in incoming) {
    final name = item.name.trim();
    var matchIndex = -1;
    double? converted;
    for (var i = 0; i < pool.length; i++) {
      if (!sameProduct(pool[i].name, name)) continue;
      final c = convertAmount(item.amount, item.unit, pool[i].unit);
      if (c == null) continue;
      matchIndex = i;
      converted = c;
      break;
    }
    if (matchIndex >= 0) {
      final line = pool[matchIndex];
      final total = line.amount + converted!;
      pool[matchIndex] = InventoryItem(id: line.id, name: line.name, amount: total, unit: line.unit);
      results.add(AddResult(
        docId: line.id,
        name: line.name,
        unit: line.unit,
        added: converted,
        merged: true,
        newTotal: total,
      ));
    } else {
      final id = itemDocId(name, item.unit);
      pool.add(InventoryItem(id: id, name: name, amount: item.amount, unit: item.unit));
      results.add(AddResult(
        docId: id,
        name: name,
        unit: item.unit,
        added: item.amount,
        merged: false,
        newTotal: item.amount,
      ));
    }
  }
  return results;
}
