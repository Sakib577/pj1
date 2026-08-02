import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_models.dart';
import '../services/category_repository.dart';
import '../services/exchange_rate_service.dart';
import '../services/finance_repository.dart';
import '../services/payment_reminder_service.dart';
import '../utils/currency_settings.dart';

class FinanceAppState extends ChangeNotifier {
  double _balance = 0;
  double _income = 0;
  double _expenses = 0;
  final List<TransactionItem> _transactions = [];
  final List<CategoryItem> _categories = [];
  final List<ExpenseCategory> _expenseCategories = _defaultExpenseCategories();
  final List<ExpenseCategory> _incomeCategories = _defaultIncomeCategories();
  final List<String> _recentCategoryIds = [];
  final List<String> _recentIncomeCategoryIds = [];
  final CategoryRepository _categoryRepository = CategoryRepository();
  final FinanceRepository _financeRepository = FinanceRepository();
  final List<PlannedPayment> _plannedPayments = [];
  final List<DebtItem> _debts = [];
  final List<ShoppingItem> _shoppingItems = [];
  final List<BudgetCategory> _budgets = [];
  final List<SavingsGoal> _goals = [];
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  Map<String, double> _usdRates = {'USD': 1};
  DateTime? _ratesUpdatedAt;
  bool _ratesLoading = false;
  String? _syncedUid;
  bool _categorySyncReady = false;
  StreamSubscription<List<ExpenseCategory>>? _expenseCategorySubscription;
  StreamSubscription<List<ExpenseCategory>>? _incomeCategorySubscription;
  StreamSubscription<List<TransactionItem>>? _transactionSubscription;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  StreamSubscription<List<PlannedPayment>>? _paymentSubscription;
  StreamSubscription<List<DebtItem>>? _debtSubscription;
  StreamSubscription<List<ShoppingItem>>? _shoppingSubscription;
  bool _notifyScheduled = false;
  bool _currencyNeedsSetup = false;
  SyncStatus _syncStatus = SyncStatus.synced;

  // Whether the user's records are currently offline, syncing, or synced. Lets
  // the UI show a banner so the user knows edits are stored locally for now.
  SyncStatus get syncStatus => _syncStatus;
  bool get isOffline => _syncStatus == SyncStatus.offline;
  bool get hasPendingSync => _syncStatus == SyncStatus.pending;

  // FinanceAppScope is an InheritedNotifier and every page depends on it, so a
  // notifyListeners() during the framework's build/layout phase (e.g. an async
  // Firestore write completing mid-route-transition, or right after a dialog /
  // bottom sheet closes during its pop animation) can trip Flutter's
  // InheritedElement '_dependents.isEmpty' assertion. Always defer the
  // notification to just after the frame so dependents are never rebuilt while
  // the element tree is mid-deactivation. Coalesce bursts that fall in the same
  // frame.
  @override
  void notifyListeners() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }

  BalanceSummary get balanceSummary => BalanceSummary(
    total: _balance,
    deltaPercent: 0,
    isPositive: _balance >= 0,
  );

  List<StatCardData> get stats => [
    StatCardData(
      label: 'Income',
      amount: _income,
      icon: Icons.arrow_downward,
      color: const Color(0xFF22C55E),
      isPositive: true,
    ),
    StatCardData(
      label: 'Expenses',
      amount: _expenses,
      icon: Icons.arrow_upward,
      color: const Color(0xFFF97316),
      isPositive: false,
    ),
  ];

  List<TransactionItem> get transactions => List.unmodifiable(_transactions);
  List<CategoryItem> get categories => List.unmodifiable(_categories);
  List<ExpenseCategory> get expenseCategories =>
      List.unmodifiable(_expenseCategories);
  List<ExpenseCategory> get incomeCategories =>
      List.unmodifiable(_incomeCategories);
  List<ExpenseCategory> get recentExpenseCategories =>
      _recentCategories(_expenseCategories, _recentCategoryIds);
  List<ExpenseCategory> get recentIncomeCategories =>
      _recentCategories(_incomeCategories, _recentIncomeCategoryIds);

  Future<void>? _initialLoad;

  List<ExpenseCategory> _recentCategories(
    List<ExpenseCategory> categories,
    List<String> recentIds,
  ) {
    final recent = <ExpenseCategory>[];
    for (final id in recentIds) {
      for (final category in categories) {
        if (category.id == id) recent.add(category);
      }
    }
    return recent.isEmpty
        ? categories.take(3).toList()
        : recent.take(3).toList();
  }

  List<PlannedPayment> get plannedPayments =>
      List.unmodifiable(_plannedPayments);

  void addPlannedPayment(PlannedPayment payment) {
    _plannedPayments.insert(0, payment);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.savePlannedPayment(uid, payment)));
    _syncReminders();
  }

  void removePlannedPayment(String id) {
    _plannedPayments.removeWhere((payment) => payment.id == id);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deletePlannedPayment(uid, id)));
    _syncReminders();
  }

  // Confirms a planned payment: records it as a real transaction and removes
  // it from the planned-payments list so the confirmed amount only appears in
  // transactions, not as an upcoming payment.
  void confirmPlannedPayment(String id) {
    final index = _plannedPayments.indexWhere((payment) => payment.id == id);
    if (index == -1) return;
    final payment = _plannedPayments[index];
    if (!payment.needsConfirmation) return;

    _recordTransaction(
      amountUsd: payment.amount,
      icon: payment.icon,
      iconColor: payment.iconColor,
      isIncome: payment.isIncome,
      category: _findCategoryForPayment(payment),
      subcategory: payment.subcategory,
      note: payment.title,
    );

    _plannedPayments.removeAt(index);
    notifyListeners();
    unawaited(_write(
      (uid) => _financeRepository.deletePlannedPayment(uid, payment.id),
    ));
    _syncReminders();
  }

  ExpenseCategory _findCategoryForPayment(PlannedPayment payment) {
    final categories = payment.isIncome ? _incomeCategories : _expenseCategories;
    for (final category in categories) {
      if (category.name == payment.categoryName) return category;
    }
    return ExpenseCategory(
      id: payment.isIncome ? 'planned-income' : 'planned-expense',
      name: payment.categoryName.isEmpty
          ? (payment.isIncome ? 'Income' : 'Expense')
          : payment.categoryName,
      icon: payment.icon,
      subcategories: const [],
    );
  }

  List<DebtItem> get debts => List.unmodifiable(_debts);

  void addDebt(DebtItem debt) {
    _debts.insert(0, debt);
    // Borrowing brings money in; lending puts money out.
    _adjustDebtBalance(debt.amount, debt.type, 1);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveDebt(uid, debt)));
  }

  void setDebtClosed(String id, bool isClosed) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index == -1) return;
    final debt = _debts[index];
    if (isClosed) {
      // Closing/forgiving settles the record without moving money.
      _debts[index] = debt.copyWith(settlement: DebtSettlement.closed);
    } else {
      _debts[index] = debt.copyWith(settlement: DebtSettlement.active);
      if (debt.settlement == DebtSettlement.repaid) {
        // Reopening a repaid debt undoes the repayment money movement.
        _adjustDebtBalance(debt.amount, debt.type, 1);
      }
    }
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveDebt(uid, _debts[index])));
  }

  void markDebtRepaid(String id) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index == -1) return;
    final debt = _debts[index];
    if (debt.settlement != DebtSettlement.active) return;
    // Repaying reverses the original money movement: borrowed pays back out,
    // lent money comes back in.
    _adjustDebtBalance(debt.amount, debt.type, -1);
    _debts[index] = debt.copyWith(settlement: DebtSettlement.repaid);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveDebt(uid, _debts[index])));
  }

  void deleteDebt(String id) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index == -1) return;
    final debt = _debts[index];
    _debts.removeAt(index);
    if (debt.settlement != DebtSettlement.repaid) {
      // Repaid debts have zero net balance effect, so nothing to undo.
      _adjustDebtBalance(debt.amount, debt.type, -1);
    }
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteDebt(uid, id)));
  }

  // Re-schedules Android reminders to match the current planned payments.
  void _syncReminders() {
    unawaited(
      PaymentReminderService.instance.scheduleReminders(_plannedPayments),
    );
  }

  // Runs a Firestore write for the signed-in user, ignoring failures so a
  // slow network never blocks the UI.
  Future<void> _write(
    Future<void> Function(String uid) operation,
  ) async {
    final uid = _syncedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await operation(uid);
    } catch (_) {}
  }

  // sign 1 = borrowed adds money / lent takes money out (creation).
  // sign -1 = borrowed pays back out / lent money comes back in (repayment).
  void _adjustDebtBalance(double amount, DebtType type, int sign) {
    _balance += sign * (type == DebtType.borrowed ? amount : -amount);
  }

  List<ShoppingItem> get shoppingItems => List.unmodifiable(_shoppingItems);

  List<String> get shoppingSubcategories {
    for (final category in _expenseCategories) {
      if (category.id == 'shopping') {
        return List.unmodifiable(category.subcategories);
      }
    }
    return const [];
  }

  void addShoppingItem(ShoppingItem item) {
    if (item.id.isEmpty) {
      item = ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: item.name,
        subcategory: item.subcategory,
        createdAt: DateTime.now(),
      );
    }
    _shoppingItems.insert(0, item);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveShoppingItem(uid, item)));
  }

  void deleteShoppingItem(String id) {
    _shoppingItems.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteShoppingItem(uid, id)));
  }

  // Marks an item done and records the price as a Shopping expense transaction.
  Future<void> completeShoppingItem({
    required String id,
    required double price,
    required String subcategory,
  }) async {
    final index = _shoppingItems.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final item = _shoppingItems[index];
    if (item.isDone) return;

    _shoppingItems[index] = item.copyWith(
      isDone: true,
      price: CurrencySettings.toUsd(price.abs()),
      completedAt: DateTime.now(),
    );
    final updated = _shoppingItems[index];
    unawaited(_write((uid) => _financeRepository.saveShoppingItem(uid, updated)));

    ExpenseCategory? shoppingCategory;
    for (final category in _expenseCategories) {
      if (category.id == 'shopping') {
        shoppingCategory = category;
        break;
      }
    }
    if (shoppingCategory != null) {
      addTransaction(
        amount: price.abs(),
        icon: shoppingCategory.icon ?? Icons.shopping_bag_rounded,
        iconColor: const Color(0xFFF97316),
        isIncome: false,
        category: shoppingCategory,
        subcategory: subcategory.isEmpty ? null : subcategory,
        note: item.name,
      );
    } else {
      notifyListeners();
    }
  }
  List<BudgetCategory> get budgets => List.unmodifiable(_budgets);
  SavingsOverview get savingsOverview => const SavingsOverview(
    totalSavings: 0,
    progress: 0,
    message: 'No savings goals yet.',
  );
  List<SavingsGoal> get savingsGoals => List.unmodifiable(_goals);

  double get currentBalance => _balance;
  double get monthlyIncome => _income;
  double get monthlyExpenses => _expenses;
  String get currencyCode => CurrencySettings.code;
  List<String> get availableCurrencyCodes => _usdRates.keys.toList()..sort();
  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;
  bool get ratesLoading => _ratesLoading;

  // True when the signed-in user has no currency stored yet, so the app can
  // prompt them once to pick their default display currency.
  bool get currencyNeedsSetup => _currencyNeedsSetup;

  Future<void> syncUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _stopSync();
      _clearFinanceData();
      _categorySyncReady = true;
      notifyListeners();
      return;
    }

    if (_syncedUid == user.uid && _categorySyncReady) {
      return;
    }

    _stopSync();
    _syncedUid = user.uid;

    _initialLoad = _loadUserDataForUser(user.uid);
    await _initialLoad;
  }

  void stopCategorySync() {
    _stopSync();
    notifyListeners();
  }

  void _stopSync() {
    _expenseCategorySubscription?.cancel();
    _incomeCategorySubscription?.cancel();
    _transactionSubscription?.cancel();
    _paymentSubscription?.cancel();
    _debtSubscription?.cancel();
    _shoppingSubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _expenseCategorySubscription = null;
    _incomeCategorySubscription = null;
    _transactionSubscription = null;
    _syncStatusSubscription = null;
    _paymentSubscription = null;
    _debtSubscription = null;
    _shoppingSubscription = null;
    _initialLoad = null;
    _categorySyncReady = false;
  }

  Future<void> _loadUserDataForUser(String uid) async {
    await _loadCategoriesForUser(uid);

    try {
      final transactions = await _financeRepository.loadTransactions(uid);
      _transactions
        ..clear()
        ..addAll(transactions)
        ..sort((a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)));
    } catch (_) {}

    try {
      final payments = await _financeRepository.loadPlannedPayments(uid);
      _plannedPayments
        ..clear()
        ..addAll(payments)
        ..sort((a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)));
    } catch (_) {}

    try {
      final debts = await _financeRepository.loadDebts(uid);
      _debts
        ..clear()
        ..addAll(debts)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}

    try {
      final shoppingItems = await _financeRepository.loadShoppingItems(uid);
      if (shoppingItems.isNotEmpty) {
        _shoppingItems
          ..clear()
          ..addAll(shoppingItems)
          ..sort(
            (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
          );
      }
    } catch (_) {}

    try {
      final storedCurrency = await _financeRepository.loadCurrency(uid);
      if (storedCurrency != null && storedCurrency.isNotEmpty) {
        CurrencySettings.update(code: storedCurrency, rates: _usdRates);
        _currencyNeedsSetup = false;
      } else {
        _currencyNeedsSetup = true;
      }
    } catch (_) {
      // Offline: keep the current currency and do not prompt.
    }

    _recomputeTotals();
    _syncReminders();
    notifyListeners();

    _transactionSubscription = _financeRepository
        .watchTransactions(uid)
        .listen((transactions) {
          _transactions
            ..clear()
            ..addAll(transactions)
            ..sort(
              (a, b) =>
                  _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
            );
          _recomputeTotals();
          notifyListeners();
        });
    _syncStatusSubscription = _financeRepository
        .watchSyncStatus(uid)
        .listen((status) {
          if (status == _syncStatus) return;
          _syncStatus = status;
          notifyListeners();
        });
    _paymentSubscription = _financeRepository
        .watchPlannedPayments(uid)
        .listen((payments) {
          _plannedPayments
            ..clear()
            ..addAll(payments)
            ..sort(
              (a, b) =>
                  _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
            );
          notifyListeners();
        });
    _debtSubscription = _financeRepository.watchDebts(uid).listen((debts) {
      _debts
        ..clear()
        ..addAll(debts)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _recomputeTotals();
      notifyListeners();
    });
    _shoppingSubscription = _financeRepository
        .watchShoppingItems(uid)
        .listen((shoppingItems) {
          _shoppingItems
            ..clear()
            ..addAll(shoppingItems)
            ..sort(
              (a, b) =>
                  _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
            );
          notifyListeners();
        });
  }

  // Balance is derived from transactions plus the net effect of active or
  // closed debts, so it can be rebuilt from persisted records after a restart.
  void _recomputeTotals() {
    var income = 0.0;
    var expenses = 0.0;
    for (final transaction in _transactions) {
      if (transaction.negative) {
        expenses += transaction.amount;
      } else {
        income += transaction.amount;
      }
    }
    var debtContribution = 0.0;
    for (final debt in _debts) {
      if (debt.settlement == DebtSettlement.repaid) continue;
      debtContribution +=
          debt.type == DebtType.borrowed ? debt.amount : -debt.amount;
    }
    _income = income;
    _expenses = expenses;
    _balance = income - expenses + debtContribution;
  }

  void _clearFinanceData() {
    _transactions.clear();
    _plannedPayments.clear();
    _debts.clear();
    _shoppingItems.clear();
    _currencyNeedsSetup = false;
    _syncStatus = SyncStatus.synced;
    _recomputeTotals();
  }

  DateTime _sortTime(DateTime? date) =>
      date ?? DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _loadCategoriesForUser(String uid) async {
    try {
      final loadedExpenseCategories = await _categoryRepository.loadCategories(
        uid: uid,
        isIncome: false,
        fallback: _defaultExpenseCategories(),
      );
      _replaceCategories(_expenseCategories, loadedExpenseCategories);
    } catch (_) {}

    try {
      final loadedIncomeCategories = await _categoryRepository.loadCategories(
        uid: uid,
        isIncome: true,
        fallback: _defaultIncomeCategories(),
      );
      _replaceCategories(_incomeCategories, loadedIncomeCategories);
    } catch (_) {}

    _expenseCategorySubscription = _categoryRepository
        .watchCategories(uid: uid, isIncome: false)
        .listen((categories) {
          _replaceCategories(_expenseCategories, categories);
          notifyListeners();
        });
    _incomeCategorySubscription = _categoryRepository
        .watchCategories(uid: uid, isIncome: true)
        .listen((categories) {
          _replaceCategories(_incomeCategories, categories);
          notifyListeners();
        });

    _categorySyncReady = true;
    notifyListeners();
  }

  void _replaceCategories(
    List<ExpenseCategory> target,
    List<ExpenseCategory> source,
  ) {
    target
      ..clear()
      ..addAll(source);
    if (identical(target, _expenseCategories)) {
      _normalizeMissingCategory(target);
    }
  }

  // Renames the legacy "Missing/Uncategorized" catch-all to "Missing" and keeps
  // that category first in the list.
  void _normalizeMissingCategory(List<ExpenseCategory> categories) {
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].name.trim() == 'Missing/Uncategorized') {
        categories[i] = categories[i].copyWith(name: 'Missing');
      }
    }
    final index = categories.indexWhere((category) =>
        category.name.trim() == 'Missing');
    if (index > 0) {
      categories.insert(0, categories.removeAt(index));
    }
  }

  Future<void> refreshExchangeRates() async {
    if (_ratesLoading) return;
    _ratesLoading = true;
    notifyListeners();
    try {
      final snapshot = await _exchangeRateService.fetchLatestUsdRates();
      _usdRates = snapshot.rates;
      _ratesUpdatedAt = snapshot.updatedAt;
      CurrencySettings.update(code: currencyCode, rates: _usdRates);
    } finally {
      _ratesLoading = false;
      notifyListeners();
    }
  }

  void changeCurrency(String code) {
    CurrencySettings.update(code: code, rates: _usdRates);
    _currencyNeedsSetup = false;
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveCurrency(uid, code)));
  }

  // Loads the exchange-rate list if it has not been fetched yet, so a first-run
  // currency picker has real options instead of just USD.
  Future<void> ensureCurrencyAvailable() async {
    if (_ratesLoading) return;
    if (_usdRates.length > 1) return;
    await refreshExchangeRates();
  }

  Future<void> addExpenseCategory({
    required String name,
    required String emoji,
    bool isIncome = false,
  }) async {
    final id =
        '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().microsecondsSinceEpoch}';
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final category = ExpenseCategory(
      id: id,
      name: name,
      emoji: emoji,
      subcategories: const [],
      isUserDefined: true,
      sortOrder: categories.length,
    );
    categories.add(category);
    notifyListeners();
    await _persistCategory(category: category, isIncome: isIncome);
  }

  Future<void> addSubcategory({
    required String categoryId,
    required String name,
    bool isIncome = false,
    String? emoji,
  }) async {
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    for (final category in categories) {
      if (category.id == categoryId) {
        if (!category.subcategories.contains(name)) {
          category.subcategories.add(name);
          category.userDefinedSubcategories.add(name);
          category.subcategoryEmojis[name] = (emoji == null ||
                  emoji.trim().isEmpty)
              ? defaultSubcategoryEmoji(name)
              : emoji.trim();
          notifyListeners();
          await _persistCategory(category: category, isIncome: isIncome);
        }
        return;
      }
    }
  }

  Future<void> deleteCategory({
    required ExpenseCategory category,
    required bool isIncome,
  }) async {
    if (!category.isUserDefined) return;
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    categories.remove(category);
    _moveTransactionsToMissing(category.name);
    notifyListeners();
    final uid = _syncedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await _categoryRepository.deleteCategory(
        uid: uid,
        isIncome: isIncome,
        categoryId: category.id,
      );
    }
  }

  Future<void> deleteSubcategory({
    required ExpenseCategory category,
    required String subcategory,
    required bool isIncome,
  }) async {
    if (!category.userDefinedSubcategories.remove(subcategory)) return;
    category.subcategories.remove(subcategory);
    _moveTransactionsToMissing('${category.name} · $subcategory');
    notifyListeners();
    await _persistCategory(category: category, isIncome: isIncome);
  }

  void _moveTransactionsToMissing(String removedCategoryName) {
    for (var index = 0; index < _transactions.length; index++) {
      if (_transactions[index].categoryName == removedCategoryName ||
          _transactions[index].categoryName.startsWith(
            '$removedCategoryName · ',
          )) {
        _transactions[index] = _transactions[index].copyWith(
          categoryName: 'Missing',
        );
      }
    }
  }

  void addTransaction({
    required double amount,
    required IconData icon,
    required Color iconColor,
    required bool isIncome,
    required ExpenseCategory category,
    String? subcategory,
    String? note,
  }) {
    // Financial totals stay in USD internally; the entered value is converted
    // from the user's selected display currency using the latest fetched rate.
    final value = CurrencySettings.toUsd(amount.abs());
    _recordTransaction(
      amountUsd: value,
      icon: icon,
      iconColor: iconColor,
      isIncome: isIncome,
      category: category,
      subcategory: subcategory,
      note: note,
    );
  }

  void _recordTransaction({
    required double amountUsd,
    required IconData icon,
    required Color iconColor,
    required bool isIncome,
    required ExpenseCategory category,
    String? subcategory,
    String? note,
  }) {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();

    _balance += isIncome ? amountUsd : -amountUsd;
    if (isIncome) {
      _income += amountUsd;
    } else {
      _expenses += amountUsd;
    }

    _transactions.insert(
      0,
      TransactionItem(
        id: id,
        title: subcategory == null
            ? category.name
            : '${category.name} · $subcategory',
        subtitle: _buildSubtitle(now, note),
        amount: amountUsd,
        icon: icon,
        iconColor: iconColor,
        categoryName: subcategory == null
            ? category.name
            : '${category.name} · $subcategory',
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        negative: !isIncome,
        createdAt: now,
      ),
    );

    final recentIds = isIncome ? _recentIncomeCategoryIds : _recentCategoryIds;
    recentIds.remove(category.id);
    recentIds.insert(0, category.id);

    notifyListeners();

    final transaction = _transactions.first;
    unawaited(_write(
      (uid) => _financeRepository.saveTransaction(uid, transaction),
    ));
  }

  void updateTransaction(TransactionItem updated) {
    final index = _transactions.indexWhere((txn) => txn.id == updated.id);
    if (index == -1) return;
    _transactions[index] = updated;
    _recomputeTotals();
    notifyListeners();
    if (updated.id != null) {
      unawaited(_write(
        (uid) => _financeRepository.updateTransaction(
          uid,
          updated.id!,
          updated,
        ),
      ));
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((txn) => txn.id == id);
    if (index == -1) return;
    _transactions.removeAt(index);
    _recomputeTotals();
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteTransaction(uid, id)));
  }

  Future<void> _persistCategory({
    required ExpenseCategory category,
    required bool isIncome,
  }) async {
    final uid = _syncedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await _categoryRepository.upsertCategory(
      uid: uid,
      isIncome: isIncome,
      category: category,
    );
  }

  String _buildSubtitle(DateTime date, String? note) {
    final month = _monthLabel(date.month);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final subtitle = '$month ${date.day}, $hour:$minute $period';
    final trimmedNote = note?.trim();
    if (trimmedNote == null || trimmedNote.isEmpty) {
      return subtitle;
    }
    return '$subtitle · $trimmedNote';
  }

  String _monthLabel(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      default:
        return 'Dec';
    }
  }

  static List<ExpenseCategory> _defaultExpenseCategories() => [
    ExpenseCategory(
      id: 'food-drinks',
      name: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      subcategories: [
        'Groceries',
        'Restaurant & Café',
        'Snacks',
        'Food delivery',
      ],
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      subcategories: [
        'Clothes & Shoes',
        'Medicine',
        'Electronics',
        'Accessories',
        'Gifts',
        'Health',
        'Home',
        'Beauty',
        'Jewellery',
        'Kids',
        'Pets',
        'Stationery & DIY',
      ],
    ),
    ExpenseCategory(
      id: 'housing',
      name: 'Housing',
      icon: Icons.home_rounded,
      subcategories: [
        'Rent or mortgage',
        'Utilities',
        'Furniture',
        'Repairs',
        'Home supplies',
      ],
    ),
    ExpenseCategory(
      id: 'transport',
      name: 'Transportation',
      icon: Icons.directions_bus_rounded,
      subcategories: ['Public transport', 'Ride share', 'Taxi', 'Bicycle'],
    ),
    ExpenseCategory(
      id: 'vehicle',
      name: 'Vehicle',
      icon: Icons.directions_car_rounded,
      subcategories: ['Fuel', 'Insurance', 'Parking', 'Rentals', 'Maintenance'],
    ),
    ExpenseCategory(
      id: 'lifestyle',
      name: 'Lifestyle & Wellbeing',
      icon: Icons.self_improvement_rounded,
      subcategories: [
        'Fitness',
        'Charity',
        'Culture & events',
        'Education',
        'Healthcare',
        'Hobbies',
        'Travel & holidays',
      ],
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      subcategories: [
        'Books & audiobooks',
        'Subscriptions',
        'Sports',
        'Games',
        'Movies & shows',
      ],
    ),
    ExpenseCategory(
      id: 'communication',
      name: 'Communication',
      icon: Icons.forum_rounded,
      subcategories: ['Internet bill', 'Phone bill', 'Postage'],
    ),
    ExpenseCategory(
      id: 'software-assets',
      name: 'Software & Digital Assets',
      icon: Icons.devices_rounded,
      subcategories: ['Software', 'Cloud services', 'Digital assets'],
    ),
    ExpenseCategory(
      id: 'investments',
      name: 'Investments',
      icon: Icons.trending_up_rounded,
      subcategories: [
        'Stocks & ETFs',
        'Mutual funds',
        'Bonds',
        'Retirement contributions',
      ],
    ),
    ExpenseCategory(
      id: 'legal-financial',
      name: 'Legal & Financial',
      icon: Icons.account_balance_rounded,
      subcategories: [
        'Bank charges',
        'Professional fees',
        'Child support',
        'Fines',
        'Insurance',
        'Loan interest',
        'Taxes',
      ],
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Missing',
      icon: Icons.category_rounded,
      subcategories: const [],
    ),
  ];

  static List<ExpenseCategory> _defaultIncomeCategories() => [
    ExpenseCategory(
      id: 'salary-wages',
      name: 'Salary & Wages',
      icon: Icons.payments_rounded,
      subcategories: [
        'Base salary',
        'Overtime',
        'Bonus',
        'Commission',
        'Allowance',
        'Advance payment',
      ],
    ),
    ExpenseCategory(
      id: 'dues',
      name: 'Dues Received',
      icon: Icons.assignment_turned_in_rounded,
      subcategories: [
        'Outstanding payment',
        'Reimbursement',
        'Refund on bills',
        'Pending invoice',
      ],
    ),
    ExpenseCategory(
      id: 'interest',
      name: 'Interest',
      icon: Icons.savings_rounded,
      subcategories: [
        'Savings interest',
        'Deposit interest',
        'Fixed deposit',
        'Bond interest',
      ],
    ),
    ExpenseCategory(
      id: 'dividends',
      name: 'Dividends',
      icon: Icons.trending_up_rounded,
      subcategories: [
        'Stock dividends',
        'Fund distributions',
        'Cash dividends',
      ],
    ),
    ExpenseCategory(
      id: 'lending',
      name: 'Loan Repayments',
      icon: Icons.handshake_rounded,
      subcategories: [
        'Personal loan repayment',
        'Business loan repayment',
        'Partial repayment',
      ],
    ),
    ExpenseCategory(
      id: 'renting',
      name: 'Rental Income',
      icon: Icons.home_work_rounded,
      subcategories: [
        'Property rent',
        'Equipment rent',
        'Shared room',
        'Parking space',
      ],
    ),
    ExpenseCategory(
      id: 'sales',
      name: 'Sales',
      icon: Icons.sell_rounded,
      subcategories: [
        'Personal items',
        'Business sales',
        'Online sales',
        'Marketplace sale',
      ],
    ),
    ExpenseCategory(
      id: 'gifts',
      name: 'Gifts',
      icon: Icons.card_giftcard_rounded,
      subcategories: [
        'Cash gift',
        'Gift card',
        'Family support',
        'Celebration gift',
      ],
    ),
    ExpenseCategory(
      id: 'refunds',
      name: 'Refunds',
      icon: Icons.replay_rounded,
      subcategories: ['Purchase refund', 'Tax refund', 'Shipping refund'],
    ),
    ExpenseCategory(
      id: 'freelance',
      name: 'Freelance & Side Work',
      icon: Icons.work_outline_rounded,
      subcategories: [
        'Freelance project',
        'Consulting',
        'Side job',
        'Contract work',
        'Content creation',
      ],
    ),
    ExpenseCategory(
      id: 'other-income',
      name: 'Other Income',
      icon: Icons.category_rounded,
      subcategories: ['Cashback', 'Prize', 'Gift voucher', 'Other'],
    ),
  ];
}

// FinanceAppScope is an InheritedNotifier that exposes the shared
// FinanceAppState. Every widget that calls FinanceAppScope.of(context) becomes
// a dependent and is rebuilt automatically when the notifier fires — including
// pushed routes, which the root-level ListenableBuilder approach could not
// reach (Navigator caches route widgets, so only the home route rebuilt).
// The '_dependents.isEmpty' assertion is avoided by FinanceAppState deferring
// every notifyListeners() to just after the current frame (see the override at
// the top of this file), so dependents are never marked dirty while the element
// tree is mid-deactivation (route/dialog pop).
class FinanceAppScope extends InheritedNotifier<FinanceAppState> {
  const FinanceAppScope({
    super.key,
    required FinanceAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static FinanceAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FinanceAppScope>();
    assert(scope != null, 'FinanceAppScope not found in widget tree.');
    return scope!.notifier!;
  }
}
