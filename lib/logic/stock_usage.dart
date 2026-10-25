import '../models/meal.dart';

/// What is left of each item after cooking: id -> new amount. Never below zero, so
/// "used 2 kg" of 1 kg leaves 0 and not -1. Implements spec.md > Components > Log today's dish.
/// Items that were not used, or were left blank, are not in the result.
Map<String, double> remainingAfter(List<UsedAmount> used) {
  final remaining = <String, double>{};
  for (final u in used) {
    if (u.amount <= 0) continue;
    final before = remaining[u.id] ?? u.left;
    final after = before - u.amount;
    remaining[u.id] = after < 0 ? 0 : after;
  }
  return remaining;
}

/// A tiny amount left after rounding (0.0000001 kg) counts as finished.
bool isFinished(double amount) => amount < 0.001;
