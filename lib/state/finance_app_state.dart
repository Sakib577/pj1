import 'package:flutter/material.dart';

import '../models/finance_models.dart';

class FinanceAppState extends ChangeNotifier {
  double _balance = 0;
  double _income = 0;
  double _expenses = 0;
  final List<TransactionItem> _transactions = [];
  final List<CategoryItem> _categories = [];
  final List<PlannedPayment> _plannedPayments = [];
  final List<BudgetCategory> _budgets = [];
  final List<SavingsGoal> _goals = [];

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
  List<PlannedPayment> get plannedPayments => List.unmodifiable(_plannedPayments);
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

  void addTransaction({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required bool isIncome,
  }) {
    final value = amount.abs();
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
        title: title,
        subtitle: _buildSubtitle(now),
        amount: value,
        icon: icon,
        iconColor: iconColor,
        negative: !isIncome,
      ),
    );

    notifyListeners();
  }

  String _buildSubtitle(DateTime date) {
    final month = _monthLabel(date.month);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$month ${date.day}, $hour:$minute $period';
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
}

class FinanceAppScope extends InheritedNotifier<FinanceAppState> {
  const FinanceAppScope({super.key, required FinanceAppState notifier, required super.child})
      : super(notifier: notifier);

  static FinanceAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FinanceAppScope>();
    assert(scope != null, 'FinanceAppScope not found in widget tree.');
    return scope!.notifier!;
  }
}
