import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_models.dart';
import '../services/category_repository.dart';
import '../services/currency_preferences.dart';
import '../services/exchange_rate_service.dart';
import '../services/finance_repository.dart';
import '../services/app_lock_service.dart';
import '../services/payment_reminder_service.dart';
import '../utils/currency_settings.dart';
import '../utils/currency_formatters.dart';

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
  final List<AppNotification> _notifications = [];
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  Map<String, double> _usdRates = Map.of(CurrencySettings.usdRates);
  DateTime? _ratesUpdatedAt;
  bool _ratesLoading = false;
  bool _isLoadingData = true;
  String? _syncedUid;
  bool _categorySyncReady = false;
  StreamSubscription<List<ExpenseCategory>>? _expenseCategorySubscription;
  StreamSubscription<List<ExpenseCategory>>? _incomeCategorySubscription;
  StreamSubscription<List<TransactionItem>>? _transactionSubscription;
  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  StreamSubscription<List<PlannedPayment>>? _paymentSubscription;
  StreamSubscription<List<DebtItem>>? _debtSubscription;
  StreamSubscription<List<ShoppingItem>>? _shoppingSubscription;
  StreamSubscription<List<BudgetCategory>>? _budgetSubscription;
  StreamSubscription<List<SavingsGoal>>? _goalSubscription;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  bool _currencyNeedsSetup = false;
  SyncStatus _syncStatus = SyncStatus.synced;
  bool _paymentNotificationsEnabled = true;
  bool _budgetNotificationsEnabled = true;
  LockType _lockType = LockType.none;

  bool get paymentNotificationsEnabled => _paymentNotificationsEnabled;
  bool get budgetNotificationsEnabled => _budgetNotificationsEnabled;
  LockType get lockType => _lockType;

  // Kept for backwards compatibility with any remaining callers that only care
  // about the biometric variant of the app lock.
  bool get biometricLockEnabled => _lockType == LockType.biometric;

  // Whether the user's records are currently offline, syncing, or synced. Lets
  // the UI show a banner so the user knows edits are stored locally for now.
  SyncStatus get syncStatus => _syncStatus;
  bool get isOffline => _syncStatus == SyncStatus.offline;
  bool get hasPendingSync => _syncStatus == SyncStatus.pending;
  bool get isLoadingData => _isLoadingData;

  @override
  void dispose() {
    _stopSync();
    super.dispose();
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
    unawaited(
      _write((uid) => _financeRepository.savePlannedPayment(uid, payment)),
    );
    _syncReminders();
  }

  void removePlannedPayment(String id) {
    _plannedPayments.removeWhere((payment) => payment.id == id);
    notifyListeners();
    unawaited(
      _write((uid) => _financeRepository.deletePlannedPayment(uid, id)),
    );
    _syncReminders();
  }

  void updatePlannedPayment(PlannedPayment payment) {
    final index = _plannedPayments.indexWhere((item) => item.id == payment.id);
    if (index == -1) return;
    _plannedPayments[index] = payment;
    notifyListeners();
    unawaited(
      _write((uid) => _financeRepository.savePlannedPayment(uid, payment)),
    );
    _syncReminders();
  }

  // Confirms a planned payment: records it as a real transaction. One-time
  // payments are then removed from the list. Repeating payments stay and are
  // advanced to their next occurrence (via lastConfirmedDate) so they come due
  // again on schedule instead of disappearing.
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

    if (payment.repeat == RepeatFrequency.once) {
      _plannedPayments.removeAt(index);
      notifyListeners();
      unawaited(
        _write(
          (uid) => _financeRepository.deletePlannedPayment(uid, payment.id),
        ),
      );
      _syncReminders();
      return;
    }

    updatePlannedPayment(
      payment.copyWith(lastConfirmedDate: payment.currentDue()),
    );
  }

  ExpenseCategory _findCategoryForPayment(PlannedPayment payment) {
    final categories = payment.isIncome
        ? _incomeCategories
        : _expenseCategories;
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
    final transactionId = _recordDebtTransaction(debt, repayment: false);
    debt = DebtItem(
      id: debt.id,
      person: debt.person,
      amount: debt.amount,
      type: debt.type,
      settlement: debt.settlement,
      note: debt.note,
      createdAt: debt.createdAt,
      creationTransactionId: transactionId,
      // Pin the original direction so overpay flips can be reverted.
      createdType: debt.createdType ?? debt.type,
    );
    _debts.insert(0, debt);
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
      // Reopening a repaid/closed record restores the full outstanding amount
      // and removes all recorded repayments (and their transactions).
      for (final entry in debt.repaymentLog) {
        _deleteLinkedTransaction(entry.transactionId);
      }
      _debts[index] = debt.copyWith(
        settlement: DebtSettlement.active,
        repaymentLog: const [],
        clearRepaymentTransactionId: true,
        clearRemainingAmount: true,
      );
    }
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveDebt(uid, _debts[index])));
  }

  // Applies a repayment of `amountUsd` to an active debt. A repayment that does
  // not cover the full balance reduces the amount still owed. A repayment that
  // exceeds the balance flips the debt's direction (borrowed <-> lent) and the
  // surplus becomes the new outstanding balance owed the other way. Every
  // repayment is recorded so deleting its transaction reverts the debt.
  void repayDebt(String id, double amountUsd) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index == -1) return;
    final debt = _debts[index];
    if (debt.settlement != DebtSettlement.active) return;
    final payment = amountUsd.abs();
    if (payment <= 0) return;

    final remaining = debt.remaining;
    final surplus = payment - remaining;
    final txnId = _recordDebtTransaction(
      debt,
      repayment: true,
      amount: payment,
    );
    final paidOff = surplus == 0;
    final next = debt.copyWith(
      type: surplus > 0
          ? (debt.type == DebtType.borrowed
              ? DebtType.lent
              : DebtType.borrowed)
          : debt.type,
      settlement: paidOff ? DebtSettlement.repaid : DebtSettlement.active,
      remainingAmount: paidOff ? 0 : surplus.abs(),
      repaymentLog: [
        ...debt.repaymentLog,
        DebtRepayment(transactionId: txnId, amount: payment),
      ],
    );
    _debts[index] = next;
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveDebt(uid, next)));
  }

  // Derives a debt's original direction and principal from its creation
  // transaction. This is the authoritative source, so reversion also works for
  // legacy records saved before direction history was tracked.
  (DebtType, double) _originOf(DebtItem debt) {
    final index = _transactions.indexWhere(
      (txn) => txn.id == debt.creationTransactionId,
    );
    if (index != -1) {
      final txn = _transactions[index];
      final type = txn.negative ? DebtType.lent : DebtType.borrowed;
      return (type, txn.amount);
    }
    return (debt.originType, debt.amount);
  }

  // Replays a debt's repayment history from its original creation to derive
  // its current direction and outstanding balance.
  (double, DebtType) _replayDebt(DebtItem debt) {
    final (originType, originAmount) = _originOf(debt);
    var type = originType;
    var remaining = originAmount;
    for (final entry in debt.repaymentLog) {
      if (entry.amount < remaining) {
        remaining -= entry.amount;
      } else if (entry.amount == remaining) {
        remaining = 0;
      } else {
        remaining = entry.amount - remaining;
        type = type == DebtType.borrowed ? DebtType.lent : DebtType.borrowed;
      }
    }
    return (remaining, type);
  }

  void deleteDebt(String id) {
    final index = _debts.indexWhere((debt) => debt.id == id);
    if (index == -1) return;
    _removeFullDebt(index);
  }

  // Removes a debt along with its creation transaction and every repayment
  // transaction from the transaction history.
  void _removeFullDebt(int index) {
    final debt = _debts[index];
    _debts.removeAt(index);
    _deleteLinkedTransaction(debt.creationTransactionId);
    for (final entry in debt.repaymentLog) {
      _deleteLinkedTransaction(entry.transactionId);
    }
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteDebt(uid, debt.id)));
  }

  // Re-schedules Android reminders to match the current planned payments.
  void _syncReminders() {
    unawaited(
      PaymentReminderService.instance.scheduleReminders(
        _paymentNotificationsEnabled ? _plannedPayments : const [],
      ),
    );
  }

  // Runs a Firestore write for the signed-in user, ignoring failures so a
  // slow network never blocks the UI.
  Future<void> _write(Future<void> Function(String uid) operation) async {
    final uid = _syncedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await operation(uid);
    } catch (_) {}
  }

  String _recordDebtTransaction(
    DebtItem debt, {
    required bool repayment,
    double? amount,
  }) {
    final now = DateTime.now();
    final paymentAmount = amount ?? debt.amount;
    final id =
        'debt-${debt.id}-${repayment ? 'repaid' : 'created'}-${now.microsecondsSinceEpoch}';
    final isIncome = repayment
        ? debt.type == DebtType.lent
        : debt.type == DebtType.borrowed;
    final item = TransactionItem(
      id: id,
      title: repayment
          ? 'Debt repaid by ${debt.person}'
          : debt.type == DebtType.borrowed
          ? 'Borrowed from ${debt.person}'
          : 'Lent to ${debt.person}',
      subtitle: _buildSubtitle(now, debt.note),
      amount: paymentAmount,
      icon: repayment
          ? Icons.currency_exchange_rounded
          : Icons.handshake_rounded,
      iconColor: repayment ? const Color(0xFF22C55E) : const Color(0xFFF97316),
      categoryName: 'Debt',
      note: debt.note,
      negative: !isIncome,
      createdAt: now,
    );
    _transactions.insert(0, item);
    _recomputeTotals();
    unawaited(_write((uid) => _financeRepository.saveTransaction(uid, item)));
    return id;
  }

  void _deleteLinkedTransaction(String? id) {
    if (id == null || id.isEmpty) return;
    _transactions.removeWhere((transaction) => transaction.id == id);
    _recomputeTotals();
    unawaited(_write((uid) => _financeRepository.deleteTransaction(uid, id)));
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
    unawaited(
      _write((uid) => _financeRepository.saveShoppingItem(uid, updated)),
    );

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

  List<BudgetCategory> get budgets => List.unmodifiable(
    _budgets.map((budget) {
      final spent = _transactions
          .where(
            (transaction) =>
                transaction.negative &&
                _isInBudgetPeriod(transaction.createdAt, budget) &&
                _matchesBudgetCategory(transaction.categoryName, budget),
          )
          .fold<double>(0, (total, transaction) => total + transaction.amount);
      return budget.copyWith(spent: spent);
    }),
  );
  SavingsOverview get savingsOverview {
    final target = _goals.fold<double>(0, (total, goal) => total + goal.target);
    final current = _goals.fold<double>(
      0,
      (total, goal) => total + goal.current,
    );
    return SavingsOverview(
      totalSavings: current,
      progress: target == 0 ? 0 : (current / target).clamp(0, 1),
      message: _goals.isEmpty
          ? 'No savings goals yet.'
          : 'Keep building toward your goals.',
    );
  }

  List<SavingsGoal> get savingsGoals => List.unmodifiable(_goals);
  List<AppNotification> get notifications {
    final result = _notifications
        .where((item) => item.title != 'Planned payment added')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final payment in _plannedPayments) {
      final due = payment.nextDue();
      final dueDay = DateTime(due.year, due.month, due.day);
      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      // A reminder only exists from the moment the payment was created, so a
      // payment added today should not claim reminders from previous days.
      final created = payment.createdAt ?? payment.startDate;
      final createdDay = DateTime(created.year, created.month, created.day);
      for (final daysBefore in [2, 1, 0]) {
        final reminderDay = dueDay.subtract(Duration(days: daysBefore));
        // Do not show a future due-day reminder as "due today". A one-day
        // reminder for tomorrow is valid and should be visible today.
        if (reminderDay.isAfter(todayDay)) continue;
        // The payment did not exist before it was created, so a reminder
        // scheduled earlier than its creation date never happened.
        if (reminderDay.isBefore(createdDay)) continue;
        final title = daysBefore == 0
            ? 'Payment due today'
            : 'Payment coming up in $daysBefore '
                  '${daysBefore == 1 ? 'day' : 'days'}';
        final amount = formatCurrency(payment.amount);
        final sign = payment.isIncome ? '+' : '-';
        result.add(
          AppNotification(
            id: '${payment.id}:$daysBefore:${reminderDay.millisecondsSinceEpoch}',
            title: title,
            body: daysBefore == 0
                ? '${payment.title} · $sign$amount'
                : '${payment.title} is due in $daysBefore '
                      '${daysBefore == 1 ? 'day' : 'days'} · $sign$amount',
            createdAt: reminderDay,
          ),
        );
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  bool _isInBudgetPeriod(DateTime? date, BudgetCategory budget) {
    if (date == null) return false;
    final now = DateTime.now();
    if (budget.period == 'monthly') {
      return date.year == now.year && date.month == now.month;
    }
    final days = budget.period == 'thirtyDays' ? 30 : budget.customDays;
    // Guard against legacy/corrupted records: a non-positive interval would
    // never advance the loop below and freeze the whole app (white screen).
    if (days < 1) return false;
    var start = budget.startDate;
    var guard = 0;
    while (start.add(Duration(days: days)).isBefore(now) && guard < 2000) {
      start = start.add(Duration(days: days));
      guard++;
    }
    return !date.isBefore(start) &&
        date.isBefore(start.add(Duration(days: days)));
  }

  // Whether a transaction's category counts toward a budget. A budget with an
  // explicit category only counts expenses from that category (a transaction
  // stores either the bare category name or "Category · Subcategory").
  // A budget without a category counts every expense, except for legacy
  // repeating budgets created before category tracking existed, whose label
  // was used as the category name.
  bool _matchesBudgetCategory(String transactionCategory, BudgetCategory budget) {
    final category = budget.category;
    if (category != null) {
      return transactionCategory == category ||
          transactionCategory.startsWith('$category · ');
    }
    if (budget.period == 'monthly') return true;
    return transactionCategory == budget.label;
  }

  void addBudget(
    String label,
    double limit, {
    String period = 'monthly',
    int customDays = 30,
    String? category,
  }) {
    if (label.trim().isEmpty || limit <= 0) return;
    if (customDays < 1) customDays = 1;
    final item = BudgetCategory(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: label,
      limit: CurrencySettings.toUsd(limit),
      spent: 0,
      daysLeft: 0,
      status: 'Healthy',
      statusColor: const Color(0xFF16A34A),
      icon: Icons.account_balance_wallet_outlined,
      iconBg: const Color(0xFFFFF4E8),
      period: period,
      customDays: customDays,
      startDate: DateTime.now(),
      category: category,
    );
    _budgets.add(item);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveBudget(uid, item)));
  }

  void deleteBudget(String id) {
    _budgets.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteBudget(uid, id)));
  }

  void updateBudget(BudgetCategory item) {
    final index = _budgets.indexWhere((budget) => budget.id == item.id);
    if (index == -1) return;
    if (item.label.trim().isEmpty || item.limit <= 0) return;
    _budgets[index] = item;
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveBudget(uid, item)));
  }

  void addSavingsGoal(String title, double target) {
    final item = SavingsGoal.fromMap(
      DateTime.now().microsecondsSinceEpoch.toString(),
      {'title': title, 'target': CurrencySettings.toUsd(target), 'current': 0},
    );
    _goals.add(item);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveSavingsGoal(uid, item)));
  }

  void deleteSavingsGoal(String id) {
    _goals.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.deleteSavingsGoal(uid, id)));
  }

  void updateSavingsGoal(SavingsGoal item) {
    final index = _goals.indexWhere((goal) => goal.id == item.id);
    if (index == -1) return;
    _goals[index] = item;
    notifyListeners();
    unawaited(_write((uid) => _financeRepository.saveSavingsGoal(uid, item)));
  }

  void addSavingsContribution(String id, double amount) {
    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index == -1 || amount <= 0) return;
    final amountUsd = CurrencySettings.toUsd(amount);
    _goals[index] = _goals[index].copyWith(
      current: _goals[index].current + amountUsd,
    );
    notifyListeners();
    unawaited(
      _write((uid) => _financeRepository.saveSavingsGoal(uid, _goals[index])),
    );
    _recordTransaction(
      amountUsd: amountUsd,
      icon: Icons.savings_outlined,
      iconColor: const Color(0xFFF59E0B),
      isIncome: false,
      category: ExpenseCategory(
        id: 'savings',
        name: 'Savings',
        icon: Icons.savings_outlined,
        subcategories: const [],
      ),
      note: 'Added to ${_goals[index].title}',
    );
  }

  void withdrawSavingsContribution(String id, double amount) {
    final index = _goals.indexWhere((goal) => goal.id == id);
    final amountUsd = CurrencySettings.toUsd(amount);
    if (index == -1 || amountUsd <= 0 || amountUsd > _goals[index].current) {
      return;
    }
    _goals[index] = _goals[index].copyWith(
      current: _goals[index].current - amountUsd,
    );
    notifyListeners();
    unawaited(
      _write((uid) => _financeRepository.saveSavingsGoal(uid, _goals[index])),
    );
    _recordTransaction(
      amountUsd: amountUsd,
      icon: Icons.savings_outlined,
      iconColor: const Color(0xFF16A34A),
      isIncome: true,
      category: ExpenseCategory(
        id: 'savings',
        name: 'Savings',
        icon: Icons.savings_outlined,
        subcategories: const [],
      ),
      note: 'Withdrawn from ${_goals[index].title}',
    );
  }

  double get currentBalance => _balance;
  double get monthlyIncome => _income;
  double get monthlyExpenses => _expenses;
  String get currencyCode => CurrencySettings.code;
  List<String> get availableCurrencyCodes =>
      {...CurrencySettings.supportedCodes, ..._usdRates.keys}.toList()..sort();
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
    _isLoadingData = true;
    notifyListeners();

    // Apply this user's last local choice while Firestore loads. This is also
    // the fallback when the device is offline after sign-in.
    await CurrencyPreferences.loadForUser(user.uid);
    _usdRates = Map.of(CurrencySettings.usdRates);

    try {
      final load = _loadUserDataForUser(user.uid);
      // Watchdog: regardless of how the load completes, force the dashboard to
      // render after a hard cap so the user is never left on a blank screen.
      Future<void>.delayed(const Duration(seconds: 12)).then((_) {
        if (_isLoadingData) {
          _isLoadingData = false;
          notifyListeners();
          debugPrint('syncUserData: watchdog forced isLoadingData=false');
        }
      });
      await load.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // The initial load did not finish in time (slow or unavailable network).
      // Keep whatever already loaded so the dashboard renders instead of
      // showing a never-ending white loader. The pending future keeps running
      // and updates the UI when it eventually completes.
      debugPrint('syncUserData: initial load timed out after 10s');
    } finally {
      _isLoadingData = false;
      notifyListeners();
      debugPrint('syncUserData: finished, isLoadingData=false');
    }
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
    _budgetSubscription?.cancel();
    _goalSubscription?.cancel();
    _notificationSubscription?.cancel();
    _syncStatusSubscription?.cancel();
    _expenseCategorySubscription = null;
    _incomeCategorySubscription = null;
    _transactionSubscription = null;
    _syncStatusSubscription = null;
    _paymentSubscription = null;
    _debtSubscription = null;
    _shoppingSubscription = null;
    _budgetSubscription = null;
    _goalSubscription = null;
    _notificationSubscription = null;
    _categorySyncReady = false;
  }

  Future<void> _loadUserDataForUser(String uid) async {
    // Start independent cache/server reads together. Firestore can satisfy
    // these from its local cache immediately while any network refresh runs.
    final transactionsFuture = _financeRepository.loadRecentTransactions(uid);
    final paymentsFuture = _financeRepository.loadPlannedPayments(uid);
    final debtsFuture = _financeRepository.loadDebts(uid);
    final shoppingFuture = _financeRepository.loadShoppingItems(uid);
    final budgetsFuture = _financeRepository.loadBudgets(uid);
    final goalsFuture = _financeRepository.loadSavingsGoals(uid);
    final notificationsFuture = _financeRepository.loadNotifications(uid);
    final currencyFuture = _financeRepository.loadCurrency(uid);
    final preferencesFuture = _financeRepository.loadPreferences(uid);
    await _loadCategoriesForUser(uid);

    try {
      final transactions = await transactionsFuture;
      _transactions
        ..clear()
        ..addAll(transactions)
        ..sort(
          (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
        );
    } catch (_) {}

    try {
      final payments = await paymentsFuture;
      _plannedPayments
        ..clear()
        ..addAll(payments)
        ..sort(
          (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
        );
    } catch (_) {}

    try {
      final debts = await debtsFuture;
      _debts
        ..clear()
        ..addAll(debts)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}

    try {
      final shoppingItems = await shoppingFuture;
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
      _budgets
        ..clear()
        ..addAll(await budgetsFuture);
    } catch (_) {}
    try {
      _goals
        ..clear()
        ..addAll(await goalsFuture);
    } catch (_) {}
    try {
      _notifications
        ..clear()
        ..addAll(await notificationsFuture);
    } catch (_) {}

    try {
      // Server-first on purpose (restores the stored currency after a
      // reinstall), but bound it: on a slow/unreachable network this read can
      // hang for a very long time and would otherwise keep the dashboard on
      // its white loading screen. The catch below falls back to the cached
      // choice when the timeout fires.
      final storedCurrency = await currencyFuture.timeout(
        const Duration(seconds: 6),
      );
      debugPrint('loadCurrency: ok, code=$storedCurrency');
      if (storedCurrency != null && storedCurrency.isNotEmpty) {
        CurrencySettings.update(code: storedCurrency, rates: _usdRates);
        _currencyNeedsSetup = false;
        unawaited(CurrencyPreferences.save(uid: uid));
        if (storedCurrency != 'USD' && !_usdRates.containsKey(storedCurrency)) {
          unawaited(refreshExchangeRates());
        }
      } else {
        _currencyNeedsSetup = true;
      }
    } catch (_) {
      // Offline: keep the current currency and do not prompt.
      debugPrint('loadCurrency: timed out / failed (offline or unreachable)');
    }

    try {
      final preferences = await preferencesFuture.timeout(
        const Duration(seconds: 6),
      );
      _paymentNotificationsEnabled =
          preferences['paymentNotificationsEnabled'] as bool? ?? true;
      _budgetNotificationsEnabled =
          preferences['budgetNotificationsEnabled'] as bool? ?? true;
      final storedLockType = preferences['lockType'] as String?;
      if (storedLockType != null) {
        _lockType = LockType.values.firstWhere(
          (type) => type.name == storedLockType,
          orElse: () => LockType.none,
        );
      } else {
        // Migrate the legacy boolean preference.
        _lockType = (preferences['biometricLockEnabled'] as bool? ?? false)
            ? LockType.biometric
            : LockType.none;
      }
      // The PIN hash lives only on this device, keyed by user. If the stored
      // preference says PIN but no hash exists locally (e.g. after a fresh
      // install, or on an account that never set one on this phone), there is
      // nothing to verify against — drop the lock so the app opens and the
      // user can set a new PIN from Settings.
      if (_lockType == LockType.pin &&
          !await AppLockService.instance.hasPin(uid)) {
        _lockType = LockType.none;
      }
    } catch (_) {}

    _recomputeTotals();
    _syncReminders();
    notifyListeners();

    _transactionSubscription = _financeRepository
        .watchRecentTransactions(uid)
        .listen(
      (transactions) {
        _mergeRecentTransactions(transactions);
        _recomputeTotals();
        notifyListeners();
      },
    );
    _syncStatusSubscription = _financeRepository.watchRecentSyncStatus(uid).listen((
      status,
    ) {
      if (status == _syncStatus) return;
      _syncStatus = status;
      notifyListeners();
    });
    unawaited(_hydrateAllTransactions(uid));
    _paymentSubscription = _financeRepository.watchPlannedPayments(uid).listen((
      payments,
    ) {
      _plannedPayments
        ..clear()
        ..addAll(payments)
        ..sort(
          (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
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
    _shoppingSubscription = _financeRepository.watchShoppingItems(uid).listen((
      shoppingItems,
    ) {
      _shoppingItems
        ..clear()
        ..addAll(shoppingItems)
        ..sort(
          (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
        );
      notifyListeners();
    });
    _budgetSubscription = _financeRepository.watchBudgets(uid).listen((items) {
      _budgets
        ..clear()
        ..addAll(items);
      notifyListeners();
    });
    _goalSubscription = _financeRepository.watchSavingsGoals(uid).listen((
      items,
    ) {
      _goals
        ..clear()
        ..addAll(items);
      notifyListeners();
    });
    _notificationSubscription = _financeRepository
        .watchNotifications(uid)
        .listen((items) {
          _notifications
            ..clear()
            ..addAll(items);
          notifyListeners();
        });
  }

  void _mergeRecentTransactions(List<TransactionItem> recent) {
    final recentIds = _transactions
        .take(100)
        .map((item) => item.id)
        .whereType<String>()
        .toSet();
    _transactions.removeWhere(
      (item) => item.id != null && recentIds.contains(item.id),
    );
    _transactions.addAll(recent);
    _transactions.sort(
      (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
    );
  }

  Future<void> _hydrateAllTransactions(String uid) async {
    try {
      final all = await _financeRepository.loadAllTransactionsFromServer(uid);
      if (_syncedUid != uid) return;
      _transactions
        ..clear()
        ..addAll(all)
        ..sort(
          (a, b) => _sortTime(b.createdAt).compareTo(_sortTime(a.createdAt)),
        );
      _recomputeTotals();
      notifyListeners();
    } catch (_) {
      // The recent cache remains available when the server is unreachable.
    }
  }

  // Balance is derived from transactions. Debt activity creates matching
  // transactions, while a small legacy fallback preserves balances for debts
  // created by versions before debt transactions were introduced.
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
      if (debt.creationTransactionId != null) continue;
      if (debt.settlement == DebtSettlement.repaid) continue;
      debtContribution += debt.type == DebtType.borrowed
          ? debt.amount
          : -debt.amount;
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
    _budgets.clear();
    _goals.clear();
    _notifications.clear();
    _currencyNeedsSetup = false;
    _isLoadingData = false;
    _paymentNotificationsEnabled = true;
    _budgetNotificationsEnabled = true;
    _lockType = LockType.none;
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
      ..addAll(
        identical(target, _incomeCategories)
            ? source.map(
                (category) => category.id == 'other-income'
                    ? category.copyWith(icon: Icons.card_giftcard_rounded)
                    : category,
              )
            : source.map(
                (category) => category.copyWith(
                  subcategories: category.subcategories
                      .where((item) => item.toLowerCase() != 'bicycle')
                      .toList(),
                ),
              ),
      );
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
    final index = categories.indexWhere(
      (category) => category.name.trim() == 'Missing',
    );
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
      unawaited(CurrencyPreferences.save(uid: _syncedUid));
    } finally {
      _ratesLoading = false;
      notifyListeners();
    }
  }

  void changeCurrency(String code) {
    CurrencySettings.update(code: code, rates: _usdRates);
    _currencyNeedsSetup = false;
    notifyListeners();
    unawaited(CurrencyPreferences.save(uid: _syncedUid));
    unawaited(_write((uid) => _financeRepository.saveCurrency(uid, code)));
  }

  void setPaymentNotificationsEnabled(bool value) {
    _paymentNotificationsEnabled = value;
    notifyListeners();
    _syncReminders();
    unawaited(
      _write(
        (uid) => _financeRepository.savePreferences(uid, {
          'paymentNotificationsEnabled': value,
        }),
      ),
    );
  }

  void setBudgetNotificationsEnabled(bool value) {
    _budgetNotificationsEnabled = value;
    notifyListeners();
    unawaited(
      _write(
        (uid) => _financeRepository.savePreferences(uid, {
          'budgetNotificationsEnabled': value,
        }),
      ),
    );
  }

  /// Switches the app-lock verification method. For [LockType.pin] a [pin]
  /// must be provided (it is stored locally, hashed, under the user's key).
  /// Returns false when the requested method could not be enabled.
  Future<bool> setLockType(LockType type, {String? pin}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    switch (type) {
      case LockType.biometric:
        final service = AppLockService.instance;
        if (!await service.isBiometricAvailable() ||
            !await service.authenticateBiometric()) {
          return false;
        }
      case LockType.pin:
        if (pin == null || pin.length < 4) return false;
        await AppLockService.instance.setPin(uid, pin);
      case LockType.none:
        break;
    }
    if (type != LockType.pin) {
      await AppLockService.instance.clearPin(uid);
    }
    _lockType = type;
    notifyListeners();
    unawaited(
      _write(
        (uid) => _financeRepository.savePreferences(uid, {
          'lockType': type.name,
        }),
      ),
    );
    return true;
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
          category.subcategoryEmojis[name] =
              (emoji == null || emoji.trim().isEmpty)
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
    unawaited(
      _write((uid) => _financeRepository.saveTransaction(uid, transaction)),
    );
  }

  void updateTransaction(TransactionItem updated) {
    final index = _transactions.indexWhere((txn) => txn.id == updated.id);
    if (index == -1) return;
    _transactions[index] = updated;
    _recomputeTotals();
    notifyListeners();
    if (updated.id != null) {
      unawaited(
        _write(
          (uid) =>
              _financeRepository.updateTransaction(uid, updated.id!, updated),
        ),
      );
    }
  }

  void deleteTransaction(String id) {
    final index = _transactions.indexWhere((txn) => txn.id == id);
    if (index == -1) return;

    if (id.startsWith('debt-')) {
      // Deleting a debt's creation transaction removes the whole debt record.
      final creationIndex = _debts.indexWhere(
        (debt) => debt.creationTransactionId == id,
      );
      if (creationIndex != -1) {
        _transactions.removeAt(index);
        _removeFullDebt(creationIndex);
        return;
      }

      // Deleting a repayment transaction reverts the debt to the value it had
      // before that payment (replaying its repayment history without it).
      final repayIndex = _debts.indexWhere(
        (debt) => debt.repaymentLog.any((entry) => entry.transactionId == id),
      );
      if (repayIndex != -1) {
        final debt = _debts[repayIndex];
        final restored = debt.copyWith(
          repaymentLog: debt.repaymentLog
              .where((entry) => entry.transactionId != id)
              .toList(),
        );
        final (remaining, type) = _replayDebt(restored);
        final (originType, _) = _originOf(restored);
        _transactions.removeAt(index);
        _recomputeTotals();
        _debts[repayIndex] = restored.copyWith(
          type: type,
          remainingAmount: remaining,
          createdType: originType,
          settlement: remaining == 0
              ? DebtSettlement.repaid
              : DebtSettlement.active,
        );
        notifyListeners();
        unawaited(
          _write(
            (uid) => _financeRepository.saveDebt(uid, _debts[repayIndex]),
          ),
        );
        unawaited(_write((uid) => _financeRepository.deleteTransaction(uid, id)));
        return;
      }
    }

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
      subcategories: ['Public transport', 'Ride share', 'Taxi'],
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
      icon: Icons.card_giftcard_rounded,
      subcategories: ['Cashback', 'Prize', 'Gift voucher', 'Other'],
    ),
  ];
}

// Exposes the shared state to every route. The root app owns the ChangeNotifier
// listener and updates this scope, rather than using InheritedNotifier directly.
// This avoids Flutter deactivating an inherited notifier while a dialog route
// still has registered dependents.
class FinanceAppScope extends InheritedWidget {
  const FinanceAppScope({
    super.key,
    required this.state,
    required this.revision,
    required super.child,
  });

  final FinanceAppState state;
  final int revision;

  static FinanceAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FinanceAppScope>();
    assert(scope != null, 'FinanceAppScope not found in widget tree.');
    return scope!.state;
  }

  @override
  bool updateShouldNotify(FinanceAppScope oldWidget) =>
      revision != oldWidget.revision;
}
