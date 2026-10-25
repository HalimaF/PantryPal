import 'dart:math';

import '../models/inventory_item.dart';

/// Days until the next shopping, and totals of what is left. Plain code, no AI.
/// Implements spec.md > Components > Days-until-shopping calculation.

/// Shopping on the 28th means the next one defaults to the 28th of next month.
/// A day that does not exist next month (the 31st) becomes that month's last day.
DateTime sameDayNextMonth(DateTime date) {
  final year = date.month == 12 ? date.year + 1 : date.year;
  final month = date.month == 12 ? 1 : date.month + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, min(date.day, lastDay));
}

/// Whole days from [today] to [next]: 0 on the day itself, negative once it has passed.
/// Uses UTC dates so a clock change never shifts the answer by a day.
int daysUntil(DateTime today, DateTime next) {
  final from = DateTime.utc(today.year, today.month, today.day);
  final to = DateTime.utc(next.year, next.month, next.day);
  return to.difference(from).inDays;
}

/// What is left, added up per unit (units cannot be mixed): {kg: 6.5, pieces: 12}.
Map<String, double> totalsByUnit(Iterable<InventoryItem> items) {
  final totals = <String, double>{};
  for (final item in items) {
    totals[item.unit] = (totals[item.unit] ?? 0) + item.amount;
  }
  return totals;
}

/// "6.5 kg, 12 pieces" in the order of [groceryUnits].
String describeTotals(Map<String, double> totals) {
  final parts = [
    for (final unit in groceryUnits)
      if (totals[unit] != null && totals[unit]! > 0) '${formatAmount(totals[unit]!)} $unit',
  ];
  return parts.join(', ');
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "28 Nov"
String formatShortDate(DateTime date) => '${date.day} ${_months[date.month - 1]}';

/// Dates are stored as "2026-11-28" text so time zones can never move them a day.
String dateToKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? dateFromKey(String? key) {
  if (key == null) return null;
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]), m = int.tryParse(parts[1]), d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// The sentence at the top of the dashboard.
String daysUntilMessage(DateTime today, DateTime? next) {
  if (next == null) return 'Set your next shopping date when you add groceries.';
  final days = daysUntil(today, next);
  final date = formatShortDate(next);
  if (days < 0) return 'Your shopping day ($date) has passed. Add your new groceries.';
  if (days == 0) return 'Shopping day is today ($date).';
  if (days == 1) return '1 day until your next shopping ($date).';
  return '$days days until your next shopping ($date).';
}
