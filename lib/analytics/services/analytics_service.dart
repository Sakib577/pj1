import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../models/analytics_models.dart';
import '../models/stat_models.dart';
import '../../utils/currency_formatters.dart';
import '../utils/date_ranges.dart';

/// A deterministic palette used to color categories when the underlying
/// transaction carries no usable color.
const List<Color> kCategoryPalette = [
  Color(0xFFF59E0B),
  Color(0xFF22C55E),
  Color(0xFF3B82F6),
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFF6366F1),
  Color(0xFF84CC16),
];

/// Pure, side-effect-free computation engine. No UI, no I/O. Every method is
/// deterministic given its inputs so results are trivially cacheable.
class AnalyticsService {
  const AnalyticsService();

  /// Splits a transaction's categoryName into (base category name, subcategory).
  (String, String?) _splitCategory(String categoryName) {
    final idx = categoryName.indexOf(' · ');
    if (idx == -1) return (categoryName, null);
    return (categoryName.substring(0, idx), categoryName.substring(idx + 3));
  }

  bool _inWindow(DateTime? date, PeriodWindow window) {
    if (date == null) return false;
    final d = DateTime(date.year, date.month, date.day);
    final start = window.start;
    final end = window.end;
    return !d.isBefore(start) && !d.isAfter(end);
  }

  double _sumExpense(List<TransactionItem> rows) =>
      rows.where((t) => t.negative).fold<double>(0, (s, t) => s + t.amount);

  double _sumIncome(List<TransactionItem> rows) =>
      rows.where((t) => !t.negative).fold<double>(0, (s, t) => s + t.amount);

  // ------------------------------------------------------------------
  // Balance trend
  // ------------------------------------------------------------------
  /// Daily cumulative balance across [window], computed from all rows up to
  /// each day. Also returns previous-period totals for the delta.
  TrendSeries calculateBalance(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    // Sort ascending by date so we can accumulate a running balance once.
    final sorted = [...rows]..sort((a, b) => _dt(a).compareTo(_dt(b)));

    final prevWindow = PeriodWindow(
      start: window.previousStart,
      end: window.previousEnd,
      previousStart: window.previousStart,
      previousEnd: window.previousEnd,
      label: '',
    );

    final lastByDay = <String, double>{};
    var running = 0.0;
    var curTotal = 0.0;
    var prevTotal = 0.0;
    for (final t in sorted) {
      running += t.negative ? -t.amount : t.amount;
      lastByDay[_dateKey(_dt(t))] = running;
      final d = _dt(t);
      if (_inWindow(d, window)) {
        curTotal += t.negative ? -t.amount : t.amount;
      } else if (_inWindow(d, prevWindow)) {
        prevTotal += t.negative ? -t.amount : t.amount;
      }
    }

    // For each day in the window, the balance is the latest running total at or
    // before that day (i.e. it already includes all earlier activity).
    final points = <SeriesPoint>[];
    var acc = 0.0;
    for (var d = window.start; !d.isAfter(window.end); d = d.add(
      const Duration(days: 1),
    )) {
      final v = lastByDay[_dateKey(d)];
      if (v != null) acc = v;
      points.add(SeriesPoint(x: d, y: clampValue(acc)));
    }

    return TrendSeries(
      points: points,
      current: curTotal,
      previous: prevTotal,
    );
  }

  DateTime _dt(TransactionItem t) =>
      t.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  // ------------------------------------------------------------------
  // Cash flow
  // ------------------------------------------------------------------
  CashFlowSummary calculateCashFlow(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final prev = PeriodWindow(
      start: window.previousStart,
      end: window.previousEnd,
      previousStart: window.previousStart,
      previousEnd: window.previousEnd,
      label: '',
    );
    final curIncome = rows
        .where((t) => !t.negative && _inWindow(t.createdAt, window))
        .fold<double>(0, (s, t) => s + t.amount);
    final curExpense = rows
        .where((t) => t.negative && _inWindow(t.createdAt, window))
        .fold<double>(0, (s, t) => s + t.amount);
    final prevIncome = rows
        .where((t) => !t.negative && _inWindow(t.createdAt, prev))
        .fold<double>(0, (s, t) => s + t.amount);
    final prevExpense = rows
        .where((t) => t.negative && _inWindow(t.createdAt, prev))
        .fold<double>(0, (s, t) => s + t.amount);
    return CashFlowSummary(
      income: curIncome,
      expense: curExpense,
      net: curIncome - curExpense,
      saved: curIncome - curExpense,
      incomeVsPrevious: _delta(curIncome, prevIncome),
      expenseVsPrevious: _delta(curExpense, prevExpense),
    );
  }

  double _delta(double cur, double prev) =>
      prev == 0 ? 0 : ((cur - prev) / prev.abs()) * 100;

  /// Trend of income and expense across buckets for the range.
  TrendSeries calculateCashFlowTrend(
    List<TransactionItem> rows,
    PeriodWindow window,
    BucketGranularity granularity,
  ) {
    final buckets = _buildBuckets(window, granularity);
    final values = <DateTime, double>{};
    for (final key in buckets) {
      values[key] = 0;
    }
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !_inWindow(d, window)) continue;
      final key = bucketStart(d, granularity);
      final inc = t.negative ? -t.amount : t.amount;
      values[key] = (values[key] ?? 0) + inc;
    }
    final points = [
      for (final key in buckets)
        SeriesPoint(x: key, y: clampValue(values[key] ?? 0)),
    ];
    final current = points.fold<double>(0, (s, p) => s + p.y);
    return TrendSeries(
      points: points,
      current: current,
      previous: 0,
    );
  }

  List<DateTime> _buildBuckets(
    PeriodWindow window,
    BucketGranularity granularity,
  ) {
    final result = <DateTime>[];
    final start = bucketStart(window.start, granularity);
    final end = window.end;
    var cursor = start;
    final step = switch (granularity) {
      BucketGranularity.daily => const Duration(days: 1),
      BucketGranularity.weekly => const Duration(days: 7),
      BucketGranularity.monthly => const Duration(days: 31),
    };
    var guard = 0;
    while (!cursor.isAfter(end) && guard < 2000) {
      result.add(cursor);
      // Roll back to a clean month boundary when stepping monthly.
      if (granularity == BucketGranularity.monthly) {
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      } else {
        cursor = cursor.add(step);
      }
      guard++;
    }
    return result;
  }

  // ------------------------------------------------------------------
  // Category spending
  // ------------------------------------------------------------------
  List<CategoryStat> calculateCategorySpending(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final grouped = <String, List<TransactionItem>>{};
    for (final t in rows) {
      if (!t.negative || !_inWindow(t.createdAt, window)) continue;
      final (base, _) = _splitCategory(t.categoryName);
      grouped.putIfAbsent(base, () => []).add(t);
    }
    final total = grouped.values.fold<double>(
      0,
      (s, list) => s + list.fold<double>(0, (a, t) => a + t.amount),
    );
    final days = window.end.difference(window.start).inDays + 1;
    final months = math.max(1, (days / 30).round());

    final entries = grouped.entries.map((e) {
      final list = e.value;
      final amounts = list.map((t) => t.amount).toList()..sort();
      final sum = amounts.fold<double>(0, (s, a) => s + a);
      final icon = list.first.icon;
      final color = list.first.iconColor != const Color(0xFFF97316)
          ? list.first.iconColor
          : _categoryColor(e.key);
      return CategoryStat(
        id: e.key,
        name: e.key,
        icon: icon,
        color: color,
        amount: sum,
        percent: total == 0 ? 0 : (sum / total) * 100,
        count: list.length,
        avg: list.isEmpty ? 0 : sum / list.length,
        max: amounts.isEmpty ? 0 : amounts.last,
        min: amounts.isEmpty ? 0 : amounts.first,
        perDay: days == 0 ? 0 : sum / days,
        monthlyAvg: sum / months,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return entries;
  }

  Color _categoryColor(String name) {
    var hash = 0;
    for (final c in name.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return kCategoryPalette[hash % kCategoryPalette.length];
  }

  // ------------------------------------------------------------------
  // Spending trend
  // ------------------------------------------------------------------
  List<TrendSeries> calculateSpendingTrend(
    List<TransactionItem> rows,
    PeriodWindow window,
    BucketGranularity granularity,
  ) {
    final buckets = _buildBuckets(window, granularity);
    final income = <DateTime, double>{};
    final expense = <DateTime, double>{};
    for (final key in buckets) {
      income[key] = 0;
      expense[key] = 0;
    }
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !_inWindow(d, window)) continue;
      final key = bucketStart(d, granularity);
      if (t.negative) {
        expense[key] = (expense[key] ?? 0) + t.amount;
      } else {
        income[key] = (income[key] ?? 0) + t.amount;
      }
    }
    final expensePoints = [
      for (final key in buckets)
        SeriesPoint(x: key, y: clampValue(expense[key] ?? 0)),
    ];
    return [
      TrendSeries(
        points: expensePoints,
        current: expensePoints.fold<double>(0, (s, p) => s + p.y),
        previous: 0,
      ),
    ];
  }

  // ------------------------------------------------------------------
  // Top expenses
  // ------------------------------------------------------------------
  List<TopExpense> calculateTopExpenses(
    List<TransactionItem> rows,
    PeriodWindow window, {
    int n = 5,
  }) {
    final expenses = rows.where(
      (t) => t.negative && _inWindow(t.createdAt, window),
    ).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(n).map((t) => TopExpense(txn: t)).toList();
  }

  // ------------------------------------------------------------------
  // Debt-to-income
  // ------------------------------------------------------------------
  GaugeResult? calculateDebtRatio(
    List<DebtItem> debts,
    double periodIncome,
  ) {
    final activeDebt = debts
        .where((d) => d.settlement == DebtSettlement.active)
        .fold<double>(0, (s, d) => s + d.amount);
    if (periodIncome <= 0) return null;
    final ratio = (activeDebt / periodIncome).clamp(0, 3).toDouble();
    final level = ratio < 0.36
        ? HealthLevel.good
        : ratio < 0.43
        ? HealthLevel.moderate
        : HealthLevel.poor;
    return GaugeResult(
      value: activeDebt,
      ratio: ratio,
      label: _dtiLabel(ratio),
      level: level,
    );
  }

  String _dtiLabel(double ratio) {
    if (ratio < 0.36) return 'Healthy';
    if (ratio < 0.43) return 'Moderate';
    return 'High';
  }

  // ------------------------------------------------------------------
  // Income vs expense grouped bars
  // ------------------------------------------------------------------
  List<GroupedBar> calculateIncomeExpenseComparison(
    List<TransactionItem> rows,
    PeriodWindow window,
    BucketGranularity granularity,
  ) {
    final buckets = _buildBuckets(window, granularity);
    final income = <DateTime, double>{};
    final expense = <DateTime, double>{};
    for (final key in buckets) {
      income[key] = 0;
      expense[key] = 0;
    }
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !_inWindow(d, window)) continue;
      final key = bucketStart(d, granularity);
      if (t.negative) {
        expense[key] = (expense[key] ?? 0) + t.amount;
      } else {
        income[key] = (income[key] ?? 0) + t.amount;
      }
    }
    final labels = {
      BucketGranularity.daily: 'Day',
      BucketGranularity.weekly: 'Week',
      BucketGranularity.monthly: 'Month',
    };
    return [
      for (final key in buckets)
        GroupedBar(
          label: _bucketLabel(key, granularity, labels[granularity]!),
          income: income[key] ?? 0,
          expense: expense[key] ?? 0,
          net: (income[key] ?? 0) - (expense[key] ?? 0),
        ),
    ];
  }

  String _bucketLabel(DateTime key, BucketGranularity g, String kind) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return switch (g) {
      BucketGranularity.daily => '${key.day}',
      BucketGranularity.weekly => 'W${key.day}',
      _ => months[key.month - 1],
    };
  }

  // ------------------------------------------------------------------
  // Monthly overview
  // ------------------------------------------------------------------
  MonthlyOverview calculateMonthlyOverview(
    List<TransactionItem> rows,
    PeriodWindow window,
    BucketGranularity granularity,
  ) {
    final inWindow = rows.where((t) => _inWindow(t.createdAt, window)).toList();
    final income = _sumIncome(inWindow);
    final expense = _sumExpense(inWindow);
    final days = window.end.difference(window.start).inDays + 1;
    final avgDaily = days == 0 ? 0.0 : expense / days;

    final byDay = <String, double>{};
    for (final t in inWindow) {
      final d = t.createdAt!;
      byDay['${d.year}-${d.month}-${d.day}'] =
          (byDay['${d.year}-${d.month}-${d.day}'] ?? 0) + t.amount;
    }
    String busiest = '–';
    double maxDay = 0;
    byDay.forEach((k, v) {
      if (v > maxDay) {
        maxDay = v;
        busiest = k;
      }
    });
    busiest = busiest == '–' ? '–' : '${_mon(int.parse(busiest.split('-')[1]))} ${int.parse(busiest.split('-')[2])}';

    final catSpend = <String, double>{};
    for (final t in inWindow) {
      if (!t.negative) continue;
      final (base, _) = _splitCategory(t.categoryName);
      catSpend[base] = (catSpend[base] ?? 0) + t.amount;
    }
    String topCategory = '–';
    double topCatAmount = 0;
    catSpend.forEach((k, v) {
      if (v > topCatAmount) {
        topCatAmount = v;
        topCategory = k;
      }
    });

    return MonthlyOverview(
      income: income,
      expense: expense,
      net: income - expense,
      saved: income - expense,
      avgDailySpend: avgDaily,
      busiestDay: busiest,
      topCategory: topCategory,
      transactionCount: inWindow.length,
    );
  }

  String _mon(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }

  // ------------------------------------------------------------------
  // Financial health
  // ------------------------------------------------------------------
  List<FinancialHealthMetric> calculateFinancialHealth(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final inWindow = rows.where((t) => _inWindow(t.createdAt, window)).toList();
    final income = _sumIncome(inWindow);
    final expense = _sumExpense(inWindow);
    final savingsRate = income == 0
        ? 0.0
        : ((income - expense) / income).clamp(0, 1).toDouble();
    // Expense concentration: how much of the total spend sits in one category.
    final catSpend = <String, double>{};
    for (final t in inWindow) {
      if (!t.negative) continue;
      final (base, _) = _splitCategory(t.categoryName);
      catSpend[base] = (catSpend[base] ?? 0) + t.amount;
    }
    final topCat = catSpend.isEmpty
        ? 0.0
        : catSpend.values.reduce(math.max);
    final concentration = expense == 0 ? 0.0 : (topCat / expense);
    final diversification = (1 - concentration).clamp(0.0, 1.0).toDouble();
    final fre = inWindow.isEmpty
        ? 0.0
        : inWindow.where((t) => !t.negative).length / inWindow.length;

    return [
      FinancialHealthMetric(
        label: 'Savings rate',
        value: savingsRate,
        message: '${(savingsRate * 100).toStringAsFixed(0)}% of income saved',
      ),
      FinancialHealthMetric(
        label: 'Diversification',
        value: diversification,
        message: 'Spending spread across ${catSpend.length} categories',
      ),
      FinancialHealthMetric(
        label: 'Income stability',
        value: fre,
        message:
            '${(fre * 100).toStringAsFixed(0)}% of transactions are income',
      ),
      FinancialHealthMetric(
        label: 'Expense control',
        value: expense == 0 ? 1.0 : (1 - (expense - math.min(income, expense)) / math.max(expense, 1)).clamp(0, 1),
        message: expense == 0
            ? 'No expenses recorded'
            : '${formatCurrency(expense)} spent this period',
      ),
    ];
  }

  // ------------------------------------------------------------------
  // Category analytics
  // ------------------------------------------------------------------
  CategoryAnalytics calculateCategoryAnalytics(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final expenses = calculateCategorySpending(rows, window);
    final incomeByCat = <String, List<TransactionItem>>{};
    for (final t in rows) {
      if (t.negative || !_inWindow(t.createdAt, window)) continue;
      final (base, _) = _splitCategory(t.categoryName);
      incomeByCat.putIfAbsent(base, () => []).add(t);
    }
    final totalIncome = incomeByCat.values.fold<double>(
      0,
      (s, list) => s + list.fold<double>(0, (a, t) => a + t.amount),
    );
    final days = window.end.difference(window.start).inDays + 1;
    final months = math.max(1, (days / 30).round());
    final incomeStats = incomeByCat.entries.map((e) {
      final amounts = e.value.map((t) => t.amount).toList()..sort();
      final sum = amounts.fold<double>(0, (s, a) => s + a);
      return CategoryStat(
        id: e.key,
        name: e.key,
        icon: e.value.first.icon,
        color: _categoryColor(e.key),
        amount: sum,
        percent: totalIncome == 0 ? 0 : (sum / totalIncome) * 100,
        count: e.value.length,
        avg: amounts.isEmpty ? 0 : sum / amounts.length,
        max: amounts.isEmpty ? 0 : amounts.last,
        min: amounts.isEmpty ? 0 : amounts.first,
        perDay: days == 0 ? 0 : sum / days,
        monthlyAvg: sum / months,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return CategoryAnalytics(
      categories: expenses,
      incomeCategories: incomeStats,
      totalSpend: expenses.fold<double>(0, (s, c) => s + c.amount),
      totalIncome: totalIncome,
    );
  }

  // ------------------------------------------------------------------
  // Income analytics
  // ------------------------------------------------------------------
  IncomeAnalytics calculateIncomeAnalytics(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final inWindow = rows.where(
      (t) => !t.negative && _inWindow(t.createdAt, window),
    ).toList();
    final total = inWindow.fold<double>(0, (s, t) => s + t.amount);
    final grouped = <String, List<TransactionItem>>{};
    for (final t in inWindow) {
      final (base, _) = _splitCategory(t.categoryName);
      grouped.putIfAbsent(base, () => []).add(t);
    }
    final days = window.end.difference(window.start).inDays + 1;
    final months = math.max(1, (days / 30).round());
    final stats = grouped.entries.map((e) {
      final amounts = e.value.map((t) => t.amount).toList()..sort();
      final sum = amounts.fold<double>(0, (s, a) => s + a);
      return CategoryStat(
        id: e.key,
        name: e.key,
        icon: e.value.first.icon,
        color: _categoryColor(e.key),
        amount: sum,
        percent: total == 0 ? 0 : (sum / total) * 100,
        count: e.value.length,
        avg: amounts.isEmpty ? 0 : sum / amounts.length,
        max: amounts.isEmpty ? 0 : amounts.last,
        min: amounts.isEmpty ? 0 : amounts.first,
        perDay: days == 0 ? 0 : sum / days,
        monthlyAvg: sum / months,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    List<TransactionItem> largestList = [...inWindow]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return IncomeAnalytics(
      categories: stats,
      total: total,
      largest: largestList.isEmpty ? null : largestList.first,
    );
  }

  // ------------------------------------------------------------------
  // Weekly & hourly pattern
  // ------------------------------------------------------------------
  List<SeriesPoint> calculateWeeklyPattern(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final sums = List.filled(7, 0.0);
    final counts = List.filled(7, 0);
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !t.negative || !_inWindow(d, window)) continue;
      sums[d.weekday - 1] += t.amount;
      counts[d.weekday - 1]++;
    }
    return List.generate(7, (i) {
      return SeriesPoint(
        x: DateTime(2026, 1, i + 5),
        y: counts[i] == 0 ? 0.0 : sums[i] / counts[i],
      );
    });
  }

  List<SeriesPoint> calculateHourlyPattern(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final sums = List.filled(24, 0.0);
    final counts = List.filled(24, 0);
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !t.negative || !_inWindow(d, window)) continue;
      sums[d.hour] += t.amount;
      counts[d.hour]++;
    }
    return List.generate(24, (i) {
      final avg = counts[i] == 0 ? 0.0 : sums[i] / counts[i];
      return SeriesPoint(x: DateTime(2026, 1, 1, i), y: avg);
    });
  }

  // ------------------------------------------------------------------
  // Budget progress
  // ------------------------------------------------------------------
  List<BudgetProgress> calculateBudgetProgress(
    List<BudgetCategory> budgets,
    List<TransactionItem> transactions,
  ) {
    return budgets.map((budget) {
      double spent = 0;
      for (final t in transactions) {
        if (!t.negative) continue;
        if (budget.period == 'monthly') {
          final now = DateTime.now();
          if (t.createdAt != null &&
              t.createdAt!.year == now.year &&
              t.createdAt!.month == now.month) {
            spent += t.amount;
          }
        } else if (budget.period == 'category') {
          if (t.categoryName == budget.label ||
              t.categoryName.startsWith('${budget.label} · ')) {
            spent += t.amount;
          }
        }
      }
      final ratio = budget.limit <= 0
          ? 0.0
          : (spent / budget.limit).clamp(0, 1).toDouble();
      final remaining = (budget.limit - spent)
          .clamp(0, double.infinity)
          .toDouble();
      Color color;
      String status;
      if (ratio > 1) {
        color = const Color(0xFFEF4444);
        status = 'Over budget';
      } else if (ratio > 0.75) {
        color = const Color(0xFFF59E0B);
        status = 'Nearly spent';
      } else {
        color = const Color(0xFF22C55E);
        status = 'Healthy';
      }
      return BudgetProgress(
        budget: budget,
        spent: spent,
        remaining: remaining,
        ratio: ratio,
        status: status,
        statusColor: color,
      );
    }).toList();
  }

  // ------------------------------------------------------------------
  // Savings trend
  // ------------------------------------------------------------------
  List<TrendSeries> calculateSavingsTrend(
    List<TransactionItem> rows,
    PeriodWindow window,
    List<SavingsGoal> goals,
  ) {
    final buckets = _buildBuckets(window, BucketGranularity.monthly);
    final savings = <DateTime, double>{};
    for (final key in buckets) {
      savings[key] = 0;
    }
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !_inWindow(d, window)) continue;
      if (!t.negative && _isSavings(t)) {
        savings[bucketStart(d, BucketGranularity.monthly)] =
            (savings[bucketStart(d, BucketGranularity.monthly)] ?? 0) +
            t.amount;
      }
    }
    final points = [
      for (final key in buckets)
        SeriesPoint(x: key, y: clampValue(savings[key] ?? 0)),
    ];
    return [
      TrendSeries(
        points: points,
        current: points.fold<double>(0, (s, p) => s + p.y),
        previous: 0,
      ),
    ];
  }

  bool _isSavings(TransactionItem t) {
    final (base, _) = _splitCategory(t.categoryName);
    return base.toLowerCase().contains('saving') ||
        t.icon == Icons.savings_outlined;
  }

  // ------------------------------------------------------------------
  // Cash flow forecast
  // ------------------------------------------------------------------
  List<ForecastPoint> calculateCashFlowForecast(
    List<TransactionItem> rows,
    PeriodWindow window, {
    int horizonDays = 14,
  }) {
    // Simple linear projection of the daily net over the recent window tail.
    final inWindow = rows.where((t) => _inWindow(t.createdAt, window)).toList();
    final days = window.end.difference(window.start).inDays + 1;
    final avgDaily = days == 0
        ? 0.0
        : inWindow.fold<double>(0, (s, t) => s + (t.negative ? -t.amount : t.amount)) / days;

    final last = window.end;
    final result = <ForecastPoint>[];
    for (var i = 1; i <= horizonDays; i++) {
      result.add(
        ForecastPoint(
          x: last.add(Duration(days: i)),
          value: avgDaily,
          forecast: true,
        ),
      );
    }
    // Anchor with the last actual date, using the same daily-net scale as the
    // forecast points so the Y axis stays proportional to the recent spend.
    final actualAnchor = inWindow.isEmpty
        ? window.start
        : (inWindow.map((t) => t.createdAt!).toList()
      ..sort()
    ).last;
    result.insert(
      0,
      ForecastPoint(
        x: actualAnchor,
        value: avgDaily,
        forecast: false,
      ),
    );
    return result;
  }

  // ------------------------------------------------------------------
  // Balance history ranges
  // ------------------------------------------------------------------
  List<TrendSeries> calculateBalanceHistory(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final trend = calculateBalance(rows, window);
    return [trend];
  }

  // ------------------------------------------------------------------
  // Longest streak
  // ------------------------------------------------------------------
  int calculateLongestStreak(
    List<TransactionItem> rows,
    PeriodWindow window,
  ) {
    final days = <String>{};
    for (final t in rows) {
      final d = t.createdAt;
      if (d == null || !_inWindow(d, window)) continue;
      days.add(_dateKey(d));
    }
    var best = 0;
    var cur = 0;
    for (var d = window.start; !d.isAfter(window.end); d = d.add(
      const Duration(days: 1),
    )) {
      if (days.contains(_dateKey(d))) {
        cur++;
        best = math.max(best, cur);
      } else {
        cur = 0;
      }
    }
    return best;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}