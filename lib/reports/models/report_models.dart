import 'package:flutter/material.dart';

/// A single row in an accounting statement.
class ReportLineItem {
  const ReportLineItem({
    required this.label,
    required this.amount,
    this.icon,
    this.color,
    this.isTotal = false,
    this.indent = 0,
  });

  final String label;
  final double amount;
  final IconData? icon;
  final Color? color;
  final bool isTotal;
  final int indent;
}

/// A section of a statement (e.g. Operating Activities) with separate
/// income/expense sub-lists and a subtotal line.
class ReportSection {
  const ReportSection({
    required this.title,
    required this.icon,
    required this.incomeItems,
    required this.expenseItems,
    required this.subtotal,
    this.subtotalLabel = 'Net cash from activities',
  });

  final String title;
  final IconData icon;
  final List<ReportLineItem> incomeItems;
  final List<ReportLineItem> expenseItems;
  final double subtotal;
  final String subtotalLabel;
}

/// Cash Flow Statement — the formal accounting report that classifies cash
/// flows into operating, investing and financing activities for a period.
class CashFlowStatementReport {
  const CashFlowStatementReport({
    required this.operating,
    required this.investing,
    required this.financing,
    required this.netCashFlow,
    required this.beginningCash,
    required this.endingCash,
  });

  final ReportSection operating;
  final ReportSection investing;
  final ReportSection financing;
  final double netCashFlow;
  final double beginningCash;
  final double endingCash;
}

/// Income Statement (Profit & Loss): income vs expenses for a period.
class IncomeStatementReport {
  const IncomeStatementReport({
    required this.incomeItems,
    required this.expenseItems,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netIncome,
    required this.grossMargin,
  });

  final List<ReportLineItem> incomeItems;
  final List<ReportLineItem> expenseItems;
  final double totalIncome;
  final double totalExpenses;
  final double netIncome;
  final double grossMargin;
}

/// One budget-vs-actual variance row.
class BudgetVarianceRow {
  const BudgetVarianceRow({
    required this.category,
    required this.budget,
    required this.actual,
    required this.variance,
    required this.ratio,
  });

  final String category;
  final double budget;
  final double actual;
  final double variance;
  final double ratio;
}

/// Budget vs Actual report for the active budget period(s).
class BudgetVsActualReport {
  const BudgetVsActualReport({
    required this.rows,
    required this.totalBudget,
    required this.totalActual,
    required this.totalVariance,
  });

  final List<BudgetVarianceRow> rows;
  final double totalBudget;
  final double totalActual;
  final double totalVariance;
}

/// Balance Sheet report: assets, liabilities and net worth as of today.
class BalanceSheetReport {
  const BalanceSheetReport({
    required this.assetItems,
    required this.liabilityItems,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });

  final List<ReportLineItem> assetItems;
  final List<ReportLineItem> liabilityItems;
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
}

/// Debt summary report: borrowed vs lent and active vs settled.
class DebtReport {
  const DebtReport({
    required this.borrowedActive,
    required this.borrowedSettled,
    required this.lentActive,
    required this.lentSettled,
    required this.totalBorrowed,
    required this.totalLent,
    required this.netPosition,
  });

  final List<ReportLineItem> borrowedActive;
  final List<ReportLineItem> borrowedSettled;
  final List<ReportLineItem> lentActive;
  final List<ReportLineItem> lentSettled;
  final double totalBorrowed;
  final double totalLent;
  final double netPosition;
}

/// A single savings-goal progress row.
class SavingsGoalRow {
  const SavingsGoalRow({
    required this.title,
    required this.current,
    required this.target,
    required this.progress,
  });

  final String title;
  final double current;
  final double target;
  final double progress;
}

/// Savings & Net Worth report.
class SavingsNetWorthReport {
  const SavingsNetWorthReport({
    required this.goals,
    required this.totalSaved,
    required this.totalTarget,
    required this.savingsRate,
    required this.periodContribution,
    required this.periodWithdrawal,
  });

  final List<SavingsGoalRow> goals;
  final double totalSaved;
  final double totalTarget;
  final double savingsRate;
  final double periodContribution;
  final double periodWithdrawal;
}

/// The kind of report shown on the Reports page.
enum ReportKind {
  cashFlowStatement,
  incomeStatement,
  balanceSheet,
  budgetVsActual,
  debt,
  savingsNetWorth,
}

extension ReportKindLabel on ReportKind {
  String get label => switch (this) {
    ReportKind.cashFlowStatement => 'Cash Flow Statement',
    ReportKind.incomeStatement => 'Income Statement',
    ReportKind.balanceSheet => 'Balance Sheet',
    ReportKind.budgetVsActual => 'Budget vs Actual',
    ReportKind.debt => 'Debt Report',
    ReportKind.savingsNetWorth => 'Savings & Net Worth',
  };

  String get description => switch (this) {
    ReportKind.cashFlowStatement =>
      'Cash inflows and outflows split into operating, investing and financing activities.',
    ReportKind.incomeStatement =>
      'Earnings and spending for the period — your profit or loss.',
    ReportKind.balanceSheet =>
      'What you own, what you owe, and your net worth at this moment.',
    ReportKind.budgetVsActual =>
      'Planned budget limits compared with actual spending.',
    ReportKind.debt =>
      'Money borrowed and money lent, with settlement status.',
    ReportKind.savingsNetWorth =>
      'Savings-goal progress and how much of your income you keep.',
  };

  IconData get icon => switch (this) {
    ReportKind.cashFlowStatement => Icons.account_balance_wallet_rounded,
    ReportKind.incomeStatement => Icons.receipt_long_rounded,
    ReportKind.balanceSheet => Icons.account_balance_rounded,
    ReportKind.budgetVsActual => Icons.donut_large_rounded,
    ReportKind.debt => Icons.handshake_rounded,
    ReportKind.savingsNetWorth => Icons.savings_rounded,
  };
}