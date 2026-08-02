import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/finance_models.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(
    String uid,
    bool isIncome,
  ) {
    final collectionName = isIncome
        ? 'income_categories'
        : 'expense_categories';
    return _firestore.collection('users').doc(uid).collection(collectionName);
  }

  Stream<List<ExpenseCategory>> watchCategories({
    required String uid,
    required bool isIncome,
  }) {
    return _collection(uid, isIncome).orderBy('sortOrder').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ExpenseCategory.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<ExpenseCategory>> loadCategories({
    required String uid,
    required bool isIncome,
    required List<ExpenseCategory> fallback,
  }) async {
    try {
      final snapshot = await _collection(
        uid,
        isIncome,
      ).orderBy('sortOrder').get(const GetOptions(source: Source.cache));
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => ExpenseCategory.fromMap(doc.id, doc.data()))
            .toList();
      }
    } catch (_) {}
    // First use: show built-in categories immediately and seed/sync them in
    // the background instead of holding the launch screen for the network.
    unawaited(ensureSeeded(uid: uid, isIncome: isIncome, fallback: fallback));
    return fallback;
  }

  Future<void> ensureSeeded({
    required String uid,
    required bool isIncome,
    required List<ExpenseCategory> fallback,
  }) async {
    final collection = _collection(uid, isIncome);
    final snapshot = await collection.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (var index = 0; index < fallback.length; index++) {
      final category = fallback[index].copyWith(sortOrder: index);
      batch.set(collection.doc(category.id), category.toMap());
    }
    await batch.commit();
  }

  Future<void> upsertCategory({
    required String uid,
    required bool isIncome,
    required ExpenseCategory category,
  }) async {
    await _collection(uid, isIncome).doc(category.id).set(category.toMap());
  }

  Future<void> deleteCategory({
    required String uid,
    required bool isIncome,
    required String categoryId,
  }) async {
    await _collection(uid, isIncome).doc(categoryId).delete();
  }

  Future<void> updateSubcategories({
    required String uid,
    required bool isIncome,
    required ExpenseCategory category,
  }) async {
    await _collection(uid, isIncome).doc(category.id).set(category.toMap());
  }
}
