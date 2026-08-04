import 'package:flutter/material.dart';

/// Resolves a consistent set of chart colors from the ambient [ThemeMode].
///
/// Every analytics chart reads its colors from this palette (passed in via the
/// widget's constructor) so the whole module adapts to light/dark automatically
/// without hardcoding colors inside individual charts.
class ChartPalette {
  const ChartPalette({
    required this.income,
    required this.expense,
    required this.net,
    required this.primary,
    required this.grid,
    required this.axisLabel,
    required this.tooltipBg,
    required this.tooltipText,
    required this.highlight,
    required this.surface,
  });

  final Color income;
  final Color expense;
  final Color net;
  final Color primary;
  final Color grid;
  final Color axisLabel;
  final Color tooltipBg;
  final Color tooltipText;
  final Color highlight;
  final Color surface;

  /// Builds a palette for the current brightness.
  factory ChartPalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const ChartPalette(
        income: Color(0xFF22C55E),
        expense: Color(0xFFF97316),
        net: Color(0xFFF59E0B),
        primary: Color(0xFFFBBF24),
        grid: Color(0xFF334155),
        axisLabel: Color(0xFF94A3B8),
        tooltipBg: Color(0xFF1E293B),
        tooltipText: Color(0xFFF1F5F9),
        highlight: Color(0xFFFBBF24),
        surface: Color(0xFF1E293B),
      );
    }
    return const ChartPalette(
      income: Color(0xFF22C55E),
      expense: Color(0xFFF97316),
      net: Color(0xFFF59E0B),
      primary: Color(0xFFF59E0B),
      grid: Color(0xFFE2E8F0),
      axisLabel: Color(0xFF94A3B8),
      tooltipBg: Color(0xFF0F172A),
      tooltipText: Color(0xFFF8FAFC),
      highlight: Color(0xFFF59E0B),
      surface: Color(0xFFFFFFFF),
    );
  }
}