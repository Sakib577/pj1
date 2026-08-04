import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_line_chart.dart';
import '../models/stat_models.dart';
import 'range_segmented_control.dart';
import 'stat_card.dart';

enum BalanceHistoryRange {
  week('1W'),
  month('1M'),
  threeMonths('3M'),
  sixMonths('6M'),
  year('1Y');

  const BalanceHistoryRange(this.label);
  final String label;
}

/// Card 20: Balance History — daily balance lines with 1W/1M/3M/6M/1Y control.
class BalanceHistoryCard extends StatefulWidget {
  const BalanceHistoryCard({
    super.key,
    required this.seriesByRange,
    this.onRangeTap,
    this.rangeLabel,
  });

  final Map<BalanceHistoryRange, List<SeriesPoint>> seriesByRange;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  State<BalanceHistoryCard> createState() => _BalanceHistoryCardState();
}

class _BalanceHistoryCardState extends State<BalanceHistoryCard> {
  BalanceHistoryRange _range = BalanceHistoryRange.month;

  @override
  Widget build(BuildContext context) {
    final points = widget.seriesByRange[_range] ?? const <SeriesPoint>[];

    return StatCard(
      title: 'Balance History',
      icon: Icons.show_chart_rounded,
      subtitle: widget.rangeLabel,
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StatSegmentedControl<BalanceHistoryRange>(
          value: _range,
          options: BalanceHistoryRange.values
              .map((r) => (r, r.label))
              .toList(),
          onChanged: (r) => setState(() => _range = r),
        ),
      ),
      child: points.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No balance history')),
            )
          : StatLineChart(
              series: [points],
              isFilled: true,
              showTooltip: true,
              tooltipBuilder: (point, _) => formatCurrencyNoCents(point.y),
              height: 160,
            ),
    );
  }
}