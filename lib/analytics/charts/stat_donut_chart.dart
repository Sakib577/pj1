import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import 'chart_theme.dart';

/// One slice of the donut.
class StatDonutSlice {
  const StatDonutSlice({
    required this.label,
    required this.amount,
    required this.color,
    this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData? icon;
}

/// A donut/pie chart wrapper with a center label that updates on slice tap.
class StatDonutChart extends StatefulWidget {
  const StatDonutChart({
    super.key,
    required this.slices,
    this.height = 180,
    this.radius,
    this.animate = true,
    this.centerLabel,
    this.centerSubtitle,
    this.onSliceTap,
    this.legendBuilder,
    this.legendLimit,
    this.legendFooter,
  });

  final List<StatDonutSlice> slices;
  final double height;
  final double? radius;
  final bool animate;
  final String? centerLabel;
  final String? centerSubtitle;
  final void Function(StatDonutSlice slice)? onSliceTap;
  final Widget Function(StatDonutSlice slice)? legendBuilder;
  final int? legendLimit;
  final Widget? legendFooter;

  @override
  State<StatDonutChart> createState() => _StatDonutChartState();
}

class _StatDonutChartState extends State<StatDonutChart> {
  StatDonutSlice? _selected;

  @override
  Widget build(BuildContext context) {
    final palette = ChartPalette.of(context);
    final theme = Theme.of(context);
    final total = widget.slices.fold<double>(0, (s, x) => s + x.amount);

    final sections = [
      for (var i = 0; i < widget.slices.length; i++)
        PieChartSectionData(
          value: widget.slices[i].amount == 0 ? 0.01 : widget.slices[i].amount,
          color: widget.slices[i].color,
          radius: _selected?.label == widget.slices[i].label ? 26 : 20,
          showTitle: false,
        ),
    ];

    final selected = _selected;
    final centerLabel = selected == null
        ? (widget.centerLabel ?? 'Total')
        : selected.label;
    final centerValue = selected == null
        ? (widget.centerSubtitle ?? formatCurrencyNoCents(total))
        : formatCurrencyNoCents(selected.amount);

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: widget.radius ?? 52,
              sections: sections,
              startDegreeOffset: -90,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event is FlTapUpEvent) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }

                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    return;
                  }
                  final idx = response.touchedSection!.touchedSectionIndex;
                  if (idx < 0 || idx >= widget.slices.length) {
                    return;
                  }
                  setState(() {
                    _selected = widget.slices[idx];
                  });
                  widget.onSliceTap?.call(widget.slices[idx]);
                },
              ),
            ),
            duration: widget.animate
                ? const Duration(milliseconds: 400)
                : Duration.zero,
            curve: Curves.easeOutCubic,
          ),
        ),
        // Center overlay label
        Align(
          alignment: Alignment.center,
          heightFactor: 0,
          child: Transform.translate(
            offset: Offset(0, -(widget.height / 2)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    centerLabel,
                    key: ValueKey(centerLabel),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.axisLabel,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    centerValue,
                    key: ValueKey(centerValue),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.legendBuilder != null) ...[
          const SizedBox(height: 12),
          for (var i = 0;
              i < widget.slices.length &&
                  (widget.legendLimit == null || i < widget.legendLimit!);
              i++)
            widget.legendBuilder!(widget.slices[i]),
          if (widget.legendFooter != null) widget.legendFooter!,
        ],
      ],
    );
  }
}