import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/days_left.dart';

/// How much of one grocery item went into a dish. Implements prd.md > Log today's dish.
class UsedAmount {
  const UsedAmount({
    required this.id,
    required this.name,
    required this.unit,
    required this.amount,
    required this.left,
  });

  final String id; // the inventory document
  final String name;
  final String unit;
  final double amount; // what she says was used
  final double left; // what was left before cooking

  Map<String, dynamic> toMap() => {'name': name, 'unit': unit, 'amount': amount};
}

/// What the Log screen hands over when she taps save.
class LogMealRequest {
  const LogMealRequest({required this.dishName, required this.slot, required this.used});

  final String dishName;
  final String slot; // Lunch or Dinner
  final List<UsedAmount> used;
}

/// One line of the daily log, stored at users/{uid}/meals/{id} (spec.md > Data Model).
class MealEntry {
  const MealEntry({
    required this.id,
    required this.dishName,
    required this.slot,
    required this.date,
    required this.used,
    this.createdAt,
  });

  final String id;
  final String dishName;
  final String slot;
  final DateTime date;
  final List<({String name, String unit, double amount})> used;
  final DateTime? createdAt;

  factory MealEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final used = <({String name, String unit, double amount})>[];
    for (final raw in (data['used'] as List?) ?? const []) {
      if (raw is! Map) continue;
      used.add((
        name: (raw['name'] as String?) ?? '',
        unit: (raw['unit'] as String?) ?? '',
        amount: ((raw['amount'] as num?) ?? 0).toDouble(),
      ));
    }
    return MealEntry(
      id: doc.id,
      dishName: (data['dishName'] as String?) ?? '',
      slot: (data['slot'] as String?) ?? '',
      date: dateFromKey(data['date'] as String?) ?? DateTime.now(),
      used: used,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
