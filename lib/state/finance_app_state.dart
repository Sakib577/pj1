import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/finance_models.dart';
import '../services/category_repository.dart';
import '../services/exchange_rate_service.dart';
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
  final List<PlannedPayment> _plannedPayments = [];
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

  Future<void> syncCategoriesForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _stopCategorySync();
      _categorySyncReady = true;
      notifyListeners();
      return;
    }

    if (_syncedUid == user.uid && _categorySyncReady) {
      return;
    }

    _stopCategorySync();
    _syncedUid = user.uid;

    _initialLoad = _loadCategoriesForUser(user.uid);
    await _initialLoad;
  }

  void stopCategorySync() {
    _stopCategorySync();
    notifyListeners();
  }

  void _stopCategorySync() {
    _expenseCategorySubscription?.cancel();
    _incomeCategorySubscription?.cancel();
    _expenseCategorySubscription = null;
    _incomeCategorySubscription = null;
    _initialLoad = null;
    _categorySyncReady = false;
  }

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
    notifyListeners();
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
    await _persistCategory(category: category, isIncome: isIncome);
    notifyListeners();
  }

  Future<void> addSubcategory({
    required String categoryId,
    required String name,
    bool isIncome = false,
  }) async {
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    for (final category in categories) {
      if (category.id == categoryId) {
        if (!category.subcategories.contains(name)) {
          category.subcategories.add(name);
          category.userDefinedSubcategories.add(name);
          await _persistCategory(category: category, isIncome: isIncome);
          notifyListeners();
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
    _moveTransactionsToOther(category.name);
    final uid = _syncedUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      await _categoryRepository.deleteCategory(
        uid: uid,
        isIncome: isIncome,
        categoryId: category.id,
      );
    }
    notifyListeners();
  }

  Future<void> deleteSubcategory({
    required ExpenseCategory category,
    required String subcategory,
    required bool isIncome,
  }) async {
    if (!category.userDefinedSubcategories.remove(subcategory)) return;
    category.subcategories.remove(subcategory);
    _moveTransactionsToOther('${category.name} · $subcategory');
    await _persistCategory(category: category, isIncome: isIncome);
    notifyListeners();
  }

  void _moveTransactionsToOther(String removedCategoryName) {
    for (var index = 0; index < _transactions.length; index++) {
      if (_transactions[index].categoryName == removedCategoryName ||
          _transactions[index].categoryName.startsWith(
            '$removedCategoryName · ',
          )) {
        _transactions[index] = _transactions[index].copyWith(
          categoryName: 'Other',
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
    final now = DateTime.now();

    _balance += isIncome ? value : -value;
    if (isIncome) {
      _income += value;
    } else {
      _expenses += value;
    }

    _transactions.insert(
      0,
      TransactionItem(
        title: subcategory == null
            ? category.name
            : '${category.name} · $subcategory',
        subtitle: _buildSubtitle(now, note),
        amount: value,
        icon: icon,
        iconColor: iconColor,
        categoryName: subcategory == null
            ? category.name
            : '${category.name} · $subcategory',
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        negative: !isIncome,
      ),
    );

    final recentIds = isIncome ? _recentIncomeCategoryIds : _recentCategoryIds;
    recentIds.remove(category.id);
    recentIds.insert(0, category.id);

    notifyListeners();
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
      name: 'Other',
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
