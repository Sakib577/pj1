import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/chart_theme.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'range_segmented_control.dart';
import 'stat_card.dart';

enum _CashFlowMode { trend, cumulative }

/// Card 3: Cash Flow Trend — income/expense/net over the range with a
/// Trend | Cumulative switch. The per-bucket income/expense values come from a
/// list of [GroupedBar] (already bucketed by the caller).
class CashFlowTrendCard extends StatefulWidget {
  const CashFlowTrendCard({
    super.key,
    required this.bars,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<GroupedBar> bars;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  State<CashFlowTrendCard> createState() => _CashFlowTrendCardState();
}

class _CashFlowTrendCardState extends State<CashFlowTrendCard> {
  _CashFlowMode _mode = _CashFlowMode.trend;

  List<SeriesPoint> _toPoints(double Function(GroupedBar) valueOf) {
    // Reuse bucket order; x is a synthetic increasing index for the line.
    return [
      for (var i = 0; i < widget.bars.length; i++)
        SeriesPoint(x: DateTime(2026, 1, 1).add(Duration(days: i)), y: valueOf(widget.bars[i])),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);

    final income = _mode == _CashFlowMode.trend
        ? _toPoints((b) => b.income)
        : _cumulative((b) => b.income);
    final expense = _mode == _CashFlowMode.trend
        ? _toPoints((b) => b.expense)
        : _cumulative((b) => b.expense);

    return StatCard(
      title: 'Cash Flow Trend',
      icon: Icons.show_chart_rounded,
      subtitle: widget.rangeLabel,
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StatSegmentedControl<_CashFlowMode>(
          value: _mode,
          options: const [
            (_CashFlowMode.trend, 'Trend'),
            (_CashFlowMode.cumulative, 'Cumulative'),
          ],
          onChanged: (mode) => setState(() => _mode = mode),
        ),
      ),
      child: widget.bars.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No transactions in this period')),
            )
          : StatLineChart(
              series: [income, expense],
              seriesColors: [palette.income, palette.expense],
              height: 160,
              showTooltip: true,
              tooltipBuilder: (point, _) => formatCurrencyNoCents(point.y),
            ),
    );
  }

  List<SeriesPoint> _cumulative(double Function(GroupedBar) valueOf) {
    final result = <SeriesPoint>[];
    var acc = 0.0;
    for (var i = 0; i < widget.bars.length; i++) {
      acc += valueOf(widget.bars[i]);
      result.add(
        SeriesPoint(
          x: DateTime(2026, 1, 1).add(Duration(days: i)),
          y: acc,
        ),
      );
    }
    return result;
  }
}