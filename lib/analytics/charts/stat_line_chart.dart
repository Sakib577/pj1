import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/stat_models.dart';
import '../../utils/currency_formatters.dart';
import 'chart_theme.dart';

/// A line (optionally filled area) chart wrapper built on fl_chart.
///
/// Points are plotted on an X axis derived from the underlying [DateTime]s so
/// the wrapper stays behind the fl_chart abstraction. Colors come from the
/// ambient [ChartPalette] so the widget adapts to light/dark automatically.
class StatLineChart extends StatelessWidget {
  const StatLineChart({
    super.key,
    required this.series,
    this.seriesColors,
    this.barWidths,
    this.isFilled = false,
    this.showTooltip = true,
    this.tooltipBuilder,
    this.height = 180,
    this.animate = true,
    this.minY,
    this.maxY,
    this.xLabelBuilder,
    this.showXLabels = true,
    this.showYLabels = true,
  });

  /// Ordered (x asc) points. If multiple disjoint series are required pass
  /// them as separate [series] entries.
  final List<List<SeriesPoint>> series;
  final List<Color>? seriesColors;

  /// Optional per-series stroke width; falls back to the default when absent.
  final List<double>? barWidths;
  final bool isFilled;
  final bool showTooltip;
  final String Function(SeriesPoint point, int seriesIndex)? tooltipBuilder;
  final double height;
  final bool animate;
  final double? minY;
  final double? maxY;
  final String Function(DateTime x)? xLabelBuilder;
  final bool showXLabels;
  final bool showYLabels;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final theme = Theme.of(context);
    final colors = seriesColors ??
        (series.length == 1
            ? [palette.primary]
            : [palette.income, palette.expense]);

    final allXs = [
      for (final s in series)
        for (final p in s) p.x.millisecondsSinceEpoch,
    ];
    if (allXs.isEmpty) return const SizedBox(height: 100);

    final minX = allXs.reduce((a, b) => a < b ? a : b);
    final maxX = allXs.reduce((a, b) => a > b ? a : b);
    final xSpan = (maxX - minX).toDouble();

    List<FlSpot> toSpots(List<SeriesPoint> points) => [
      for (final p in points)
        FlSpot(
          xSpan == 0
              ? 0
              : ((p.x.millisecondsSinceEpoch - minX) / xSpan) *
                    (series.length > 6 ? 6 : 1),
          p.y,
        ),
    ];

    final lineBars = [
      for (var i = 0; i < series.length; i++)
        LineChartBarData(
          spots: toSpots(series[i]),
          color: colors[i % colors.length],
          barWidth: barWidths != null && i < barWidths!.length
              ? barWidths![i]
              : 2.5,
          isCurved: true,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: isFilled
              ? BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      colors[i % colors.length].withValues(alpha: 0.35),
                      colors[i % colors.length].withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                )
              : BarAreaData(show: false, color: Colors.transparent),
        ),
    ];

    final allY = [
      for (final s in series)
        for (final p in s) p.y,
    ];
    final allPositive = allY.isNotEmpty && allY.every((v) => v >= 0);
    final computedMinY = minY ??
        (allY.isEmpty ? 0 : allY.reduce((a, b) => a < b ? a : b));
    final computedMaxY = maxY ??
        (allY.isEmpty ? 1 : allY.reduce((a, b) => a > b ? a : b));
    final yRange = ((computedMaxY - computedMinY == 0)
        ? 1
        : (computedMaxY - computedMinY)) *
        0.3;

    // Keep the axis proportional to the actual data: all-positive series start
    // at 0 so low-spend periods aren't drowned out by a huge negative domain.
    final explicitMin = minY;
    final effectiveMinY = explicitMin ?? (allPositive ? 0.0 : computedMinY - yRange);
    final effectiveMaxY = computedMaxY + yRange;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: effectiveMinY,
          maxY: effectiveMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: palette.grid,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: showYLabels
                ? AxisTitles(
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
                  )
                : const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
            bottomTitles: showXLabels
                ? AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        if (series.isEmpty) {
                          return const SizedBox();
                        }
                        final ts = xSpan == 0
                            ? minX.toDouble()
                            : minX + (value / (series.length > 6 ? 6 : 1)) * xSpan;
                        final date = DateTime.fromMillisecondsSinceEpoch(ts.round());
                        final label = xLabelBuilder?.call(date) ??
                            '${date.day}/${date.month}';
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: palette.axisLabel,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                      interval: xSpan == 0 ? 1 : null,
                    ),
                  )
                : const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: showTooltip
              ? LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipColor: (_) => palette.tooltipBg,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final ts = xSpan == 0
                            ? minX.toDouble()
                            : minX +
                                  (spot.x / (series.length > 6 ? 6 : 1)) *
                                      xSpan;
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          ts.round(),
                        );
                        final point = SeriesPoint(x: date, y: spot.y);
                        final text = tooltipBuilder?.call(point, spot.barIndex) ??
                            formatCurrencyNoCents(spot.y);
                        return LineTooltipItem(
                          text,
                          TextStyle(
                            color: palette.tooltipText,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) => spotIndexes.map((i) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: palette.highlight,
                        strokeWidth: 2,
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, barData1, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: palette.highlight,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                )
              : LineTouchData(enabled: false),
          lineBarsData: lineBars,
        ),
        duration: animate
            ? const Duration(milliseconds: 400)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// Convenience builder producing a populated tooltip from a plain value.
  static String? Function(SeriesPoint point, int seriesIndex)
      currencyTooltip({String? suffix}) {
    return (point, _) => formatCurrencyNoCents(point.y) + (suffix ?? '');
  }
}