import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../models/report_models.dart';

/// Pure, side-effect-free computation engine for accounting reports.
///
/// Unlike the analytics module (which summarises income/expense), this engine
/// classifies every transaction into the standard accounting activities so the
/// app can produce formal statements such as a Cash Flow Statement.
class ReportService {
  const ReportService();

  // ------------------------------------------------------------------
  // Cash Flow Statement
  // ------------------------------------------------------------------

  /// Builds a formal Cash Flow Statement for [window].
  ///
  /// - Operating activities: everyday income and expenses (salary, groceries,
  ///   rent, dining, transport, subscriptions, taxes, etc.).
  /// - Investing activities: buying/selling assets (stocks, real estate,
  ///   equipment) and related dividends/interest received.
  /// - Financing activities: borrowing money, repaying debt, and any money
  ///   moved to/from savings as capital flows.
  CashFlowStatementReport calculateCashFlowStatement(
    List<TransactionItem> rows,
    DateTime start,
    DateTime end,
  ) {
    final inWindow = rows
        .where(
          (t) =>
              t.createdAt != null &&
              !t.createdAt!.isBefore(start) &&
              !t.createdAt!.isAfter(end),
        )
        .toList();

    final operatingIncome = _groupIncome(
      inWindow,
      (t) => _operatingKeywordMatch(t.categoryName) &&
          !_investingKeywordMatch(t.categoryName) &&
          !_financingKeywordMatch(t.categoryName),
    );
    final operatingExpense = _groupExpense(
      inWindow,
      (t) => _operatingKeywordMatch(t.categoryName) &&
          !_investingKeywordMatch(t.categoryName) &&
          !_financingKeywordMatch(t.categoryName),
    );

    final investingIncome = _groupIncome(
      inWindow,
      (t) => _investingKeywordMatch(t.categoryName),
    );
    final investingExpense = _groupExpense(
      inWindow,
      (t) => _investingKeywordMatch(t.categoryName),
    );

    // Financing: borrowings, loan repayments, and savings flows.
    final financingIncome = _groupIncome(
      inWindow,
      (t) => _financingKeywordMatch(t.categoryName),
    );
    final financingExpense = _groupExpense(
      inWindow,
      (t) => _financingKeywordMatch(t.categoryName),
    );

    final operating = ReportSection(
      title: 'Operating Activities',
      icon: Icons.storefront_rounded,
      incomeItems: operatingIncome,
      expenseItems: operatingExpense,
      subtotal: _sectionNet(operatingIncome, operatingExpense),
    );
    final investing = ReportSection(
      title: 'Investing Activities',
      icon: Icons.trending_up_rounded,
      incomeItems: investingIncome,
      expenseItems: investingExpense,
      subtotal: _sectionNet(investingIncome, investingExpense),
    );
    final financing = ReportSection(
      title: 'Financing Activities',
      icon: Icons.account_balance_rounded,
      incomeItems: financingIncome,
      expenseItems: financingExpense,
      subtotal: _sectionNet(financingIncome, financingExpense),
    );

    final netCashFlow =
        operating.subtotal + investing.subtotal + financing.subtotal;

    // Beginning cash = the running balance at the day before start,
    // computed from all transactions before the window.
    final before = rows
        .where(
          (t) => t.createdAt != null && t.createdAt!.isBefore(start),
        )
        .fold<double>(
          0,
          (s, t) => s + (t.negative ? -t.amount : t.amount),
        );

    return CashFlowStatementReport(
      operating: operating,
      investing: investing,
      financing: financing,
      netCashFlow: netCashFlow,
      beginningCash: before,
      endingCash: before + netCashFlow,
    );
  }

  bool _operatingKeywordMatch(String category) {
    final lower = category.toLowerCase();
    const keywords = [
      'salary', 'wages', 'bonus', 'commission', 'allowance', 'overtime',
      'freelance', 'consulting', 'contract', 'side', 'content',
      'food', 'drink', 'grocery', 'restaurant', 'cafe', 'snack', 'delivery',
      'shopping', 'clothes', 'medicine', 'electronics', 'accessor', 'gift',
      'health', 'home', 'beauty', 'jewellery', 'jewelry', 'kids', 'pets',
      'stationery', 'diy',
      'housing', 'rent', 'mortgage', 'utility', 'furniture', 'repairs',
      'transport', 'public transport', 'ride', 'taxi', 'bicycle',
      'vehicle', 'fuel', 'parking', 'maintenance',
      'fitness', 'charity', 'culture', 'event', 'education', 'healthcare',
      'hobbies', 'travel', 'holiday',
      'entertainment', 'book', 'audiobook', 'subscription', 'sports', 'games',
      'movie', 'show',
      'communication', 'internet', 'phone', 'postage',
      'software', 'cloud', 'digital',
      'bank charge', 'professional fee', 'child support', 'fines', 'fees',
      'tax', 'insurance',
      'dues', 'refund', 'reimbursement', 'cashback', 'prize', 'voucher',
      'missing', 'other',
    ];
    return keywords.any(lower.contains);
  }

  bool _investingKeywordMatch(String category) {
    final lower = category.toLowerCase();
    const keywords = [
      'stock', 'etf', 'mutual fund', 'bond', 'dividend', 'fund distribut',
      'real estate', 'property', 'asset', 'retirement', 'investment',
      'equipment rent',
    ];
    return keywords.any(lower.contains);
  }

  bool _financingKeywordMatch(String category) {
    final lower = category.toLowerCase();
    const keywords = [
      'loan', 'borrow', 'debt', 'repayment', 'lend', 'partial repayment',
      'saving', 'fixed deposit', 'interest',
    ];
    return keywords.any(lower.contains);
  }

  List<ReportLineItem> _groupIncome(
    List<TransactionItem> rows,
    bool Function(TransactionItem) where,
  ) {
    final grouped = <String, double>{};
    for (final t in rows) {
      if (t.negative || !where(t)) continue;
      final base = _baseCategory(t.categoryName);
      grouped[base] = (grouped[base] ?? 0) + t.amount;
    }
    return _toLineItems(grouped, positive: true);
  }

  List<ReportLineItem> _groupExpense(
    List<TransactionItem> rows,
    bool Function(TransactionItem) where,
  ) {
    final grouped = <String, double>{};
    for (final t in rows) {
      if (!t.negative || !where(t)) continue;
      final base = _baseCategory(t.categoryName);
      grouped[base] = (grouped[base] ?? 0) + t.amount;
    }
    return _toLineItems(grouped, positive: false);
  }

  List<ReportLineItem> _toLineItems(
    Map<String, double> grouped, {
    required bool positive,
  }) {
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in entries)
        ReportLineItem(
          label: entry.key,
          amount: positive ? entry.value : -entry.value,
          color: positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
        ),
    ];
  }

  double _sectionNet(
    List<ReportLineItem> income,
    List<ReportLineItem> expense,
  ) {
    final inc = income.fold<double>(0, (s, i) => s + i.amount);
    final exp = expense.fold<double>(0, (s, e) => s + e.amount);
    return inc + exp;
  }

  String _baseCategory(String categoryName) {
    final idx = categoryName.indexOf(' · ');
    return idx == -1 ? categoryName : categoryName.substring(0, idx);
  }

  // ------------------------------------------------------------------
  // Income Statement (Profit & Loss)
  // ------------------------------------------------------------------

  IncomeStatementReport calculateIncomeStatement(
    List<TransactionItem> rows,
    DateTime start,
    DateTime end,
  ) {
    final inWindow = rows
        .where(
          (t) =>
              t.createdAt != null &&
              !t.createdAt!.isBefore(start) &&
              !t.createdAt!.isAfter(end),
        )
        .toList();

    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};
    for (final t in inWindow) {
      final base = _baseCategory(t.categoryName);
      if (t.negative) {
        expenseMap[base] = (expenseMap[base] ?? 0) + t.amount;
      } else {
        incomeMap[base] = (incomeMap[base] ?? 0) + t.amount;
      }
    }

    final incomeItems = _toLineItems(incomeMap, positive: true);
    final expenseItems = _toLineItems(expenseMap, positive: false);

    final totalIncome = incomeItems.fold<double>(0, (s, i) => s + i.amount);
    // Line items use the accounting sign convention (negative for outflows),
    // but the statement totals are reported as positive magnitudes.
    final totalExpenses = expenseItems.fold<double>(0, (s, e) => s + e.amount).abs();
    final netIncome = totalIncome - totalExpenses;
    final grossMargin = totalIncome == 0 ? 0.0 : (netIncome / totalIncome) * 100;

    return IncomeStatementReport(
      incomeItems: incomeItems,
      expenseItems: expenseItems,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netIncome: netIncome,
      grossMargin: grossMargin,
    );
  }

  // ------------------------------------------------------------------
  // Balance Sheet
  // ------------------------------------------------------------------

  /// Builds a simplified balance sheet as of [asOf].
  ///
  /// - Current cash = running balance from all transactions (debt activity is
  ///   already recorded as transactions by the app).
  /// - Savings = current savings-goal balances.
  /// - Money lent (active) is an asset; money borrowed (active) is a liability.
  BalanceSheetReport calculateBalanceSheet(
    List<TransactionItem> rows,
    List<DebtItem> debts,
    List<SavingsGoal> goals, {
    DateTime? asOf,
  }) {
    final cutoff = asOf ?? DateTime.now();

    // Cash = running net of all transactions up to cutoff.
    final cash = rows
        .where((t) => t.createdAt != null && !t.createdAt!.isAfter(cutoff))
        .fold<double>(
          0,
          (s, t) => s + (t.negative ? -t.amount : t.amount),
        );

    final savingsTotal = goals.fold<double>(0, (s, g) => s + g.current);

    final lentActive = debts
        .where(
          (d) =>
              d.type == DebtType.lent &&
              d.settlement == DebtSettlement.active,
        )
        .fold<double>(0, (s, d) => s + d.amount);
    final borrowedActive = debts
        .where(
          (d) =>
              d.type == DebtType.borrowed &&
              d.settlement == DebtSettlement.active,
        )
        .fold<double>(0, (s, d) => s + d.amount);

    final assetItems = <ReportLineItem>[
      ReportLineItem(
        label: 'Cash & bank',
        amount: cash,
        icon: Icons.payments_rounded,
        color: const Color(0xFF16A34A),
      ),
      if (savingsTotal != 0)
        ReportLineItem(
          label: 'Savings goals',
          amount: savingsTotal,
          icon: Icons.savings_rounded,
          color: const Color(0xFF16A34A),
        ),
      if (lentActive != 0)
        ReportLineItem(
          label: 'Money lent (active)',
          amount: lentActive,
          icon: Icons.currency_exchange_rounded,
          color: const Color(0xFF16A34A),
        ),
    ];

    final liabilityItems = <ReportLineItem>[
      if (borrowedActive != 0)
        ReportLineItem(
          label: 'Money borrowed (active)',
          amount: -borrowedActive,
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFFDC2626),
        ),
    ];

    final totalAssets = cash + savingsTotal + lentActive;
    final totalLiabilities = borrowedActive;
    final netWorth = totalAssets - totalLiabilities;

    return BalanceSheetReport(
      assetItems: assetItems,
      liabilityItems: liabilityItems,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: netWorth,
    );
  }

  // ------------------------------------------------------------------
  // Budget vs Actual
  // ------------------------------------------------------------------

  BudgetVsActualReport calculateBudgetVsActual(
    List<BudgetCategory> budgets,
    List<TransactionItem> rows,
  ) {
    final rowsList = <BudgetVarianceRow>[];
    double totalBudget = 0;
    double totalActual = 0;
    for (final budget in budgets) {
      final actual = _budgetSpend(budget, rows);
      totalBudget += budget.limit;
      totalActual += actual;
      rowsList.add(
        BudgetVarianceRow(
          category: budget.label,
          budget: budget.limit,
          actual: actual,
          variance: budget.limit - actual,
          ratio: budget.limit <= 0 ? 0 : (actual / budget.limit).clamp(0, 1),
        ),
      );
    }
    return BudgetVsActualReport(
      rows: rowsList,
      totalBudget: totalBudget,
      totalActual: totalActual,
      totalVariance: totalBudget - totalActual,
    );
  }

  double _budgetSpend(BudgetCategory budget, List<TransactionItem> rows) {
    var spent = 0.0;
    final now = DateTime.now();
    for (final t in rows) {
      if (!t.negative || t.createdAt == null) continue;
      if (budget.period == 'monthly') {
        if (t.createdAt!.year == now.year && t.createdAt!.month == now.month) {
          spent += t.amount;
        }
      } else if (budget.period == 'category') {
        if (t.categoryName == budget.label ||
            t.categoryName.startsWith('${budget.label} · ')) {
          spent += t.amount;
        }
      } else {
        // thirtyDays / custom rolling periods.
        if (_inRollingWindow(t.createdAt!, budget)) {
          spent += t.amount;
        }
      }
    }
    return spent;
  }

  bool _inRollingWindow(DateTime date, BudgetCategory budget) {
    final now = DateTime.now();
    final days = budget.period == 'thirtyDays' ? 30 : budget.customDays;
    if (days < 1) return false;
    var start = budget.startDate;
    var guard = 0;
    while (start.add(Duration(days: days)).isBefore(now) && guard < 2000) {
      start = start.add(Duration(days: days));
      guard++;
    }
    return !date.isBefore(start) && date.isBefore(start.add(Duration(days: days)));
  }

  // ------------------------------------------------------------------
  // Debt report
  // ------------------------------------------------------------------

  DebtReport calculateDebtReport(List<DebtItem> debts) {
    final borrowedActive = <ReportLineItem>[];
    final borrowedSettled = <ReportLineItem>[];
    final lentActive = <ReportLineItem>[];
    final lentSettled = <ReportLineItem>[];

    for (final debt in debts) {
      final line = ReportLineItem(
        label: debt.person,
        amount: debt.type == DebtType.borrowed ? debt.amount : -debt.amount,
        icon: Icons.person_outline_rounded,
        color: debt.type == DebtType.borrowed
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
      );
      if (debt.type == DebtType.borrowed) {
        if (debt.settlement == DebtSettlement.active) {
          borrowedActive.add(line);
        } else {
          borrowedSettled.add(line);
        }
      } else {
        if (debt.settlement == DebtSettlement.active) {
          lentActive.add(line);
        } else {
          lentSettled.add(line);
        }
      }
    }

    final totalBorrowed = borrowedActive.fold<double>(0, (s, i) => s + i.amount) +
        borrowedSettled.fold<double>(0, (s, i) => s + i.amount);
    final totalLent = -lentActive.fold<double>(0, (s, i) => s + i.amount) -
        lentSettled.fold<double>(0, (s, i) => s + i.amount);

    return DebtReport(
      borrowedActive: borrowedActive,
      borrowedSettled: borrowedSettled,
      lentActive: lentActive,
      lentSettled: lentSettled,
      totalBorrowed: totalBorrowed,
      totalLent: totalLent,
      netPosition: totalBorrowed - totalLent,
    );
  }

  // ------------------------------------------------------------------
  // Savings & Net Worth
  // ------------------------------------------------------------------

  SavingsNetWorthReport calculateSavingsNetWorth(
    List<SavingsGoal> goals,
    List<TransactionItem> rows,
    DateTime start,
    DateTime end,
  ) {
    final goalRows = [
      for (final goal in goals)
        SavingsGoalRow(
          title: goal.title,
          current: goal.current,
          target: goal.target,
          progress: goal.target <= 0 ? 0 : (goal.current / goal.target).clamp(0, 1),
        ),
    ];
    final totalSaved = goals.fold<double>(0, (s, g) => s + g.current);
    final totalTarget = goals.fold<double>(0, (s, g) => s + g.target);

    final inWindow = rows
        .where(
          (t) =>
              t.createdAt != null &&
              !t.createdAt!.isBefore(start) &&
              !t.createdAt!.isAfter(end),
        )
        .toList();
    final income = inWindow
        .where((t) => !t.negative)
        .fold<double>(0, (s, t) => s + t.amount);

    double contribution = 0;
    double withdrawal = 0;
    for (final t in inWindow) {
      final base = _baseCategory(t.categoryName);
      if (!base.toLowerCase().contains('saving')) continue;
      if (t.negative) {
        contribution += t.amount;
      } else {
        withdrawal += t.amount;
      }
    }
    // Money moved to savings is not "spent" — exclude it from the expense base
    // so the savings rate reflects true spending on consumption.
    final totalExpenses = inWindow
        .where((t) => t.negative)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = totalExpenses - contribution;

    return SavingsNetWorthReport(
      goals: goalRows,
      totalSaved: totalSaved,
      totalTarget: totalTarget,
      savingsRate: income == 0 ? 0 : ((income - expense) / income).clamp(0, 1),
      periodContribution: contribution,
      periodWithdrawal: withdrawal,
    );
  }
}