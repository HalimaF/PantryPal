import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/days_left.dart';
import '../models/inventory_item.dart';

/// When mum last shopped and when she shops next.
class ShoppingDates {
  const ShoppingDates({this.last, this.next});
  final DateTime? last;
  final DateTime? next;
}

/// Everything saved for one signed-in person. The rules in firestore.rules let a person
/// reach only their own `users/{uid}`. Implements spec.md > Data Model.
class DataService {
  DataService(this.uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _user => _db.collection('users').doc(uid);
  CollectionReference<Map<String, dynamic>> get _inventory => _user.collection('inventory');

  /// Her groceries, A to Z. Updates by itself whenever anything changes.
  Stream<List<InventoryItem>> inventory() => _inventory.snapshots().map((snapshot) {
        final items = snapshot.docs.map(InventoryItem.fromDoc).where((i) => i.amount > 0).toList();
        items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      });

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
