import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/analytics/models/analytics_models.dart';
import 'package:pj1/analytics/models/stat_models.dart';
import 'package:pj1/models/finance_models.dart';
import 'package:pj1/utils/currency_settings.dart';
import 'package:pj1/utils/pdf_export.dart';

void main() {
  setUp(() => CurrencySettings.update(code: 'USD', rates: {'USD': 1}));

  TransactionItem txn({
    required double amount,
    required DateTime date,
    bool negative = true,
    String title = 'Coffee',
    String category = 'Food & Drinks',
  }) => TransactionItem(
    id: 't-$date-$amount',
    title: title,
    subtitle: '',
    amount: amount,
    icon: Icons.restaurant_rounded,
    iconColor: const Color(0xFFF97316),
    categoryName: category,
    negative: negative,
    createdAt: date,
  );

  StatisticsBundle sampleBundle() {
    final now = DateTime.now();
    final window = PeriodWindow(
      start: DateTime(now.year, now.month, 1),
      end: now,
      previousStart: now,
      previousEnd: now,
      label: 'This month',
    );
    return StatisticsBundle(
      window: window,
      balanceTrend: TrendSeries(
        points: [
          SeriesPoint(x: DateTime(now.year, now.month, 1), y: 500),
          SeriesPoint(x: DateTime(now.year, now.month, 10), y: 650),
          SeriesPoint(x: now, y: 400),
        ],
        current: 400,
        previous: 500,
      ),
      cashFlow: const CashFlowSummary(
        income: 1000,
        expense: 600,
        net: 400,
        saved: 100,
        incomeVsPrevious: 0,
        expenseVsPrevious: 0,
      ),
      cashFlowTrend: TrendSeries(
        points: const [],
        current: 0,
        previous: 0,
      ),
      categorySpending: [
        CategoryStat(
          id: 'food',
          name: 'Food & Drinks',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFF97316),
          amount: 300,
          percent: 50,
          count: 5,
          avg: 60,
          max: 100,
          min: 10,
          perDay: 10,
          monthlyAvg: 300,
        ),
        CategoryStat(
          id: 'transport',
          name: 'Transportation',
          icon: Icons.directions_bus_rounded,
          color: const Color(0xFF3B82F6),
          amount: 300,
          percent: 50,
          count: 4,
          avg: 75,
          max: 120,
          min: 20,
          perDay: 10,
          monthlyAvg: 300,
        ),
      ],
      spendingTrend: const [],
      topExpenses: [
        TopExpense(txn: txn(amount: 120, date: DateTime.now())),
      ],
      debtRatio: const GaugeResult(
        value: 300,
        ratio: 0.3,
        label: '30% of income goes to debt',
        level: HealthLevel.good,
      ),
      incomeExpenseComparison: const [
        GroupedBar(label: '1', income: 400, expense: 200, net: 200),
        GroupedBar(label: '2', income: 500, expense: 300, net: 200),
      ],
      monthlyOverview: const MonthlyOverview(
        income: 1000,
        expense: 600,
        net: 400,
        saved: 100,
        avgDailySpend: 20,
        busiestDay: 'Monday',
        topCategory: 'Food & Drinks',
        transactionCount: 9,
      ),
      financialHealth: const [],
      categoryAnalytics: const CategoryAnalytics(
        categories: [],
        incomeCategories: [],
        totalSpend: 0,
        totalIncome: 0,
      ),
      incomeAnalytics: const IncomeAnalytics(
        categories: [],
        total: 1000,
        largest: null,
      ),
      weeklyPattern: const [],
      hourlyPattern: const [],
      budgetProgress: const [],
      savingsTrend: const [],
      cashFlowForecast: [
        ForecastPoint(x: DateTime(2026, 1, 1), value: 100, forecast: false),
        ForecastPoint(x: DateTime(2026, 1, 2), value: 200, forecast: true),
        ForecastPoint(x: DateTime(2026, 1, 3), value: 250, forecast: true),
      ],
      balanceHistory: const [],
    );
  }

  group('buildStatisticsPdf', () {
    test('generates a valid PDF with populated sections', () async {
      final bytes = await buildStatisticsPdf(
        bundle: sampleBundle(),
        now: DateTime(2026, 8, 5),
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('handles an empty bundle without crashing', () async {
      final window = PeriodWindow(
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 31),
        previousStart: DateTime(2026, 7, 1),
        previousEnd: DateTime(2026, 7, 31),
        label: 'Empty',
      );
      final empty = StatisticsBundle(
        window: window,
        balanceTrend: TrendSeries(points: const [], current: 0, previous: 0),
        cashFlow: const CashFlowSummary(
          income: 0,
          expense: 0,
          net: 0,
          saved: 0,
          incomeVsPrevious: 0,
          expenseVsPrevious: 0,
        ),
        cashFlowTrend: TrendSeries(points: const [], current: 0, previous: 0),
        categorySpending: const [],
        spendingTrend: const [],
        topExpenses: const [],
        debtRatio: null,
        incomeExpenseComparison: const [],
        monthlyOverview: const MonthlyOverview(
          income: 0,
          expense: 0,
          net: 0,
          saved: 0,
          avgDailySpend: 0,
          busiestDay: '-',
          topCategory: '-',
          transactionCount: 0,
        ),
        financialHealth: const [],
        categoryAnalytics: const CategoryAnalytics(
          categories: [],
          incomeCategories: [],
          totalSpend: 0,
          totalIncome: 0,
        ),
        incomeAnalytics: const IncomeAnalytics(
          categories: [],
          total: 0,
          largest: null,
        ),
        weeklyPattern: const [],
        hourlyPattern: const [],
        budgetProgress: const [],
        savingsTrend: const [],
        cashFlowForecast: const [],
        balanceHistory: const [],
      );
      final bytes = await buildStatisticsPdf(bundle: empty, now: DateTime.now());
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });

  group('buildReportsPdfData', () {
    test('generates a valid PDF with all six reports', () async {
      final now = DateTime(2026, 8, 5);
      final rows = [
        txn(amount: 3000, date: DateTime(2026, 8, 1), negative: false),
        txn(amount: 800, date: DateTime(2026, 8, 2)),
        txn(amount: 200, date: DateTime(2026, 8, 3)),
      ];
      final debts = [
        DebtItem(
          id: 'd1',
          person: 'Alex',
          amount: 150,
          type: DebtType.borrowed,
          createdAt: DateTime(2026, 8, 1),
        ),
      ];
      final budgets = [
        BudgetCategory(
          id: 'b1',
          label: 'Transportation',
          spent: 60,
          limit: 100,
          daysLeft: 16,
          status: 'Healthy',
          statusColor: const Color(0xFF16A34A),
          icon: Icons.directions_bus_rounded,
          iconBg: const Color(0xFFFFF4E8),
          startDate: DateTime(2026, 8, 1),
        ),
      ];
      final goals = [
        SavingsGoal.fromMap('g1', {'title': 'Trip', 'current': 200, 'target': 800}),
      ];
      final bytes = await buildReportsPdfData(
        txns: rows,
        debts: debts,
        budgets: budgets,
        goals: goals,
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 31),
        rangeLabel: 'This month',
        now: now,
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
