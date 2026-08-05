import 'package:flutter/material.dart';

import '../../models/finance_models.dart';
import '../utils/date_ranges.dart';

/// A bounded date window used by every analytics computation.
///
/// [start]/[end] are inclusive day boundaries. [previousStart]/[previousEnd]
/// describe the window of exactly the same length immediately before [start],
/// used for all "vs previous period" comparisons.
class PeriodWindow {
  const PeriodWindow({
    required this.start,
    required this.end,
    required this.previousStart,
    required this.previousEnd,
    required this.label,
  });

  factory PeriodWindow.fromDateRange({DateTime? now}) {
    return buildWindowFromDateRange(now: now ?? DateTime.now());
  }

  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime previousEnd;
  final String label;

  Duration get length => end.difference(start);
}

/// A single data point on any time series.
class SeriesPoint {
  const SeriesPoint({required this.x, required this.y});

  final DateTime x;
  final double y;
}

/// A time series plus delta-percentage between the period totals and the
/// previous period totals, used by trend cards.
class TrendSeries {
  const TrendSeries({
    required this.points,
    required this.current,
    required this.previous,
  });

  final List<SeriesPoint> points;
  final double current;
  final double previous;

  /// Percentage change vs the previous period. Returns 0 when there is no
  /// meaningful baseline to compare against.
  double get deltaPercent {
    if (previous == 0) return 0;
    return ((current - previous) / previous.abs()) * 100;
  }

  bool get isUp => deltaPercent >= 0;
}

/// One column of a grouped income / expense / net comparison. The optional
/// [date] carries the bucket start so consumers can render time-series lines
/// as well as bars.
class GroupedBar {
  const GroupedBar({
    required this.label,
    required this.income,
    required this.expense,
    required this.net,
    this.date,
  });

  final String label;
  final double income;
  final double expense;
  final double net;
  final DateTime? date;
}

/// Aggregated statistics for a single spending category within a range.
class CategoryStat {
  const CategoryStat({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percent,
    required this.count,
    required this.avg,
    required this.max,
    required this.min,
    required this.perDay,
    required this.monthlyAvg,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;
  final double percent;
  final int count;
  final double avg;
  final double max;
  final double min;
  final double perDay;
  final double monthlyAvg;
}

/// One of the user's largest individual expense transactions.
class TopExpense {
  const TopExpense({required this.txn});

  final TransactionItem txn;
}

/// A circular-gauge reading with a health classification.
enum HealthLevel { good, moderate, poor }

class GaugeResult {
  const GaugeResult({
    required this.value,
    required this.ratio,
    required this.label,
    required this.level,
  });

  final double value;
  final double ratio;
  final String label;
  final HealthLevel level;
}

/// A single point of a series that may be a projected (future) value.
class ForecastPoint {
  const ForecastPoint({
    required this.x,
    required this.value,
    required this.forecast,
  });

  final DateTime x;
  final double value;
  final bool forecast;
}