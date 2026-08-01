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
      'iconName': iconNameFor(icon),
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
      icon: iconFromName(data['iconName'] as String?),
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
}

// Maps the known built-in icons to a stable string so they can be stored in
// Firestore and rebuilt without violating IconData's @mustBeConst codePoint.
String? iconNameFor(IconData? icon) {
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
    case Icons.arrow_downward:
      return 'arrow_downward';
    case Icons.arrow_upward:
      return 'arrow_upward';
    default:
      return null;
  }
}

IconData? iconFromName(String? name) {
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
    case 'arrow_downward':
      return Icons.arrow_downward;
    case 'arrow_upward':
      return Icons.arrow_upward;
    default:
      return null;
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
    this.createdAt,
  });

  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String categoryName;
  final String? note;
  final bool negative;
  final DateTime? createdAt;

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
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'iconName': iconNameFor(icon),
      'iconColor': iconColor.toARGB32(),
      'categoryName': categoryName,
      'note': note,
      'negative': negative,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> data) {
    return TransactionItem(
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      icon: iconFromName(data['iconName'] as String?) ??
          Icons.category_rounded,
      iconColor: Color(
        (data['iconColor'] as num?)?.toInt() ?? 0xFFF97316,
      ),
      categoryName: (data['categoryName'] as String?) ?? '',
      note: data['note'] as String?,
      negative: (data['negative'] as bool?) ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

// How often a planned payment repeats.
enum RepeatFrequency { once, daily, weekly, monthly, custom }

extension RepeatFrequencyLabel on RepeatFrequency {
  String get label => switch (this) {
    RepeatFrequency.once => 'One time',
    RepeatFrequency.daily => 'Daily',
    RepeatFrequency.weekly => 'Weekly',
    RepeatFrequency.monthly => 'Monthly',
    RepeatFrequency.custom => 'Custom',
  };
}

// Whether a debt is money you owe or money owed to you.
enum DebtType { borrowed, lent }

extension DebtTypeLabel on DebtType {
  String get label => switch (this) {
    DebtType.borrowed => 'Borrowed',
    DebtType.lent => 'Lent',
  };
}

// Lifecycle of a debt record. Repaid moves money back into/out of the balance;
// closed (or forgiven for lent debts) settles the record without moving money.
enum DebtSettlement { active, closed, repaid }

// One debt (borrowed or lent) with a settlement state.
class DebtItem {
  const DebtItem({
    required this.id,
    required this.person,
    required this.amount,
    this.type = DebtType.borrowed,
    this.settlement = DebtSettlement.active,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String person;
  final double amount;
  final DebtType type;
  final DebtSettlement settlement;
  final String? note;
  final DateTime createdAt;

  bool get isClosed => settlement != DebtSettlement.active;
  bool get isRepaid => settlement == DebtSettlement.repaid;

  DebtItem copyWith({DebtSettlement? settlement}) => DebtItem(
    id: id,
    person: person,
    amount: amount,
    type: type,
    settlement: settlement ?? this.settlement,
    note: note,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() {
    return {
      'person': person,
      'amount': amount,
      'type': type.name,
      'settlement': settlement.name,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory DebtItem.fromMap(String id, Map<String, dynamic> data) {
    return DebtItem(
      id: id,
      person: (data['person'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      type: DebtType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => DebtType.borrowed,
      ),
      settlement: DebtSettlement.values.firstWhere(
        (settlement) => settlement.name == data['settlement'],
        orElse: () => DebtSettlement.active,
      ),
      note: data['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

// One item on the shopping list. When completed it records a price and becomes
// an expense transaction.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.subcategory,
    this.isDone = false,
    this.price,
    this.completedAt,
  });

  final String id;
  final String name;
  final String? subcategory;
  final bool isDone;
  final double? price;
  final DateTime? completedAt;

  ShoppingItem copyWith({
    bool? isDone,
    double? price,
    DateTime? completedAt,
  }) => ShoppingItem(
    id: id,
    name: name,
    subcategory: subcategory,
    isDone: isDone ?? this.isDone,
    price: price ?? this.price,
    completedAt: completedAt ?? this.completedAt,
  );
}

// Upcoming scheduled payment card.
class PlannedPayment {
  const PlannedPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.categoryName,
    this.emoji,
    this.subcategory,
    this.isIncome = false,
    this.repeat = RepeatFrequency.once,
    this.customEveryDays = 7,
    required this.startDate,
    this.createdAt,
    this.lastConfirmedDate,
  });

  final String id;
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String categoryName;
  final String? emoji;
  final String? subcategory;
  final bool isIncome;
  final RepeatFrequency repeat;
  final int customEveryDays;
  final DateTime startDate;
  final DateTime? createdAt;

  // The last occurrence that was confirmed as paid. The next due date is always
  // computed strictly after this, so a payment is never prompted twice for the
  // same occurrence.
  final DateTime? lastConfirmedDate;

  PlannedPayment copyWith({
    DateTime? createdAt,
    DateTime? lastConfirmedDate,
  }) => PlannedPayment(
    id: id,
    title: title,
    amount: amount,
    icon: icon,
    iconColor: iconColor,
    categoryName: categoryName,
    emoji: emoji,
    subcategory: subcategory,
    isIncome: isIncome,
    repeat: repeat,
    customEveryDays: customEveryDays,
    startDate: startDate,
    createdAt: createdAt ?? this.createdAt,
    lastConfirmedDate: lastConfirmedDate ?? this.lastConfirmedDate,
  );

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'iconName': iconNameFor(icon),
      'iconColor': iconColor.toARGB32(),
      'categoryName': categoryName,
      'emoji': emoji,
      'subcategory': subcategory,
      'isIncome': isIncome,
      'repeat': repeat.name,
      'customEveryDays': customEveryDays,
      'startDate': startDate.millisecondsSinceEpoch,
      'createdAt': (createdAt ?? startDate).millisecondsSinceEpoch,
      'lastConfirmedDate': lastConfirmedDate?.millisecondsSinceEpoch,
    };
  }

  factory PlannedPayment.fromMap(String id, Map<String, dynamic> data) {
    return PlannedPayment(
      id: id,
      title: (data['title'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      icon: iconFromName(data['iconName'] as String?) ??
          Icons.category_rounded,
      iconColor: Color(
        (data['iconColor'] as num?)?.toInt() ?? 0xFFF97316,
      ),
      categoryName: (data['categoryName'] as String?) ?? '',
      emoji: data['emoji'] as String?,
      subcategory: data['subcategory'] as String?,
      isIncome: (data['isIncome'] as bool?) ?? false,
      repeat: RepeatFrequency.values.firstWhere(
        (repeat) => repeat.name == data['repeat'],
        orElse: () => RepeatFrequency.once,
      ),
      customEveryDays: (data['customEveryDays'] as num?)?.toInt() ?? 7,
      startDate: DateTime.fromMillisecondsSinceEpoch(
        (data['startDate'] as num?)?.toInt() ?? 0,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
      ),
      lastConfirmedDate: data['lastConfirmedDate'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['lastConfirmedDate'] as num).toInt(),
            )
          : null,
    );
  }

  // Next occurrence on or after [from] (today by default), always after the
  // last confirmed date so already-handled occurrences are skipped.
  DateTime nextDue({DateTime? from}) {
    final target = _dateOnly(from ?? DateTime.now());
    final lastConfirmed = lastConfirmedDate;
    var date = _dateOnly(startDate);
    if (lastConfirmed != null) {
      final confirmed = _dateOnly(lastConfirmed);
      if (confirmed.isAfter(date)) {
        date = _advance(confirmed);
      }
      if (date.isAtSameMomentAs(confirmed)) {
        date = _advance(date);
      }
    }
    if (repeat == RepeatFrequency.once) return date;
    while (date.isBefore(target)) {
      date = _advance(date);
    }
    return date;
  }

  // True when the current occurrence is due today (or is an overdue one-time
  // payment) and has not been confirmed yet.
  bool get needsConfirmation {
    final today = _dateOnly(DateTime.now());
    final due = nextDue();
    if (due.isAfter(today)) return false;
    final lastConfirmed = lastConfirmedDate;
    if (lastConfirmed != null) {
      final confirmed = _dateOnly(lastConfirmed);
      if (!confirmed.isBefore(due)) return false;
    }
    return true;
  }

  bool get isOverdue {
    final due = nextDue();
    return _dateOnly(DateTime.now()).isAfter(due);
  }

  DateTime _advance(DateTime date) {
    switch (repeat) {
      case RepeatFrequency.daily:
        return date.add(const Duration(days: 1));
      case RepeatFrequency.weekly:
        return date.add(const Duration(days: 7));
      case RepeatFrequency.monthly:
        final month = date.month + 1;
        return DateTime(
          date.year + (month > 12 ? 1 : 0),
          month > 12 ? 1 : month,
          date.day,
        );
      case RepeatFrequency.custom:
        return date.add(Duration(days: customEveryDays));
      case RepeatFrequency.once:
        return date;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
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
