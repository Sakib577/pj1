import 'package:flutter/material.dart';

import '../charts/chart_theme.dart';
import '../charts/stat_bar_chart.dart';
import '../models/stat_models.dart';
import '../utils/date_ranges.dart';
import 'range_segmented_control.dart';
import 'stat_card.dart';

/// Card 8: Income vs Expense — grouped income/expense/net bars with a
/// Daily/Weekly/Monthly control.
class IncomeExpenseComparisonCard extends StatefulWidget {
  const IncomeExpenseComparisonCard({
    super.key,
    required this.daily,
    required this.weekly,
    required this.monthly,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<GroupedBar> daily;
  final List<GroupedBar> weekly;
  final List<GroupedBar> monthly;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  State<IncomeExpenseComparisonCard> createState() =>
      _IncomeExpenseComparisonCardState();
}

class _IncomeExpenseComparisonCardState
    extends State<IncomeExpenseComparisonCard> {
  BucketGranularity _granularity = BucketGranularity.monthly;

  List<GroupedBar> get _bars => switch (_granularity) {
        BucketGranularity.daily => widget.daily,
        BucketGranularity.weekly => widget.weekly,
        BucketGranularity.monthly => widget.monthly,
      };

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final bars = _bars;

    final groups = [
      for (final b in bars)
        StatBarGroup(
          label: b.label,
          rods: [
            StatBarRod(value: b.income, color: palette.income, label: 'In'),
            StatBarRod(value: b.expense, color: palette.expense, label: 'Out'),
          ],
        ),
    ];

    return StatCard(
      title: 'Income vs Expense',
      icon: Icons.compare_arrows_rounded,
      subtitle: widget.rangeLabel,
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StatSegmentedControl<BucketGranularity>(
          value: _granularity,
          options: const [
            (BucketGranularity.daily, 'Daily'),
            (BucketGranularity.weekly, 'Weekly'),
            (BucketGranularity.monthly, 'Monthly'),
          ],
          onChanged: (g) => setState(() => _granularity = g),
        ),
      ),
      child: bars.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No transactions in this period')),
            )
          : StatBarChart(
              groups: groups,
              height: 160,
              showTooltip: true,
            ),
    );
  }
}