import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import 'chart_theme.dart';

/// One rod within a group.
class StatBarRod {
  const StatBarRod({required this.value, required this.color, this.label});

  final double value;
  final Color color;
  final String? label;
}

/// One group (x-axis category) containing one or more rods.
class StatBarGroup {
  const StatBarGroup({required this.label, required this.rods, this.x});

  final String label;

  /// Manually set the horizontal position. When omitted bars are laid out in
  /// order (0,1,2,…).
  final double? x;
  final List<StatBarRod> rods;
}

/// A grouped/negative bar chart wrapper built on fl_chart.
class StatBarChart extends StatelessWidget {
  const StatBarChart({
    super.key,
    required this.groups,
    this.height = 180,
    this.animate = true,
    this.showTooltip = true,
    this.minY,
    this.maxY,
  });

  final List<StatBarGroup> groups;
  final double height;
  final bool animate;
  final bool showTooltip;
  final double? minY;
  final double? maxY;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final theme = Theme.of(context);

    final barGroups = [
      for (var i = 0; i < groups.length; i++)
        BarChartGroupData(
          x: (groups[i].x ?? i.toDouble()).toInt(),
          barsSpace: 4,
          barRods: [
            for (final rod in groups[i].rods)
              BarChartRodData(
                toY: rod.value,
                color: rod.color,
                width: 12,
                borderRadius: BorderRadius.circular(3),
              ),
          ],
        ),
    ];

    var maxValue = 0.0;
    var minValue = 0.0;
    for (final g in groups) {
      for (final r in g.rods) {
        if (r.value > maxValue) maxValue = r.value;
        if (r.value < minValue) minValue = r.value;
      }
    }
    if (maxValue == 0 && minValue == 0) maxValue = 1;

    final show3BarsAlmostEmpty = groups.where(
      (g) => g.rods.length > 1,
    ).isNotEmpty;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY ?? maxValue * 1.2,
          minY: minY ?? (minValue < 0 ? minValue * 1.2 : 0),
          alignment: BarChartAlignment.spaceEvenly,
          barTouchData: showTooltip
              ? BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => palette.tooltipBg,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final text = _rodLabel(group, rod, rodIndex);
                      return BarTooltipItem(
                        text,
                        TextStyle(
                          color: palette.tooltipText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                )
              : BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  final text = formatCurrencyNoCents(value);
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.axisLabel,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: show3BarsAlmostEmpty ? 30 : 24,
                getTitlesWidget: (value, meta) {
                  final idx = _indexForX(value.toInt(), groups);
                  if (idx == -1) {
                    return const SizedBox();
                  }
                  if (!_shouldShowLabel(idx, groups.length)) {
                    return const SizedBox();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: RotatedBox(
                        quarterTurns: show3BarsAlmostEmpty ? 1 : 0,
                        child: Text(
                          groups[idx].label,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.axisLabel,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.grid,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
        duration: animate
            ? const Duration(milliseconds: 400)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  int _indexForX(int x, List<StatBarGroup> groups) {
    for (var i = 0; i < groups.length; i++) {
      final gx = (groups[i].x ?? i.toDouble()).toInt();
      if (gx == x) return i;
    }
    return -1;
  }

  /// Only draw a readable subset of x labels when there are many groups, so
  /// daily charts don't cram 30+ dates together. Always shows the first and
  /// last label.
  bool _shouldShowLabel(int idx, int total) {
    if (total <= 8) return true;
    const target = 6;
    final step = (total / target).ceil();
    if (step <= 1) return true;
    if (idx == 0 || idx == total - 1) return true;
    return idx % step == 0;
  }

  String _rodLabel(BarChartGroupData group, BarChartRodData rod, int rodIndex) {
    final idx = _indexForX(group.x, groups);
    if (idx == -1) return formatCurrencyNoCents(rod.toY);
    final rods = groups[idx].rods;
    final label = rodIndex < rods.length && rods[rodIndex].label != null
        ? rods[rodIndex].label!
        : null;
    return label == null
        ? formatCurrencyNoCents(rod.toY)
        : '$label\n${formatCurrencyNoCents(rod.toY)}';
  }
}