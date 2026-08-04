import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/analytics/models/stat_models.dart';
import 'package:pj1/analytics/services/analytics_service.dart';
import 'package:pj1/analytics/utils/date_ranges.dart';
import 'package:pj1/models/finance_models.dart';

void main() {
  const service = AnalyticsService();

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

  group('PeriodWindow', () {
    test('last30 builds a 30-day window plus equal previous window', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(
        now: now,
        range: const DateRange.preset(DateRangePreset.last30),
      );
      expect(w.end, DateTime(2026, 8, 5));
      expect(w.start, DateTime(2026, 7, 7));
      expect(w.length.inDays, 29);
      // Previous window is the same length immediately before start.
      expect(w.previousEnd, DateTime(2026, 7, 6));
      expect(w.previousStart, DateTime(2026, 6, 7));
    });

    test('thisMonth starts on the 1st with equal-length previous window', () {
      final now = DateTime(2026, 3, 15);
      final w = buildWindowFromDateRange(
        now: now,
        range: const DateRange.preset(DateRangePreset.thisMonth),
      );
      expect(w.start, DateTime(2026, 3, 1));
      expect(w.end, DateTime(2026, 3, 31));
      // Previous window is the same length immediately before start: 30 days.
      expect(w.previousEnd, DateTime(2026, 2, 28));
      expect(w.previousStart, DateTime(2026, 1, 29));
      expect(w.length, const Duration(days: 30));
    });

    test('custom range uses provided start/end with equal previous window',
        () {
      final w = buildWindowFromDateRange(
        now: DateTime(2026, 8, 5),
        range: DateRange.custom(
          start: DateTime(2026, 8, 1),
          end: DateTime(2026, 8, 5),
        ),
      );
      expect(w.start, DateTime(2026, 8, 1));
      expect(w.end, DateTime(2026, 8, 5));
      expect(w.label, 'Aug 1 – Aug 5');
      expect(w.previousEnd, DateTime(2026, 7, 31));
      expect(w.previousStart, DateTime(2026, 7, 27));
    });

    test('leap year: lastMonth of March ends Feb 29', () {
      final now = DateTime(2024, 3, 10);
      final w = buildWindowFromDateRange(
        now: now,
        range: const DateRange.preset(DateRangePreset.lastMonth),
      );
      expect(w.start, DateTime(2024, 2, 1));
      expect(w.end, DateTime(2024, 2, 29));
    });
  });

  group('calculateCashFlow', () {
    test('computes income/expense/net and previous deltas', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 100, date: now),
        txn(amount: 40, date: now),
        txn(amount: 200, date: DateTime(2026, 7, 20), negative: false),
        // Before previous window: should be ignored entirely.
        txn(amount: 9999, date: DateTime(2025, 1, 1)),
      ];
      final flow = service.calculateCashFlow(rows, w);
      expect(flow.income, 200);
      expect(flow.expense, 140);
      expect(flow.net, 60);
      expect(flow.saved, 60);
    });
  });

  group('calculateCategorySpending', () {
    test('groups by base category and computes percentages', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 50, date: now, category: 'Food & Drinks'),
        txn(amount: 30, date: now, category: 'Food & Drinks'),
        txn(amount: 20, date: now, category: 'Transportation'),
      ];
      final stats = service.calculateCategorySpending(rows, w);
      expect(stats.length, 2);
      expect(stats.first.name, 'Food & Drinks');
      expect(stats.first.amount, 80);
      expect(stats.first.percent, 80);
      expect(stats.first.count, 2);
      expect(stats.first.avg, 40);
      expect(stats.first.max, 50);
    });

    test('splits subcategory suffixes into the base category', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 10, date: now, category: 'Shopping · Medicine'),
        txn(amount: 5, date: now, category: 'Shopping · Health'),
      ];
      final stats = service.calculateCategorySpending(rows, w);
      expect(stats.length, 1);
      expect(stats.first.name, 'Shopping');
      expect(stats.first.amount, 15);
    });
  });

  group('calculateDebtRatio', () {
    test('returns null when there is no income', () {
      expect(service.calculateDebtRatio([], 0), isNull);
    });

    test('classifies good vs high DTI', () {
      final good = service.calculateDebtRatio(
        [
          DebtItem(
            id: '1',
            person: 'A',
            amount: 100,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        1000,
      );
      expect(good, isNotNull);
      expect(good!.level, HealthLevel.good);

      final high = service.calculateDebtRatio(
        [
          DebtItem(
            id: '2',
            person: 'B',
            amount: 900,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        1000,
      );
      expect(high!.level, HealthLevel.poor);
    });

    test('ignores repaid debts', () {
      final result = service.calculateDebtRatio(
        [
          DebtItem(
            id: '3',
            person: 'C',
            amount: 500,
            settlement: DebtSettlement.repaid,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        1000,
      );
      expect(result!.value, 0);
    });
  });

  group('calculateBalance', () {
    test('produces a daily cumulative balance series', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 100, date: DateTime(2026, 8, 3), negative: false),
        txn(amount: 40, date: DateTime(2026, 8, 4)),
      ];
      final trend = service.calculateBalance(rows, w);
      // The final point reflects the running total at the end of the window.
      expect(trend.points, isNotEmpty);
      expect(trend.points.last.y, 60);
      expect(trend.current, 60);
    });
  });

  group('calculateFinancialHealth', () {
    test('returns four metrics', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 1000, date: now, negative: false),
        txn(amount: 400, date: now),
      ];
      final metrics = service.calculateFinancialHealth(rows, w);
      expect(metrics.length, 4);
      final savings = metrics.firstWhere((m) => m.label == 'Savings rate');
      expect(savings.value, closeTo(0.6, 0.001));
    });
  });

  group('calculateLongestStreak', () {
    test('counts consecutive active days', () {
      final now = DateTime(2026, 8, 5);
      final w = buildWindowFromDateRange(now: now);
      final rows = [
        txn(amount: 10, date: DateTime(2026, 8, 1)),
        txn(amount: 10, date: DateTime(2026, 8, 2)),
        txn(amount: 10, date: DateTime(2026, 8, 3)),
        // gap on the 4th
        txn(amount: 10, date: DateTime(2026, 8, 5)),
      ];
      expect(service.calculateLongestStreak(rows, w), 3);
    });
  });

  group('bucketStart', () {
    test('weekly buckets to Monday', () {
      // 2026-08-06 is a Thursday.
      final start = bucketStart(
        DateTime(2026, 8, 6),
        BucketGranularity.weekly,
      );
      expect(start.weekday, DateTime.monday);
    });

    test('monthly buckets to the 1st', () {
      final start = bucketStart(
        DateTime(2026, 8, 21),
        BucketGranularity.monthly,
      );
      expect(start, DateTime(2026, 8, 1));
    });
  });

  group('TrendSeries delta', () {
    test('deltaPercent computes growth', () {
      const s = TrendSeries(points: [], current: 120, previous: 100);
      expect(s.deltaPercent, 20);
      expect(s.isUp, isTrue);
    });

    test('deltaPercent is 0 with no baseline', () {
      const s = TrendSeries(points: [], current: 50, previous: 0);
      expect(s.deltaPercent, 0);
    });
  });
}