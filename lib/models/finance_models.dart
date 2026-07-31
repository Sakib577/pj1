import 'package:flutter/material.dart';

// Top balance card data shown on dashboard.
class BalanceSummary {
  const BalanceSummary({
    required this.total,
    required this.deltaPercent,
    this.isPositive = true,
  });

  final double total;
  final double deltaPercent;
  final bool isPositive;
}

// Small stat card like Income / Expenses.
class StatCardData {
  const StatCardData({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.isPositive = true,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isPositive;
}

// One category item with icon and theme color.
class CategoryItem {
  const CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

// One transaction row shown in recent activity.
class TransactionItem {
  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    this.negative = true,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final bool negative;
}

// Upcoming scheduled payment card.
class PlannedPayment {
  const PlannedPayment({
    required this.title,
    required this.due,
    required this.amount,
    required this.icon,
    required this.background,
    required this.tagText,
  });

  final String title;
  final String due;
  final double amount;
  final IconData icon;
  final Color background;
  final String tagText;
}

// Budget item for a single spending category.
class BudgetCategory {
  const BudgetCategory({
    required this.label,
    required this.spent,
    required this.limit,
    required this.daysLeft,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
  });

  final String label;
  final double spent;
  final double limit;
  final int daysLeft;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;
}

// Overall savings section summary.
class SavingsOverview {
  const SavingsOverview({
    required this.totalSavings,
    required this.progress,
    required this.message,
  });

  final double totalSavings;
  final double progress;
  final String message;
}

// One savings goal card with progress and status.
class SavingsGoal {
  const SavingsGoal({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.target,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });

  final String title;
  final String subtitle;
  final double current;
  final double target;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String status;
  final Color statusColor;
  final Color statusBg;
}

