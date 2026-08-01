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
        .map((doc) => TransactionItem.fromMap(doc.data()))
        .toList();
  }

  Future<void> saveTransaction(String uid, TransactionItem transaction) async {
    final id = transaction.createdAt?.microsecondsSinceEpoch.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    await _doc(uid, 'transactions', id).set(transaction.toMap());
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

  Future<void> saveDebt(String uid, DebtItem debt) async {
    await _doc(uid, 'debts', debt.id).set(debt.toMap());
  }

  Future<void> deleteDebt(String uid, String id) async {
    await _doc(uid, 'debts', id).delete();
  }
}
