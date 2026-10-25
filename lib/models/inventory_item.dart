import 'package:cloud_firestore/cloud_firestore.dart';

/// Units mum can pick when adding an item. Implements prd.md > Add groceries.
const groceryUnits = ['kg', 'g', 'L', 'ml', 'pieces', 'packs'];

/// What Gemini saw in a photo: the name (with the brand when visible) and, when the packaging
/// shows it, how much. Only [amount] and [unit] together are filled in.
class IdentifiedItem {
  const IdentifiedItem({required this.name, this.amount, this.unit});

  final String name;
  final double? amount;
  final String? unit; // one of [groceryUnits]
}

/// One item in the pantry, stored at users/{uid}/inventory/{id} (spec.md > Data Model).
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String id;
  final String name;
  final double amount; // what is left
  final String unit;

  factory InventoryItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return InventoryItem(
      id: doc.id,
      name: (data['name'] as String?) ?? '',
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      unit: (data['unit'] as String?) ?? 'pieces',
    );
  }
}

/// "1.5" or "1,5" to 1.5; null for blank, text, zero or negative.
double? parseAmount(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null || value <= 0 || value.isNaN || value.isInfinite) return null;
  return value;
}

/// 2.0 -> "2", 1.5 -> "1.5", 0.333 -> "0.33"
String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  final text = amount.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
