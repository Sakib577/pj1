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

class ExpenseCategory {
  ExpenseCategory({
    required this.id,
    required this.name,
    required List<String> subcategories,
    this.emoji,
    this.icon,
    this.isUserDefined = false,
    Set<String>? userDefinedSubcategories,
    this.sortOrder = 0,
  }) : subcategories = List<String>.from(subcategories),
       userDefinedSubcategories = Set<String>.from(
         userDefinedSubcategories ?? const {},
       );

  final String id;
  final String name;
  final String? emoji;
  final IconData? icon;
  final bool isUserDefined;
  final List<String> subcategories;
  final Set<String> userDefinedSubcategories;
  final int sortOrder;

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    IconData? icon,
    bool? isUserDefined,
    List<String>? subcategories,
    Set<String>? userDefinedSubcategories,
    int? sortOrder,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      icon: icon ?? this.icon,
      isUserDefined: isUserDefined ?? this.isUserDefined,
      subcategories: subcategories ?? this.subcategories,
      userDefinedSubcategories:
          userDefinedSubcategories ?? this.userDefinedSubcategories,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'emoji': emoji,
      'iconName': _iconName(icon),
      'isUserDefined': isUserDefined,
      'subcategories': subcategories,
      'userDefinedSubcategories': userDefinedSubcategories.toList(),
      'sortOrder': sortOrder,
    };
  }

  factory ExpenseCategory.fromMap(String id, Map<String, dynamic> data) {
    return ExpenseCategory(
      id: id,
      name: (data['name'] as String?) ?? 'Unnamed',
      emoji: data['emoji'] as String?,
      icon: _iconFromName(data['iconName'] as String?),
      isUserDefined: (data['isUserDefined'] as bool?) ?? false,
      subcategories: List<String>.from(
        data['subcategories'] as List? ?? const [],
      ),
      userDefinedSubcategories: Set<String>.from(
        data['userDefinedSubcategories'] as List? ?? const [],
      ),
      sortOrder: (data['sortOrder'] as int?) ?? 0,
    );
  }

  static String? _iconName(IconData? icon) {
    if (icon == null) return null;
    switch (icon) {
      case Icons.restaurant_rounded:
        return 'restaurant_rounded';
      case Icons.shopping_bag_rounded:
        return 'shopping_bag_rounded';
      case Icons.home_rounded:
        return 'home_rounded';
      case Icons.directions_bus_rounded:
        return 'directions_bus_rounded';
      case Icons.directions_car_rounded:
        return 'directions_car_rounded';
      case Icons.self_improvement_rounded:
        return 'self_improvement_rounded';
      case Icons.movie_rounded:
        return 'movie_rounded';
      case Icons.forum_rounded:
        return 'forum_rounded';
      case Icons.devices_rounded:
        return 'devices_rounded';
      case Icons.trending_up_rounded:
        return 'trending_up_rounded';
      case Icons.account_balance_rounded:
        return 'account_balance_rounded';
      case Icons.category_rounded:
        return 'category_rounded';
      case Icons.help_outline_rounded:
        return 'help_outline_rounded';
      case Icons.payments_rounded:
        return 'payments_rounded';
      case Icons.assignment_turned_in_rounded:
        return 'assignment_turned_in_rounded';
      case Icons.savings_rounded:
        return 'savings_rounded';
      case Icons.handshake_rounded:
        return 'handshake_rounded';
      case Icons.home_work_rounded:
        return 'home_work_rounded';
      case Icons.sell_rounded:
        return 'sell_rounded';
      case Icons.card_giftcard_rounded:
        return 'card_giftcard_rounded';
      case Icons.replay_rounded:
        return 'replay_rounded';
      case Icons.work_outline_rounded:
        return 'work_outline_rounded';
      case Icons.add_circle_outline_rounded:
        return 'add_circle_outline_rounded';
      default:
        return null;
    }
  }

  static IconData? _iconFromName(String? name) {
    switch (name) {
      case 'restaurant_rounded':
        return Icons.restaurant_rounded;
      case 'shopping_bag_rounded':
        return Icons.shopping_bag_rounded;
      case 'home_rounded':
        return Icons.home_rounded;
      case 'directions_bus_rounded':
        return Icons.directions_bus_rounded;
      case 'directions_car_rounded':
        return Icons.directions_car_rounded;
      case 'self_improvement_rounded':
        return Icons.self_improvement_rounded;
      case 'movie_rounded':
        return Icons.movie_rounded;
      case 'forum_rounded':
        return Icons.forum_rounded;
      case 'devices_rounded':
        return Icons.devices_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'account_balance_rounded':
        return Icons.account_balance_rounded;
      case 'category_rounded':
        return Icons.category_rounded;
      case 'help_outline_rounded':
        return Icons.help_outline_rounded;
      case 'payments_rounded':
        return Icons.payments_rounded;
      case 'assignment_turned_in_rounded':
        return Icons.assignment_turned_in_rounded;
      case 'savings_rounded':
        return Icons.savings_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      case 'home_work_rounded':
        return Icons.home_work_rounded;
      case 'sell_rounded':
        return Icons.sell_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'replay_rounded':
        return Icons.replay_rounded;
      case 'work_outline_rounded':
        return Icons.work_outline_rounded;
      case 'add_circle_outline_rounded':
        return Icons.add_circle_outline_rounded;
      default:
        return null;
    }
  }
}

class CategorySelection {
  const CategorySelection({required this.category, this.subcategory});
  final ExpenseCategory category;
  final String? subcategory;
}

// One transaction row shown in recent activity.
class TransactionItem {
  const TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.categoryName,
    this.note,
    this.negative = true,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String categoryName;
  final String? note;
  final bool negative;

  TransactionItem copyWith({String? categoryName, String? note}) =>
      TransactionItem(
        title: title,
        subtitle: subtitle,
        amount: amount,
        icon: icon,
        iconColor: iconColor,
        categoryName: categoryName ?? this.categoryName,
        note: note ?? this.note,
        negative: negative,
      );
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
