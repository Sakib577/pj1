import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';
import '../charts/stat_bar_chart.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import '../utils/date_ranges.dart';
import 'balance_history_card.dart';
import 'range_segmented_control.dart';
import 'stat_card.dart';

/// The trend views offered by the unified [TrendsCard].
enum TrendsView {
  balance('Balance'),
  spending('Spending'),
  cashFlow('Cash Flow'),
  incomeVsExpense('Income vs Expense'),
  savings('Savings'),
  history('History');

  const TrendsView(this.label);
  final String label;
}

enum _CashFlowMode { trend, cumulative }

/// Unified trends card. One place to inspect every time-series in the app:
/// balance, spending, income/expense cash flow, savings and balance history.
///
/// The trend is chosen from a dropdown in the card header; secondary controls
/// (granularity, cumulative vs per-bucket, history window) appear next to it
/// only when the selected view supports them.
class TrendsCard extends StatefulWidget {
  const TrendsCard({
    super.key,
    required this.balanceTrend,
    required this.spendingByGranularity,
    required this.cashFlowBars,
    required this.incomeExpenseByGranularity,
    required this.savingsSeries,
    required this.savingsGoal,
    required this.historyByRange,
    this.rangeLabel,
  });

  final TrendSeries balanceTrend;

  /// Expense per day/week/month within the range.
  final Map<BucketGranularity, List<SeriesPoint>> spendingByGranularity;

  /// Daily income/expense buckets used by the Cash Flow view.
  final List<GroupedBar> cashFlowBars;

  /// Income/expense grouped bars at each granularity for the comparison view.
  final Map<BucketGranularity, List<GroupedBar>> incomeExpenseByGranularity;

  final List<TrendSeries> savingsSeries;
  final double? savingsGoal;
  final Map<BalanceHistoryRange, List<SeriesPoint>> historyByRange;
  final String? rangeLabel;

  @override
  State<TrendsCard> createState() => _TrendsCardState();
}

class _TrendsCardState extends State<TrendsCard> {
  TrendsView _view = TrendsView.balance;
  BucketGranularity _spendingGranularity = BucketGranularity.daily;
  _CashFlowMode _cashFlowMode = _CashFlowMode.trend;
  BucketGranularity _granularity = BucketGranularity.monthly;
  BalanceHistoryRange _historyRange = BalanceHistoryRange.month;

  Widget? get _subMode {
    switch (_view) {
      case TrendsView.balance:
      case TrendsView.savings:
        return null;
      case TrendsView.spending:
        return StatSegmentedControl<BucketGranularity>(
          value: _spendingGranularity,
          options: const [
            (BucketGranularity.daily, 'Daily'),
            (BucketGranularity.weekly, 'Weekly'),
            (BucketGranularity.monthly, 'Monthly'),
          ],
          onChanged: (g) => setState(() => _spendingGranularity = g),
        );
      case TrendsView.cashFlow:
        return StatSegmentedControl<_CashFlowMode>(
          value: _cashFlowMode,
          options: const [
            (_CashFlowMode.trend, 'Trend'),
            (_CashFlowMode.cumulative, 'Cumulative'),
          ],
          onChanged: (m) => setState(() => _cashFlowMode = m),
        );
      case TrendsView.incomeVsExpense:
        return StatSegmentedControl<BucketGranularity>(
          value: _granularity,
          options: const [
            (BucketGranularity.daily, 'Daily'),
            (BucketGranularity.weekly, 'Weekly'),
            (BucketGranularity.monthly, 'Monthly'),
          ],
          onChanged: (g) => setState(() => _granularity = g),
        );
      case TrendsView.history:
        return StatSegmentedControl<BalanceHistoryRange>(
          value: _historyRange,
          options: BalanceHistoryRange.values
              .map((r) => (r, r.label))
              .toList(),
          onChanged: (r) => setState(() => _historyRange = r),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatCard(
      title: 'Trends',
      icon: Icons.multiline_chart_rounded,
      subtitle: widget.rangeLabel,
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StatSegmentedControl<TrendsView>(
          value: _view,
          options: TrendsView.values.map((v) => (v, v.label)).toList(),
          onChanged: (v) => setState(() => _view = v),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_subMode != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: _subMode!,
            ),
            const SizedBox(height: 8),
          ],
          switch (_view) {
            TrendsView.balance => _BalanceContent(trend: widget.balanceTrend),
            TrendsView.spending => _SpendingContent(
              points: widget.spendingByGranularity[_spendingGranularity] ??
                  const <SeriesPoint>[],
              granularity: _spendingGranularity,
            ),
            TrendsView.cashFlow => _CashFlowContent(
              bars: widget.cashFlowBars,
              cumulative: _cashFlowMode == _CashFlowMode.cumulative,
            ),
            TrendsView.incomeVsExpense => _IncomeVsExpenseContent(
              bars: widget.incomeExpenseByGranularity[_granularity] ??
                  const <GroupedBar>[],
            ),
            TrendsView.savings => _SavingsContent(
              series: widget.savingsSeries,
              goalTarget: widget.savingsGoal,
            ),
            TrendsView.history => _HistoryContent(
              points: widget.historyByRange[_historyRange] ??
                  const <SeriesPoint>[],
            ),
          },
        ],
      ),
    );
  }
}

class _BalanceContent extends StatelessWidget {
  const _BalanceContent({required this.trend});

  final TrendSeries trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = trend.points;
    return points.isEmpty
        ? const SizedBox(
            height: 90,
            child: Center(child: Text('No transactions in this period')),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCurrencyNoCents(trend.current),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              _DeltaChip(delta: trend.deltaPercent),
              const SizedBox(height: 14),
              StatLineChart(
                series: [points],
                isFilled: true,
                height: 160,
                showTooltip: true,
                tooltipBuilder: (point, _) =>
                    formatCurrencyNoCents(point.y),
              ),
            ],
          );
  }
}

class _SpendingContent extends StatelessWidget {
  const _SpendingContent({required this.points, required this.granularity});

  final List<SeriesPoint> points;
  final BucketGranularity granularity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ChartPalette.of(context);
    final total = points.fold<double>(0, (s, p) => s + p.y);
    return points.isEmpty
        ? const SizedBox(
            height: 110,
            child: Center(child: Text('No spending in this period')),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCurrencyNoCents(total),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.expense,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                switch (granularity) {
                  BucketGranularity.daily => 'Expense per day',
                  BucketGranularity.weekly => 'Expense per week',
                  BucketGranularity.monthly => 'Expense per month',
                },
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              StatBarChart(
                groups: [
                  for (final p in points)
                    StatBarGroup(
                      label: p.x.day.toString(),
                      rods: [
                        StatBarRod(value: p.y, color: palette.expense),
                      ],
                    ),
                ],
                height: 160,
                showTooltip: true,
              ),
            ],
          );
  }
}

class _CashFlowContent extends StatelessWidget {
  const _CashFlowContent({required this.bars, required this.cumulative});

  final List<GroupedBar> bars;
  final bool cumulative;

  List<SeriesPoint> _series(double Function(GroupedBar) valueOf) {
    final result = <SeriesPoint>[];
    var acc = 0.0;
    for (var i = 0; i < bars.length; i++) {
      acc += valueOf(bars[i]);
      result.add(
        SeriesPoint(
          x: DateTime(2026, 1, 1).add(Duration(days: i)),
          y: cumulative ? acc : valueOf(bars[i]),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    return bars.isEmpty
        ? const SizedBox(
            height: 120,
            child: Center(child: Text('No transactions in this period')),
          )
        : StatLineChart(
            series: [
              _series((b) => b.income),
              _series((b) => b.expense),
              _series((b) => b.net),
            ],
            seriesColors: [palette.income, palette.expense, palette.net],
            height: 160,
            showTooltip: true,
            tooltipBuilder: (point, index) => switch (index) {
              0 => 'In ${formatCurrencyNoCents(point.y)}',
              1 => 'Out ${formatCurrencyNoCents(point.y)}',
              _ => 'Net ${formatCurrencyNoCents(point.y)}',
            },
          );
  }
}

class _IncomeVsExpenseContent extends StatelessWidget {
  const _IncomeVsExpenseContent({required this.bars});

  final List<GroupedBar> bars;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    return bars.isEmpty
        ? const SizedBox(
            height: 120,
            child: Center(child: Text('No transactions in this period')),
          )
        : StatBarChart(
            groups: [
              for (final b in bars)
                StatBarGroup(
                  label: b.label,
                  rods: [
                    StatBarRod(value: b.income, color: palette.income, label: 'In'),
                    StatBarRod(value: b.expense, color: palette.expense, label: 'Out'),
                  ],
                ),
            ],
            height: 160,
            showTooltip: true,
          );
  }
}

class _SavingsContent extends StatelessWidget {
  const _SavingsContent({required this.series, required this.goalTarget});

  final List<TrendSeries> series;
  final double? goalTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = series.isEmpty ? <SeriesPoint>[] : series.first.points;
    final current = series.isEmpty ? 0.0 : series.first.current;

    final values = <double>[...points.map((p) => p.y)];
    final dataMax = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = dataMax == 0 ? 1.0 : dataMax * 1.2;
    final goalLine = goalTarget != null && goalTarget! <= maxY
        ? [
            SeriesPoint(x: points.first.x, y: goalTarget!),
            SeriesPoint(x: points.last.x, y: goalTarget!),
          ]
        : null;

    return points.isEmpty
        ? const SizedBox(
            height: 110,
            child: Center(child: Text('No savings in this period')),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCurrencyNoCents(current),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                goalTarget != null
                    ? '${(current / goalTarget! * 100).clamp(0, 999).toStringAsFixed(0)}% of goal'
                    : 'Saved this period',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              StatLineChart(
                series: [
                  points,
                  ?goalLine,
                ].whereType<List<SeriesPoint>>().toList(),
                seriesColors: const [
                  Color(0xFF22C55E),
                  Color(0xFF94A3B8),
                ],
                isFilled: true,
                showTooltip: true,
                tooltipBuilder: (point, _) =>
                    formatCurrencyNoCents(point.y),
                maxY: maxY,
                height: 160,
              ),
            ],
          );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.points});

  final List<SeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    return points.isEmpty
        ? const SizedBox(
            height: 120,
            child: Center(child: Text('No balance history')),
          )
        : StatLineChart(
            series: [points],
            isFilled: true,
            height: 160,
            showTooltip: true,
            tooltipBuilder: (point, _) => formatCurrencyNoCents(point.y),
          );
  }
}

/// A small "▲ x% vs previous" chip used by the balance view.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = delta > 0;
    final color = isUp
        ? const Color(0xFF16A34A)
        : delta < 0
        ? const Color(0xFFDC2626)
        : theme.colorScheme.onSurfaceVariant;
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : delta < 0
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}% '
          '${delta > 0 ? 'up from previous' : delta < 0 ? 'down from previous' : 'same as previous'}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
