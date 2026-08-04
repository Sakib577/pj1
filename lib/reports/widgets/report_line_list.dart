import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../models/report_models.dart';

/// Renders a list of [ReportLineItem]s with a consistent layout: dotted leader
/// between label and amount, inline totals, and optional activity icons.
class ReportLineList extends StatelessWidget {
  const ReportLineList({
    super.key,
    required this.items,
    this.emptyMessage = 'No activity',
  });

  final List<ReportLineItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _LineRow(item: items[i]),
        ],
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.item});

  final ReportLineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor =
        item.color ?? (item.amount < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A));
    return Padding(
      padding: EdgeInsets.only(
        left: 8.0 + (item.indent * 16),
        top: 10,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: item.isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _signAmount(item.amount),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: item.isTotal ? FontWeight.w800 : FontWeight.w700,
              color: item.isTotal ? theme.colorScheme.onSurface : amountColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _signAmount(double value) {
    final formatted = formatCurrency(value.abs());
    if (value < 0 || value == 0) return '-$formatted';
    return '+$formatted';
  }
}