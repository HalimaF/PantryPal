import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/days_left.dart';
import '../logic/stock_usage.dart';
import '../models/family_profile.dart';
import '../models/inventory_item.dart';
import '../models/meal.dart';

/// When mum last shopped and when she shops next.
class ShoppingDates {
  const ShoppingDates({this.last, this.next});
  final DateTime? last;
  final DateTime? next;
}

/// Everything saved for one signed-in person. The rules in firestore.rules let a person
/// reach only their own `users/{uid}`. Implements spec.md > Data Model.
class DataService {
  // A private name cannot be a named parameter, so the field is set by hand.
  // ignore: prefer_initializing_formals
  DataService(this.uid, {FirebaseFirestore? firestore}) : _firestore = firestore;

  final String uid;
  final FirebaseFirestore? _firestore;

  // Looked up when first needed, so a test can replace this class without Firebase running.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _user => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _inventory => _user.collection('inventory');
  CollectionReference<Map<String, dynamic>> get _meals => _user.collection('meals');

  /// Her groceries, A to Z. Updates by itself whenever anything changes.
  Stream<List<InventoryItem>> inventory() => _inventory.snapshots().map(_toItems);

  /// Her groceries, read once right now. A second listener on a live feed that is already
  /// open gets nothing until the next change, so screens that only need the current list
  /// use this instead. Falls back to what the phone has saved if the internet is slow.
  Future<List<InventoryItem>> inventoryOnce() async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _inventory
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      snapshot = await _inventory.get(const GetOptions(source: Source.cache));
    }
    return _toItems(snapshot);
  }

  List<InventoryItem> _toItems(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs.map(InventoryItem.fromDoc).where((i) => i.amount > 0).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  /// The daily log, newest first.
  Stream<List<MealEntry>> meals() => _meals.snapshots().map(_toMeals);

  List<MealEntry> _toMeals(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final meals = snapshot.docs.map(MealEntry.fromDoc).toList();
    meals.sort((a, b) {
      final byDay = b.date.compareTo(a.date);
      if (byDay != 0) return byDay;
      return (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());
    });
    return meals;
  }

  /// Names of dishes cooked in the last [days] days, so they are not suggested again.
  Future<Set<String>> recentMealNames({int days = 7}) async {
    final now = DateTime.now();
    final since = dateToKey(DateTime(now.year, now.month, now.day - (days - 1)));
    final query = _meals.where('date', isGreaterThanOrEqualTo: since);
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await query
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      snapshot = await query.get(const GetOptions(source: Source.cache));
    }
    return {for (final m in _toMeals(snapshot)) m.dishName};
  }

  /// Saves the dish in the log and takes what was used out of the groceries, in one go:
  /// either both happen or neither does.
  Future<void> logMeal(LogMealRequest request) {
    final now = DateTime.now();
    final batch = _db.batch();
    batch.set(_meals.doc(), {
      'dishName': request.dishName.trim(),
      'slot': request.slot,
      'date': dateToKey(DateTime(now.year, now.month, now.day)),
      'used': [for (final u in request.used.where((u) => u.amount > 0)) u.toMap()],
      'createdAt': FieldValue.serverTimestamp(),
    });
    remainingAfter(request.used).forEach((id, amount) {
      final ref = _inventory.doc(id);
      if (isFinished(amount)) {
        batch.delete(ref);
      } else {
        batch.set(ref, {'amount': amount}, SetOptions(merge: true));
      }
    });
    return batch.commit();
  }

  /// Who she cooks for, read once. Falls back to what the phone has saved if the internet is slow.
  Future<FamilyProfile> profileOnce() async {
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _user
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      doc = await _user.get(const GetOptions(source: Source.cache));
    }
    return FamilyProfile.fromMap(doc.data()?['profile']);
  }

  Future<void> saveProfile(FamilyProfile profile) =>
      _user.set({'profile': profile.toMap()}, SetOptions(merge: true));

  Stream<ShoppingDates> shoppingDates() => _user.snapshots().map((doc) {
        final data = doc.data() ?? {};
        return ShoppingDates(
          last: dateFromKey(data['lastShoppingDate'] as String?),
          next: dateFromKey(data['nextShoppingDate'] as String?),
        );
      });

  /// Adding "chicken 1 kg" twice gives 2 kg: one document per name and unit.
  Future<void> addItem({required String name, required double amount, required String unit}) {
    final clean = name.trim();
    return _inventory.doc(_itemId(clean, unit)).set({
      'name': clean,
      'unit': unit,
      'amount': FieldValue.increment(amount),
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeItem(String id) => _inventory.doc(id).delete();

  Future<void> saveShoppingDates({required DateTime last, required DateTime next}) =>
      _user.set({
        'lastShoppingDate': dateToKey(last),
        'nextShoppingDate': dateToKey(next),
      }, SetOptions(merge: true));
}

/// A safe document name for any language ("Chicken", "مرغی"), the same each time.
String _itemId(String name, String unit) =>
    base64Url.encode(utf8.encode('${name.toLowerCase()}|$unit')).replaceAll('=', '');

/// Exposed so tests can check that the same item always lands in the same document.
String itemIdFor(String name, String unit) => _itemId(name.trim(), unit);
