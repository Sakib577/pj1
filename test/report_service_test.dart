import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/models/finance_models.dart';
import 'package:pj1/reports/services/report_service.dart';

void main() {
  const service = ReportService();

  TransactionItem txn({
    required double amount,
    required DateTime date,
    bool negative = true,
    String category = 'Food & Drinks',
  }) => TransactionItem(
    id: 't-${date.microsecondsSinceEpoch}-$amount',
    title: category,
    subtitle: '',
    amount: amount,
    icon: Icons.restaurant_rounded,
    iconColor: const Color(0xFFF97316),
    categoryName: category,
    negative: negative,
    createdAt: date,
  );

  group('calculateCashFlowStatement', () {
    test('classifies operating, investing and financing flows', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 31);
      final rows = [
        // Operating income + expense
        txn(
          amount: 3000,
          date: DateTime(2026, 8, 5),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 800,
          date: DateTime(2026, 8, 6),
          category: 'Housing · Rent or mortgage',
        ),
        // Investing: buying stocks (expense) and dividends (income)
        txn(
          amount: 500,
          date: DateTime(2026, 8, 10),
          category: 'Investments · Stocks & ETFs',
        ),
        txn(
          amount: 40,
          date: DateTime(2026, 8, 12),
          negative: false,
          category: 'Dividends · Stock dividends',
        ),
        // Financing: borrowing + savings contribution
        txn(
          amount: 1000,
          date: DateTime(2026, 8, 15),
          negative: false,
          category: 'Debt',
        ),
        txn(
          amount: 200,
          date: DateTime(2026, 8, 16),
          category: 'Savings · Other',
        ),
      ];

      final report = service.calculateCashFlowStatement(rows, start, end);

      // Operating = 3000 salary - 800 rent = 2200
      expect(report.operating.subtotal, closeTo(2200, 0.001));
      // Investing = 40 dividends - 500 stocks = -460
      expect(report.investing.subtotal, closeTo(-460, 0.001));
      // Financing = 1000 borrowed - 200 savings contribution = 800
      expect(report.financing.subtotal, closeTo(800, 0.001));
      // Net = 2200 - 460 + 800 = 2540
      expect(report.netCashFlow, closeTo(2540, 0.001));
    });

    test('beginning cash is the running balance before the window', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 31);
      final rows = [
        txn(
          amount: 500,
          date: DateTime(2026, 7, 15),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 100,
          date: DateTime(2026, 8, 5),
          category: 'Food & Drinks · Groceries',
        ),
      ];
      final report = service.calculateCashFlowStatement(rows, start, end);
      expect(report.beginningCash, closeTo(500, 0.001));
      expect(report.endingCash, closeTo(400, 0.001));
    });

    test('empty window produces zero flows and equal cash figures', () {
      final report = service.calculateCashFlowStatement(
        [],
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );
      expect(report.netCashFlow, 0);
      expect(report.operating.subtotal, 0);
      expect(report.investing.subtotal, 0);
      expect(report.financing.subtotal, 0);
      expect(report.endingCash, report.beginningCash);
    });
  });

  group('calculateIncomeStatement', () {
    test('computes totals, net and margin', () {
      final rows = [
        txn(
          amount: 2500,
          date: DateTime(2026, 8, 1),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 900,
          date: DateTime(2026, 8, 2),
          category: 'Housing · Rent or mortgage',
        ),
        txn(
          amount: 300,
          date: DateTime(2026, 8, 3),
          category: 'Food & Drinks · Groceries',
        ),
      ];
      final report = service.calculateIncomeStatement(
        rows,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );
      expect(report.totalIncome, closeTo(2500, 0.001));
      expect(report.totalExpenses, closeTo(1200, 0.001));
      expect(report.netIncome, closeTo(1300, 0.001));
      expect(report.grossMargin, closeTo(52, 0.001));
    });

    test('ignores rows outside the period', () {
      final rows = [
        txn(
          amount: 1000,
          date: DateTime(2026, 7, 15),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 500,
          date: DateTime(2026, 9, 1),
          category: 'Food & Drinks · Groceries',
        ),
      ];
      final report = service.calculateIncomeStatement(
        rows,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );
      expect(report.totalIncome, 0);
      expect(report.totalExpenses, 0);
      expect(report.netIncome, 0);
    });
  });

  group('calculateBalanceSheet', () {
    test('includes cash, savings and active debts', () {
      final rows = [
        txn(
          amount: 1000,
          date: DateTime(2026, 8, 1),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 200,
          date: DateTime(2026, 8, 2),
          category: 'Food & Drinks · Groceries',
        ),
      ];
      final debts = [
        DebtItem(
          id: 'lent-1',
          person: 'Alex',
          amount: 150,
          type: DebtType.lent,
          createdAt: DateTime(2026, 8, 3),
        ),
        DebtItem(
          id: 'borrowed-1',
          person: 'Sam',
          amount: 80,
          type: DebtType.borrowed,
          createdAt: DateTime(2026, 8, 4),
        ),
        DebtItem(
          id: 'repaid-1',
          person: 'Old',
          amount: 500,
          type: DebtType.borrowed,
          settlement: DebtSettlement.repaid,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
      final goals = [
        SavingsGoal.fromMap('g1', {'title': 'Emergency', 'current': 300, 'target': 1000}),
      ];
      final report = service.calculateBalanceSheet(rows, debts, goals);
      expect(report.totalAssets, closeTo(800 + 300 + 150, 0.001));
      expect(report.totalLiabilities, closeTo(80, 0.001));
      expect(report.netWorth, closeTo(800 + 300 + 150 - 80, 0.001));
    });
  });

  group('calculateBudgetVsActual', () {
    test('compares budget limit to actual spending', () {
      // "now" matches the real current month so category-period budgets are
      // compared against actual spending recorded this month.
      final now = DateTime.now();
      final categoryBudget = BudgetCategory(
        id: 'b2',
        label: 'Transportation',
        spent: 0,
        limit: 100,
        daysLeft: 16,
        status: 'Healthy',
        statusColor: const Color(0xFF16A34A),
        icon: Icons.directions_bus_rounded,
        iconBg: const Color(0xFFFFF4E8),
        period: 'category',
        startDate: DateTime(2026, 8, 1),
      );
      final rows = [
        txn(
          amount: 60,
          date: now,
          category: 'Transportation · Public transport',
        ),
        txn(
          amount: 50,
          date: now,
          category: 'Transportation · Taxi',
        ),
      ];
      final report = service.calculateBudgetVsActual([categoryBudget], rows);
      expect(report.rows.length, 1);
      expect(report.rows.first.actual, closeTo(110, 0.001));
      expect(report.rows.first.variance, closeTo(-10, 0.001));
      expect(report.rows.first.ratio, closeTo(1, 0.001));
    });
  });

  group('calculateDebtReport', () {
    test('splits borrowed vs lent and active vs settled', () {
      final debts = [
        DebtItem(
          id: '1',
          person: 'A',
          amount: 100,
          type: DebtType.borrowed,
          createdAt: DateTime(2026, 1, 1),
        ),
        DebtItem(
          id: '2',
          person: 'B',
          amount: 50,
          type: DebtType.lent,
          createdAt: DateTime(2026, 1, 2),
        ),
        DebtItem(
          id: '3',
          person: 'C',
          amount: 30,
          type: DebtType.borrowed,
          settlement: DebtSettlement.repaid,
          createdAt: DateTime(2026, 1, 3),
        ),
      ];
      final report = service.calculateDebtReport(debts);
      expect(report.borrowedActive.length, 1);
      expect(report.lentActive.length, 1);
      expect(report.borrowedSettled.length, 1);
      expect(report.totalBorrowed, closeTo(130, 0.001));
      expect(report.totalLent, closeTo(50, 0.001));
      expect(report.netPosition, closeTo(80, 0.001));
    });

    test('empty debts produces zero report', () {
      final report = service.calculateDebtReport([]);
      expect(report.totalBorrowed, 0);
      expect(report.totalLent, 0);
      expect(report.netPosition, 0);
    });
  });

  group('calculateSavingsNetWorth', () {
    test('aggregates goals and period contributions', () {
      final goals = [
        SavingsGoal.fromMap('g1', {'title': 'Trip', 'current': 200, 'target': 800}),
        SavingsGoal.fromMap('g2', {'title': 'Fund', 'current': 150, 'target': 500}),
      ];
      final rows = [
        txn(
          amount: 1000,
          date: DateTime(2026, 8, 1),
          negative: false,
          category: 'Salary & Wages · Base salary',
        ),
        txn(
          amount: 700,
          date: DateTime(2026, 8, 2),
          category: 'Food & Drinks · Groceries',
        ),
        txn(
          amount: 50,
          date: DateTime(2026, 8, 3),
          category: 'Savings',
        ),
      ];
      final report = service.calculateSavingsNetWorth(
        goals,
        rows,
        DateTime(2026, 8, 1),
        DateTime(2026, 8, 31),
      );
      expect(report.goals.length, 2);
      expect(report.totalSaved, closeTo(350, 0.001));
      expect(report.totalTarget, closeTo(1300, 0.001));
      expect(report.periodContribution, closeTo(50, 0.001));
      // Savings rate = (1000 - 700) / 1000 = 30%
      expect(report.savingsRate, closeTo(0.3, 0.001));
    });
  });
}