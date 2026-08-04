import 'package:flutter/material.dart';

import 'chart_theme.dart';

/// A small floating tooltip shown above a touched chart point.
class ChartTooltip extends StatelessWidget {
  const ChartTooltip({
    super.key,
    required this.title,
    required this.subtitle,
    this.palette,
  });

  final String title;
  final String? subtitle;
  final ChartPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? ChartPalette.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.tooltipBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: p.tooltipText,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: p.tooltipText.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}