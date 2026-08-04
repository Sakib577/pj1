import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';
import '../charts/stat_bar_chart.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'range_segmented_control.dart';
import 'stat_card.dart';

enum SpendingPatternMode { hourly, daily, weekly, monthly }

/// Unified Spending Pattern card. One place to inspect how money is spent at
/// four granularities: hourly (24h average), daily, weekly (Mon..Sun average)
/// and monthly.
class SpendingPatternCard extends StatefulWidget {
  const SpendingPatternCard({
    super.key,
    required this.hourly,
    required this.daily,
    required this.weekly,
    required this.monthly,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<SeriesPoint> hourly;
  final List<SeriesPoint> daily;
  final List<SeriesPoint> weekly;
  final List<SeriesPoint> monthly;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  State<SpendingPatternCard> createState() => _SpendingPatternCardState();
}

class _SpendingPatternCardState extends State<SpendingPatternCard> {
  SpendingPatternMode _mode = SpendingPatternMode.daily;

  static const _weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = ChartPalette.of(context);
    final (points, labelBuilder) = _resolve();

    return StatCard(
      title: 'Spending Pattern',
      icon: Icons.insights_rounded,
      subtitle: widget.rangeLabel,
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StatSegmentedControl<SpendingPatternMode>(
          value: _mode,
          options: const [
            (SpendingPatternMode.hourly, 'Hourly'),
            (SpendingPatternMode.daily, 'Daily'),
            (SpendingPatternMode.weekly, 'Weekly'),
            (SpendingPatternMode.monthly, 'Monthly'),
          ],
          onChanged: (m) => setState(() => _mode = m),
        ),
      ),
      child: points.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No spending in this period')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subtitle(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (_mode == SpendingPatternMode.daily ||
                    _mode == SpendingPatternMode.monthly)
                  StatBarChart(
                    groups: [
                      for (final p in points)
                        StatBarGroup(
                          label: labelBuilder(p.x),
                          rods: [
                            StatBarRod(value: p.y, color: palette.expense),
                          ],
                        ),
                    ],
                    height: 160,
                    showTooltip: true,
                  )
                else
                  StatLineChart(
                    series: [points],
                    showTooltip: true,
                    xLabelBuilder: labelBuilder,
                    tooltipBuilder: (point, _) => formatCurrencyNoCents(
                      point.y,
                    ),
                    maxY: _maxY(points),
                    height: 160,
                  ),
              ],
            ),
    );
  }

  double _maxY(List<SeriesPoint> points) {
    final max = points.map((p) => p.y).fold<double>(0, (m, v) => v > m ? v : m);
    return max * 1.2;
  }

  String _subtitle() {
    return switch (_mode) {
      SpendingPatternMode.hourly => 'Average spend by hour of day',
      SpendingPatternMode.daily => 'Expense per day',
      SpendingPatternMode.weekly => 'Average spend per weekday',
      SpendingPatternMode.monthly => 'Expense per month',
    };
  }

  (List<SeriesPoint>, String Function(DateTime)) _resolve() {
    switch (_mode) {
      case SpendingPatternMode.hourly:
        return (widget.hourly, (d) => '${d.hour}:00');
      case SpendingPatternMode.daily:
        return (widget.daily, (d) => '${d.day}');
      case SpendingPatternMode.weekly:
        return (widget.weekly, (d) => _weekdayLabels[d.weekday - 1]);
      case SpendingPatternMode.monthly:
        return (widget.monthly, (d) => _mon(d.month));
    }
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
}
