import '../models/stat_models.dart';

/// Preset ranges offered to the user. Each maps to a [PeriodWindow] built
/// relative to "now".
enum DateRangePreset {
  today,
  last7,
  last30,
  thisMonth,
  lastMonth,
  thisYear,
  all,
}

/// A user-selected date range. `custom` is supported by supplying explicit
/// start/end dates (inclusive); the [preset] field is ignored when [custom]
/// is true.
class DateRange {
  const DateRange({
    required this.preset,
    this.start,
    this.end,
  }) : custom = start != null;

  const DateRange.preset(DateRangePreset this.preset)
      : start = null,
        end = null,
        custom = false;

  const DateRange.custom({required this.start, required this.end})
      : preset = null,
        custom = true;

  final DateRangePreset? preset;
  final DateTime? start;
  final DateTime? end;
  final bool custom;

  String get label {
    if (custom) return _formatCustom(start!, end!);
    return switch (preset!) {
      DateRangePreset.today => 'Today',
      DateRangePreset.last7 => 'Last 7 days',
      DateRangePreset.last30 => 'Last 30 days',
      DateRangePreset.thisMonth => 'This month',
      DateRangePreset.lastMonth => 'Last month',
      DateRangePreset.thisYear => 'This year',
      DateRangePreset.all => 'All time',
    };
  }

  static String _formatCustom(DateTime start, DateTime end) {
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    return sameDay
        ? '${_mon(start)} ${start.day}'
        : '${_mon(start)} ${start.day} – ${_mon(end)} ${end.day}';
  }

  static String _mon(DateTime d) {
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
    return months[d.month - 1];
  }
}

/// Builds the [PeriodWindow] (plus the previous window of equal length) for a
/// [DateRange] relative to [now]. Days are clamped to day boundaries.
PeriodWindow buildWindowFromDateRange({
  required DateTime now,
  DateRange? range,
}) {
  final resolved = range ?? const DateRange.preset(DateRangePreset.thisMonth);
  final start = _Day.today(now);

  if (resolved.custom) {
    final begin = _Day.today(resolved.start!);
    final endInclusive = _Day.today(resolved.end!);
    final windowLength = endInclusive.difference(begin);
    final previousEnd = begin.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(windowLength);
    return PeriodWindow(
      start: begin,
      end: endInclusive,
      previousStart: previousStart,
      previousEnd: previousEnd,
      label: resolved.label,
    );
  }

  DateTime begin, endInclusive;

  switch (resolved.preset!) {
    case DateRangePreset.today:
      begin = start;
      endInclusive = start;
    case DateRangePreset.last7:
      begin = start.subtract(const Duration(days: 6));
      endInclusive = start;
    case DateRangePreset.last30:
      begin = start.subtract(const Duration(days: 29));
      endInclusive = start;
    case DateRangePreset.thisMonth:
      begin = DateTime(start.year, start.month, 1);
      endInclusive = DateTime(start.year, start.month + 1, 0);
    case DateRangePreset.lastMonth:
      begin = DateTime(start.year, start.month - 1, 1);
      endInclusive = DateTime(start.year, start.month, 0);
    case DateRangePreset.thisYear:
      begin = DateTime(start.year, 1, 1);
      endInclusive = DateTime(start.year, 12, 31);
    case DateRangePreset.all:
      begin = DateTime.fromMillisecondsSinceEpoch(0);
      endInclusive = start.add(const Duration(days: 1));
  }

  final windowLength = endInclusive.difference(begin);
  final previousEnd = begin.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(windowLength);

  return PeriodWindow(
    start: begin,
    end: endInclusive,
    previousStart: previousStart,
    previousEnd: previousEnd,
    label: resolved.label,
  );
}

/// Helper that normalizes a [DateTime] to its day boundary.
class _Day {
  static DateTime today(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Builds an auto window when a full DateRange cannot be resolved.
PeriodWindow buildAutoWindow({DateTime? now}) {
  return buildWindowFromDateRange(
    now: now ?? DateTime.now(),
    range: const DateRange.preset(DateRangePreset.last30),
  );
}

/// The granularity used to bucket a time series for a chosen [PeriodWindow].
enum BucketGranularity { daily, weekly, monthly }

/// Buckets a day by the given granularity, returning the start timestamp.
DateTime bucketStart(DateTime d, BucketGranularity granularity) {
  final day = DateTime(d.year, d.month, d.day);
  switch (granularity) {
    case BucketGranularity.daily:
      return day;
    case BucketGranularity.weekly:
      return day.subtract(Duration(days: day.weekday - DateTime.monday));
    case BucketGranularity.monthly:
      return DateTime(d.year, d.month, 1);
  }
}

/// Ensures [value] stays a sane finite number for rendering.
double clampValue(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return value;
}