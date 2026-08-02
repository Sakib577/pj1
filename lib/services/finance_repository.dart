import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/finance_models.dart';

/// Reads and writes the user's financial records (transactions, planned
/// payments, debts) in Firestore under users/{uid}/...
class FinanceRepository {
  FinanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String kind, String id) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(kind)
        .doc(id);
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid, String kind) {
    return _firestore.collection('users').doc(uid).collection(kind);
  }

  // --- Transactions ---

  Future<List<TransactionItem>> loadTransactions(String uid) async {
    final snapshot = await _collection(uid, 'transactions').get(
      const GetOptions(source: Source.serverAndCache),
    );
    return snapshot.docs
        .map((doc) => TransactionItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<TransactionItem>> watchTransactions(String uid) {
    return _collection(uid, 'transactions').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => TransactionItem.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  // Reports whether the user's transactions collection is fully synced, being
  // read from the local cache because the server is unavailable, or has local
  // writes still waiting to be pushed. includeMetadataChanges is required so
  // the stream fires when only the metadata (pending/from-cache flags) changes.
  Stream<SyncStatus> watchSyncStatus(String uid) {
    return _collection(uid, 'transactions')
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          if (snapshot.metadata.isFromCache) return SyncStatus.offline;
          if (snapshot.metadata.hasPendingWrites) return SyncStatus.pending;
          return SyncStatus.synced;
        });
  }

  Future<void> saveTransaction(String uid, TransactionItem transaction) async {
    final id = transaction.id ??
        transaction.createdAt?.microsecondsSinceEpoch.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    await _doc(uid, 'transactions', id).set(transaction.toMap());
  }

  Future<void> updateTransaction(
    String uid,
    String id,
    TransactionItem transaction,
  ) async {
    await _doc(uid, 'transactions', id).set(transaction.toMap());
  }

  Future<void> deleteTransaction(String uid, String id) async {
    await _doc(uid, 'transactions', id).delete();
  }

  // --- Planned payments ---

  Future<List<PlannedPayment>> loadPlannedPayments(String uid) async {
    final snapshot = await _collection(uid, 'planned_payments').get(
      const GetOptions(source: Source.serverAndCache),
    );
    return snapshot.docs
        .map((doc) => PlannedPayment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<PlannedPayment>> watchPlannedPayments(String uid) {
    return _collection(uid, 'planned_payments').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => PlannedPayment.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> savePlannedPayment(String uid, PlannedPayment payment) async {
    await _doc(uid, 'planned_payments', payment.id).set(payment.toMap());
  }

  Future<void> deletePlannedPayment(String uid, String id) async {
    await _doc(uid, 'planned_payments', id).delete();
  }

  // --- Debts ---

  Future<List<DebtItem>> loadDebts(String uid) async {
    final snapshot = await _collection(uid, 'debts').get(
      const GetOptions(source: Source.serverAndCache),
    );
    return snapshot.docs
        .map((doc) => DebtItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<DebtItem>> watchDebts(String uid) {
    return _collection(uid, 'debts').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => DebtItem.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> saveDebt(String uid, DebtItem debt) async {
    await _doc(uid, 'debts', debt.id).set(debt.toMap());
  }

  Future<void> deleteDebt(String uid, String id) async {
    await _doc(uid, 'debts', id).delete();
  }

  // --- Shopping items ---

  Future<List<ShoppingItem>> loadShoppingItems(String uid) async {
    final snapshot = await _collection(uid, 'shopping_items').get(
      const GetOptions(source: Source.serverAndCache),
    );
    return snapshot.docs
        .map((doc) => ShoppingItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<ShoppingItem>> watchShoppingItems(String uid) {
    return _collection(uid, 'shopping_items').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ShoppingItem.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> saveShoppingItem(String uid, ShoppingItem item) async {
    await _doc(uid, 'shopping_items', item.id).set(item.toMap());
  }

  Future<void> deleteShoppingItem(String uid, String id) async {
    await _doc(uid, 'shopping_items', id).delete();
  }

  // --- Currency settings ---

  Future<String?> loadCurrency(String uid) async {
    final doc = await _doc(uid, 'settings', 'currency').get();
    if (!doc.exists) return null;
    return (doc.data()?['code'] as String?)?.trim();
  }

  Future<void> saveCurrency(String uid, String code) async {
    await _doc(uid, 'settings', 'currency').set({'code': code});
  }
}
