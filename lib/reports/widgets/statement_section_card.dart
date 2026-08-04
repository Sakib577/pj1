import 'package:flutter/material.dart';

import '../../utils/currency_formatters.dart';
import '../models/report_models.dart';
import 'report_line_list.dart';

/// A card rendering a single [ReportSection] (e.g. "Operating Activities")
/// with separate income and expense line lists plus a subtotal row.
class StatementSectionCard extends StatelessWidget {
  const StatementSectionCard({
    super.key,
    required this.section,
  });

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    section.icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (section.incomeItems.isNotEmpty) ...[
              _SubsectionHeader(
                label: 'Cash inflows',
                color: const Color(0xFF16A34A),
              ),
              ReportLineList(
                items: section.incomeItems,
                emptyMessage: 'No inflows',
              ),
            ],
            if (section.expenseItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SubsectionHeader(
                label: 'Cash outflows',
                color: const Color(0xFFDC2626),
              ),
              ReportLineList(
                items: section.expenseItems,
                emptyMessage: 'No outflows',
              ),
            ],
            if (section.incomeItems.isEmpty && section.expenseItems.isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'No activity in this section',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.subtotalLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _signed(section.subtotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: section.subtotal < 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _signed(double value) {
    final formatted = formatCurrency(value.abs());
    if (value == 0) return formatted;
    return value < 0 ? '-$formatted' : '+$formatted';
  }
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}