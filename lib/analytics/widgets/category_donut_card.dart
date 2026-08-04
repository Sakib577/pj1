import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../charts/stat_donut_chart.dart';
import '../models/stat_models.dart';
import 'stat_card.dart';

/// Card 4: Spending by Categories — donut with tappable legend.
/// Shows the full donut (always accounting for every category spent) while the
/// legend previews the top 3 categories with a "Show more" toggle.
class CategoryDonutCard extends StatefulWidget {
  const CategoryDonutCard({
    super.key,
    required this.categories,
    this.onRangeTap,
    this.rangeLabel,
  });

  final List<CategoryStat> categories;
  final VoidCallback? onRangeTap;
  final String? rangeLabel;

  @override
  State<CategoryDonutCard> createState() => _CategoryDonutCardState();
}

class _CategoryDonutCardState extends State<CategoryDonutCard> {
  static const int _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final total = categories.fold<double>(0, (s, c) => s + c.amount);

    final slices = [
      for (final c in categories)
        StatDonutSlice(
          label: c.name,
          amount: c.amount,
          color: c.color,
          icon: c.icon,
        ),
    ];

    return StatCard(
      title: 'Spending by Categories',
      icon: Icons.pie_chart_rounded,
      subtitle: widget.rangeLabel,
      trailing: widget.onRangeTap != null
          ? IconButton(
              onPressed: widget.onRangeTap,
              tooltip: 'Change range',
              icon: const Icon(Icons.calendar_month_outlined, size: 18),
            )
          : null,
      child: categories.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(child: Text('No spending in this period')),
            )
          : StatDonutChart(
              slices: slices,
              height: 160,
              radius: 46,
              centerLabel: 'Total',
              centerSubtitle: formatCurrencyNoCents(total),
              legendLimit: _expanded ? null : _previewCount,
              legendFooter: categories.length > _previewCount
                  ? TextButton.icon(
                      onPressed: () => setState(() {
                        _expanded = !_expanded;
                      }),
                      icon: Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _expanded
                            ? 'Show less'
                            : 'Show more (${categories.length - _previewCount})',
                      ),
                    )
                  : null,
              legendBuilder: (slice) => _LegendRow(
                icon: slice.icon,
                label: slice.label,
                amount: slice.amount,
                percent: total == 0 ? 0 : (slice.amount / total) * 100,
                color: slice.color,
              ),
            ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });

  final IconData? icon;
  final String label;
  final double amount;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: icon != null
                ? Icon(icon, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatCurrencyNoCents(amount),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              '${percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
