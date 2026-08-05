import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import 'stat_models.dart';

/// Summary figures for a period (income, expense, net, and saved).
class CashFlowSummary {
  const CashFlowSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.saved,
    required this.incomeVsPrevious,
    required this.expenseVsPrevious,
    required this.netVsPrevious,
  });

  final double income;
  final double expense;
  final double net;
  final double saved;
  final double incomeVsPrevious;
  final double expenseVsPrevious;
  final double netVsPrevious;
}

/// Eight headline figures shown on the Monthly Overview card.
class MonthlyOverview {
  const MonthlyOverview({
    required this.income,
    required this.expense,
    required this.net,
    required this.saved,
    required this.avgDailySpend,
    required this.busiestDay,
    required this.topCategory,
    required this.transactionCount,
  });

  final double income;
  final double expense;
  final double net;
  final double saved;
  final double avgDailySpend;
  final String busiestDay;
  final String topCategory;
  final int transactionCount;
}

/// Loaded insight metrics for financial health, each on ~0..1 scale where a
/// higher value is better, plus a human message per metric.
class FinancialHealthMetric {
  const FinancialHealthMetric({
    required this.label,
    required this.value,
    required this.message,
  });

  final String label;
  final double value;
  final String message;
}

/// A projection of next month's total expense, split into the recurring
/// scheduled bills and the variable-spending baseline it was built from.
class NextMonthEstimate {
  const NextMonthEstimate({
    required this.scheduledBills,
    required this.variableBaseline,
    required this.basisLabel,
    required this.history,
  });

  final double scheduledBills;
  final double variableBaseline;

  /// Human-readable description of where the variable baseline came from
  /// (e.g. "median of last 3 months" or "current month's pace").
  final String basisLabel;

  /// Recent months of actual spending (chronological), ending with the next
  /// month's projected total so a card can render a comparison chart.
  final List<MonthlySpendPoint> history;

  double get total => scheduledBills + variableBaseline;
}

/// One bar in the estimate's comparison chart: a recent month of actual
/// spending, or the projected next month ([isEstimate]).
class MonthlySpendPoint {
  const MonthlySpendPoint({
    required this.label,
    required this.amount,
    required this.isEstimate,
  });

  final String label;
  final double amount;
  final bool isEstimate;
}

/// The full per-category analytics dataset (spending + income combined).
class CategoryAnalytics {
  const CategoryAnalytics({
    required this.categories,
    required this.incomeCategories,
    required this.totalSpend,
    required this.totalIncome,
  });

  final List<CategoryStat> categories;
  final List<CategoryStat> incomeCategories;
  final double totalSpend;
  final double totalIncome;
}

/// Income source analytics: by category plus the largest single income.
class IncomeAnalytics {
  const IncomeAnalytics({
    required this.categories,
    required this.total,
    required this.largest,
  });

  final List<CategoryStat> categories;
  final double total;
  final TransactionItem? largest;
}

/// The full statistics bundle computed for an active range.
class StatisticsBundle {
  const StatisticsBundle({
    required this.window,
    required this.balanceTrend,
    required this.cashFlow,
    required this.cashFlowTrend,
    required this.categorySpending,
    required this.spendingTrend,
    required this.topExpenses,
    required this.debtRatio,
    required this.incomeExpenseComparison,
    required this.monthlyOverview,
    required this.financialHealth,
    required this.categoryAnalytics,
    required this.incomeAnalytics,
    required this.weeklyPattern,
    required this.hourlyPattern,
    required this.budgetProgress,
    required this.savingsTrend,
    required this.cashFlowForecast,
    required this.balanceHistory,
  });

  final PeriodWindow window;
  final TrendSeries balanceTrend;
  final CashFlowSummary cashFlow;
  final TrendSeries cashFlowTrend;
  final List<CategoryStat> categorySpending;
  final List<TrendSeries> spendingTrend;
  final List<TopExpense> topExpenses;
  final GaugeResult? debtRatio;
  final List<GroupedBar> incomeExpenseComparison;
  final MonthlyOverview monthlyOverview;
  final List<FinancialHealthMetric> financialHealth;
  final CategoryAnalytics categoryAnalytics;
  final IncomeAnalytics incomeAnalytics;
  final List<SeriesPoint> weeklyPattern;
  final List<SeriesPoint> hourlyPattern;
  final List<BudgetProgress> budgetProgress;
  final List<TrendSeries> savingsTrend;
  final List<ForecastPoint> cashFlowForecast;
  final List<TrendSeries> balanceHistory;
}

class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.ratio,
    required this.status,
    required this.statusColor,
  });

  final BudgetCategory budget;
  final double spent;
  final double remaining;
  final double ratio;
  final String status;
  final Color statusColor;
}