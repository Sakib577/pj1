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
    Map<String, String>? subcategoryEmojis,
    this.sortOrder = 0,
  }) : subcategories = List<String>.from(subcategories),
       userDefinedSubcategories = Set<String>.from(
         userDefinedSubcategories ?? const {},
       ),
       subcategoryEmojis = Map<String, String>.from(
         subcategoryEmojis ?? const {},
       );

  final String id;
  final String name;
  final String? emoji;
  final IconData? icon;
  final bool isUserDefined;
  final List<String> subcategories;
  final Set<String> userDefinedSubcategories;
  final Map<String, String> subcategoryEmojis;
  final int sortOrder;

  ExpenseCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    IconData? icon,
    bool? isUserDefined,
    List<String>? subcategories,
    Set<String>? userDefinedSubcategories,
    Map<String, String>? subcategoryEmojis,
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
      subcategoryEmojis: subcategoryEmojis ?? this.subcategoryEmojis,
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
      'subcategoryEmojis': subcategoryEmojis,
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
      subcategoryEmojis: Map<String, String>.from(
        (data['subcategoryEmojis'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        ),
      ),
      sortOrder: (data['sortOrder'] as int?) ?? 0,
    );
  }
}

/// Returns the logo (emoji) to show for a subcategory: the user-set emoji when
/// present, otherwise a sensible default. Different subcategories map to
/// different emojis.
String subcategoryEmoji(ExpenseCategory category, String subcategory) {
  final stored = category.subcategoryEmojis[subcategory];
  if (stored != null && stored.trim().isNotEmpty) return stored;
  return defaultSubcategoryEmoji(subcategory);
}

/// Returns the Material icon to show for a subcategory that is part of the
/// built-in (pre-defined) set — these use icons that match the app theme
/// instead of emojis. Returns null for user-defined subcategories, which are
/// rendered with an emoji instead. Unknown built-in names fall back to a
/// generic label icon.
IconData? subcategoryIcon(ExpenseCategory category, String subcategory) {
  if (category.userDefinedSubcategories.contains(subcategory)) return null;
  return _subcategoryIconMap[subcategory] ?? Icons.label_outline_rounded;
}

// Curated Material icon per built-in subcategory, matching the orange app theme.
const Map<String, IconData> _subcategoryIconMap = <String, IconData>{
  // Food & Drinks
  'Groceries': Icons.local_grocery_store_rounded,
  'Restaurant & Café': Icons.restaurant_rounded,
  'Snacks': Icons.fastfood_rounded,
  'Food delivery': Icons.delivery_dining_rounded,
  // Shopping
  'Clothes & Shoes': Icons.checkroom_rounded,
  'Medicine': Icons.medication_rounded,
  'Electronics': Icons.devices_rounded,
  'Accessories': Icons.watch_rounded,
  'Gifts': Icons.card_giftcard_rounded,
  'Health': Icons.favorite_rounded,
  'Home': Icons.home_rounded,
  'Beauty': Icons.brush_rounded,
  'Jewellery': Icons.diamond_rounded,
  'Kids': Icons.child_care_rounded,
  'Pets': Icons.pets_rounded,
  'Stationery & DIY': Icons.handyman_rounded,
  // Housing
  'Rent or mortgage': Icons.key_rounded,
  'Utilities': Icons.bolt_rounded,
  'Furniture': Icons.chair_rounded,
  'Repairs': Icons.build_rounded,
  'Home supplies': Icons.cleaning_services_rounded,
  // Transportation
  'Public transport': Icons.directions_bus_rounded,
  'Ride share': Icons.local_taxi_rounded,
  'Taxi': Icons.local_taxi_rounded,
  'Bicycle': Icons.directions_bike_rounded,
  // Vehicle
  'Fuel': Icons.local_gas_station_rounded,
  'Insurance': Icons.verified_user_rounded,
  'Parking': Icons.local_parking_rounded,
  'Rentals': Icons.directions_car_rounded,
  'Maintenance': Icons.settings_rounded,
  // Lifestyle & Wellbeing
  'Fitness': Icons.fitness_center_rounded,
  'Charity': Icons.volunteer_activism_rounded,
  'Culture & events': Icons.theater_comedy_rounded,
  'Education': Icons.school_rounded,
  'Healthcare': Icons.medical_services_rounded,
  'Hobbies': Icons.palette_rounded,
  'Travel & holidays': Icons.flight_rounded,
  // Entertainment
  'Books & audiobooks': Icons.menu_book_rounded,
  'Subscriptions': Icons.autorenew_rounded,
  'Sports': Icons.sports_soccer_rounded,
  'Games': Icons.sports_esports_rounded,
  'Movies & shows': Icons.movie_rounded,
  // Communication
  'Internet bill': Icons.wifi_rounded,
  'Phone bill': Icons.phone_rounded,
  'Postage': Icons.markunread_mailbox_rounded,
  // Software & Digital Assets
  'Software': Icons.code_rounded,
  'Cloud services': Icons.cloud_rounded,
  'Digital assets': Icons.storage_rounded,
  // Investments
  'Stocks & ETFs': Icons.show_chart_rounded,
  'Mutual funds': Icons.savings_rounded,
  'Bonds': Icons.account_balance_rounded,
  'Retirement contributions': Icons.account_balance_wallet_rounded,
  // Legal & Financial
  'Bank charges': Icons.account_balance_rounded,
  'Professional fees': Icons.gavel_rounded,
  'Child support': Icons.family_restroom_rounded,
  'Fines': Icons.gpp_bad_rounded,
  'Loan interest': Icons.percent_rounded,
  'Taxes': Icons.receipt_long_rounded,
  'Fees & taxes': Icons.receipt_rounded,
  // Income: Salary & Wages
  'Base salary': Icons.payments_rounded,
  'Overtime': Icons.schedule_rounded,
  'Bonus': Icons.celebration_rounded,
  'Commission': Icons.handshake_rounded,
  'Allowance': Icons.savings_outlined,
  'Advance payment': Icons.fast_forward_rounded,
  // Income: Dues Received
  'Outstanding payment': Icons.pending_actions_rounded,
  'Reimbursement': Icons.currency_exchange_rounded,
  'Refund on bills': Icons.replay_rounded,
  'Pending invoice': Icons.receipt_long_rounded,
  // Income: Interest
  'Savings interest': Icons.savings_rounded,
  'Deposit interest': Icons.account_balance_rounded,
  'Fixed deposit': Icons.lock_rounded,
  'Bond interest': Icons.description_rounded,
  // Income: Dividends
  'Stock dividends': Icons.show_chart_rounded,
  'Fund distributions': Icons.ballot_rounded,
  'Cash dividends': Icons.payments_rounded,
  // Income: Loan Repayments
  'Personal loan repayment': Icons.handshake_rounded,
  'Business loan repayment': Icons.business_center_rounded,
  'Partial repayment': Icons.call_split_rounded,
  // Income: Rental Income
  'Property rent': Icons.home_work_rounded,
  'Equipment rent': Icons.hardware_rounded,
  'Shared room': Icons.bed_rounded,
  'Parking space': Icons.local_parking_rounded,
  // Income: Sales
  'Personal items': Icons.sell_rounded,
  'Business sales': Icons.storefront_rounded,
  'Online sales': Icons.shopping_bag_rounded,
  'Marketplace sale': Icons.store_rounded,
  // Income: Gifts
  'Cash gift': Icons.card_giftcard_rounded,
  'Gift card': Icons.card_giftcard_rounded,
  'Family support': Icons.family_restroom_rounded,
  'Celebration gift': Icons.celebration_rounded,
  // Income: Refunds
  'Purchase refund': Icons.refresh_rounded,
  'Tax refund': Icons.request_quote_rounded,
  'Shipping refund': Icons.local_shipping_rounded,
  // Income: Freelance & Side Work
  'Freelance project': Icons.work_rounded,
  'Consulting': Icons.support_agent_rounded,
  'Side job': Icons.work_outline_rounded,
  'Contract work': Icons.description_rounded,
  'Content creation': Icons.video_call_rounded,
  // Income: Other Income
  'Cashback': Icons.currency_exchange_rounded,
  'Prize': Icons.emoji_events_rounded,
  'Gift voucher': Icons.card_giftcard_rounded,
  'Other': Icons.more_horiz_rounded,
};

/// A curated default emoji per common subcategory, falling back to a stable,
/// name-derived emoji so that every distinct subcategory still gets its own.
String defaultSubcategoryEmoji(String name) {
  const map = <String, String>{
    'Groceries': '🛒',
    'Restaurant & Café': '🍽️',
    'Snacks': '🍿',
    'Food delivery': '🛵',
    'Clothes & Shoes': '👕',
    'Medicine': '💊',
    'Electronics': '📱',
    'Accessories': '🧢',
    'Gifts': '🎁',
    'Health': '🩺',
    'Home': '🏡',
    'Beauty': '💄',
    'Jewellery': '💍',
    'Kids': '🧸',
    'Pets': '🐾',
    'Stationery & DIY': '🛠',
    'Rent or mortgage': '🏠',
    'Utilities': '💡',
    'Furniture': '🛋',
    'Repairs': '🔧',
    'Home supplies': '🧻',
    'Public transport': '🚌',
    'Ride share': '🚕',
    'Taxi': '🚖',
    'Bicycle': '🚲',
    'Fuel': '⛽',
    'Insurance': '🛡',
    'Parking': '🅿',
    'Rentals': '🚙',
    'Maintenance': '🔩',
    'Fitness': '🏋',
    'Charity': '🤝',
    'Culture & events': '🎭',
    'Education': '📚',
    'Healthcare': '🩺',
    'Hobbies': '🎨',
    'Travel & holidays': '✈️',
    'Books & audiobooks': '📖',
    'Subscriptions': '🔁',
    'Sports': '⚽',
    'Games': '🎮',
    'Movies & shows': '🎬',
    'Internet bill': '🌐',
    'Phone bill': '📞',
    'Postage': '📮',
    'Software': '💻',
    'Cloud services': '☁️',
    'Digital assets': '💾',
    'Stocks & ETFs': '📈',
    'Mutual funds': '💰',
    'Bonds': '📊',
    'Retirement contributions': '🏦',
    'Bank charges': '🏧',
    'Professional fees': '⚖️',
    'Child support': '👨‍👩‍👧',
    'Fines': '🚫',
    'Taxes': '🧾',
    'Loan interest': '🏦',
    'Fees & taxes': '🧾',
    'Base salary': '💵',
    'Overtime': '⏰',
    'Bonus': '🎉',
    'Commission': '💼',
    'Allowance': '🪙',
    'Advance payment': '⏳',
    'Outstanding payment': '📋',
    'Reimbursement': '🔁',
    'Refund on bills': '↩️',
    'Pending invoice': '🧾',
    'Savings interest': '🏦',
    'Deposit interest': '🏧',
    'Fixed deposit': '🔐',
    'Bond interest': '📄',
    'Stock dividends': '📊',
    'Fund distributions': '🤲',
    'Cash dividends': '💵',
    'Personal loan repayment': '🤝',
    'Business loan repayment': '🏢',
    'Partial repayment': '🪙',
    'Property rent': '🏘',
    'Equipment rent': '🚜',
    'Shared room': '🛏',
    'Parking space': '🅿',
    'Personal items': '🛍',
    'Business sales': '💼',
    'Online sales': '🌐',
    'Marketplace sale': '🏪',
    'Cash gift': '💝',
    'Gift card': '🎟',
    'Family support': '👨‍👩‍👧',
    'Celebration gift': '🎂',
    'Purchase refund': '🛒',
    'Gift voucher': '🎫',
    'Other': '📦',
  };
  final match = map[name];
  if (match != null) return match;

  // Stable, deterministic fallback so distinct names still get distinct logos.
  const palette = [
    '🏷️',
    '🧾',
    '🛍️',
    '💊',
    '📦',
    '⚙️',
    '🧰',
    '🪙',
    '📌',
    '🔖',
    '🧺',
    '🧴',
    '🔋',
    '📎',
    '🎯',
    '🧩',
    '🪛',
    '🧵',
    '🖇️',
    '🔭',
  ];
  return palette[name.hashCode.abs() % palette.length];
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
    this.id,
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

  final String? id;
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
        id: id,
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
      'id': id,
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

  factory TransactionItem.fromMap(String id, Map<String, dynamic> data) {
    return TransactionItem(
      id: (data['id'] as String?) ?? id,
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      icon: iconFromName(data['iconName'] as String?) ?? Icons.category_rounded,
      iconColor: Color((data['iconColor'] as num?)?.toInt() ?? 0xFFF97316),
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

// Realtime sync state of the user's Firestore data. Used to surface an
// "offline" / "syncing" indicator so the user knows when writes are only stored
// locally and will be pushed once the network returns.
enum SyncStatus {
  // Fully up to date with the server.
  synced,
  // Reading from the local cache because the server is unreachable.
  offline,
  // Connected to the server but with local writes still waiting to be pushed.
  pending,
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

// One recorded repayment against a debt. Kept so deleting a linked repayment
// transaction can replay the history and revert the debt to its prior value.
class DebtRepayment {
  const DebtRepayment({required this.transactionId, required this.amount});

  final String transactionId;
  final double amount;

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'amount': amount,
    };
  }

  factory DebtRepayment.fromMap(Map<String, dynamic> data) {
    return DebtRepayment(
      transactionId: (data['transactionId'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

// One debt (borrowed or lent) with a settlement state.
class DebtItem {
  const DebtItem({
    required this.id,
    required this.person,
    required this.amount,
    this.type = DebtType.borrowed,
    this.settlement = DebtSettlement.active,
    this.note,
    this.creationTransactionId,
    this.repaymentTransactionId,
    this.remainingAmount,
    this.createdType,
    this.repaymentLog = const [],
    required this.createdAt,
  });

  final String id;
  final String person;
  // Original principal recorded when the debt was created. This never changes
  // even if overpayments flip the direction of the debt.
  final double amount;
  final DebtType type;
  final DebtSettlement settlement;
  final String? note;
  final String? creationTransactionId;
  final String? repaymentTransactionId;
  // Outstanding balance after partial repayments. Null means the full amount
  // is still owed (backwards compatible with records created before partial
  // repayments existed).
  final double? remainingAmount;
  // Direction the debt was originally created in (before any overpay flips).
  // Null falls back to `type` for records created before this was tracked.
  final DebtType? createdType;
  // Ordered history of repayments, used to revert changes when a linked
  // repayment transaction is deleted.
  final List<DebtRepayment> repaymentLog;
  final DateTime createdAt;

  bool get isClosed => settlement != DebtSettlement.active;
  bool get isRepaid => settlement == DebtSettlement.repaid;

  // Current outstanding balance (accounting for any partial repayments).
  double get remaining => remainingAmount ?? amount;

  bool get hasPartialRepayment => remainingAmount != null && remainingAmount != amount;

  // The direction the debt was first recorded in.
  DebtType get originType => createdType ?? type;

  DebtItem copyWith({
    DebtType? type,
    DebtSettlement? settlement,
    String? repaymentTransactionId,
    bool clearRepaymentTransactionId = false,
    double? remainingAmount,
    bool clearRemainingAmount = false,
    DebtType? createdType,
    List<DebtRepayment>? repaymentLog,
  }) => DebtItem(
    id: id,
    person: person,
    amount: amount,
    type: type ?? this.type,
    settlement: settlement ?? this.settlement,
    note: note,
    creationTransactionId: creationTransactionId,
    repaymentTransactionId: clearRepaymentTransactionId
        ? null
        : repaymentTransactionId ?? this.repaymentTransactionId,
    remainingAmount: clearRemainingAmount
        ? null
        : remainingAmount ?? this.remainingAmount,
    createdType: createdType ?? this.createdType,
    repaymentLog: repaymentLog ?? this.repaymentLog,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() {
    return {
      'person': person,
      'amount': amount,
      'type': type.name,
      'settlement': settlement.name,
      'note': note,
      'creationTransactionId': creationTransactionId,
      'repaymentTransactionId': repaymentTransactionId,
      'remainingAmount': remainingAmount,
      'createdType': createdType?.name,
      'repaymentLog': repaymentLog.map((entry) => entry.toMap()).toList(),
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
      creationTransactionId: data['creationTransactionId'] as String?,
      repaymentTransactionId: data['repaymentTransactionId'] as String?,
      remainingAmount: (data['remainingAmount'] as num?)?.toDouble(),
      createdType: (data['createdType'] as String?) == null
          ? null
          : DebtType.values.firstWhere(
              (t) => t.name == data['createdType'],
              orElse: () => DebtType.borrowed,
            ),
      repaymentLog: ((data['repaymentLog'] as List?) ?? const [])
          .whereType<Map>()
          .map((entry) => DebtRepayment.fromMap(Map<String, dynamic>.from(entry)))
          .toList(),
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
    this.createdAt,
  });

  final String id;
  final String name;
  final String? subcategory;
  final bool isDone;
  final double? price;
  final DateTime? completedAt;
  final DateTime? createdAt;

  ShoppingItem copyWith({bool? isDone, double? price, DateTime? completedAt}) =>
      ShoppingItem(
        id: id,
        name: name,
        subcategory: subcategory,
        isDone: isDone ?? this.isDone,
        price: price ?? this.price,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subcategory': subcategory,
      'isDone': isDone,
      'price': price,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'createdAt': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory ShoppingItem.fromMap(String id, Map<String, dynamic> data) {
    return ShoppingItem(
      id: id,
      name: (data['name'] as String?) ?? '',
      subcategory: data['subcategory'] as String?,
      isDone: (data['isDone'] as bool?) ?? false,
      price: (data['price'] as num?)?.toDouble(),
      completedAt: data['completedAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['completedAt'] as num).toInt(),
            )
          : null,
      createdAt: data['createdAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['createdAt'] as num).toInt(),
            )
          : null,
    );
  }
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
    String? title,
    double? amount,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? lastConfirmedDate,
  }) => PlannedPayment(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    icon: icon,
    iconColor: iconColor,
    categoryName: categoryName,
    emoji: emoji,
    subcategory: subcategory,
    isIncome: isIncome,
    repeat: repeat,
    customEveryDays: customEveryDays,
    startDate: startDate ?? this.startDate,
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
      icon: iconFromName(data['iconName'] as String?) ?? Icons.category_rounded,
      iconColor: Color((data['iconColor'] as num?)?.toInt() ?? 0xFFF97316),
      categoryName: (data['categoryName'] as String?) ?? '',
      emoji: data['emoji'] as String?,
      subcategory: data['subcategory'] as String?,
      isIncome: (data['isIncome'] as bool?) ?? false,
      repeat: RepeatFrequency.values.firstWhere(
        (repeat) => repeat.name == data['repeat'],
        orElse: () => RepeatFrequency.once,
      ),
      customEveryDays: ((data['customEveryDays'] as num?)?.toInt() ?? 7)
          .clamp(1, 36500)
          .toInt(),
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
    // Bound the loop: a non-positive custom interval would otherwise spin
    // forever and freeze the UI (white screen) on corrupt data.
    var guard = 0;
    while (date.isBefore(target) && guard < 10000) {
      date = _advance(date);
      guard++;
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
        return date.add(
          Duration(days: customEveryDays < 1 ? 1 : customEveryDays),
        );
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
    required this.id,
    required this.label,
    required this.spent,
    required this.limit,
    required this.daysLeft,
    required this.status,
    required this.statusColor,
    required this.icon,
    required this.iconBg,
    this.period = 'monthly',
    required this.startDate,
    this.customDays = 30,
  });

  final String id;
  final String label;
  final double spent;
  final double limit;
  final int daysLeft;
  final String status;
  final Color statusColor;
  final IconData icon;
  final Color iconBg;
  final String period;
  final DateTime startDate;
  final int customDays;

  BudgetCategory copyWith({
    double? spent,
    String? label,
    double? limit,
    String? period,
    int? customDays,
    DateTime? startDate,
  }) => BudgetCategory(
    id: id,
    label: label ?? this.label,
    spent: spent ?? this.spent,
    limit: limit ?? this.limit,
    daysLeft: daysLeft,
    status: status,
    statusColor: statusColor,
    icon: icon,
    iconBg: iconBg,
    period: period ?? this.period,
    startDate: startDate ?? this.startDate,
    customDays: customDays ?? this.customDays,
  );

  Map<String, dynamic> toMap() => {
    'label': label,
    'limit': limit,
    'period': period,
    'startDate': startDate.millisecondsSinceEpoch,
    'customDays': customDays,
  };
  factory BudgetCategory.fromMap(String id, Map<String, dynamic> data) =>
      BudgetCategory(
        id: id,
        label: (data['label'] as String?) ?? 'Budget',
        limit: (data['limit'] as num?)?.toDouble() ?? 0,
        spent: 0,
        daysLeft: 0,
        status: 'Healthy',
        statusColor: const Color(0xFF16A34A),
        icon: Icons.account_balance_wallet_outlined,
        iconBg: const Color(0xFFFFF4E8),
        period: (data['period'] as String?) ?? 'monthly',
        startDate: DateTime.fromMillisecondsSinceEpoch(
          (data['startDate'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        customDays: ((data['customDays'] as num?)?.toInt() ?? 30)
            .clamp(1, 36500)
            .toInt(),
      );
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
    required this.id,
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

  final String id;
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

  SavingsGoal copyWith({double? current, String? title, double? target}) =>
      SavingsGoal.fromMap(id, {
        ...toMap(),
        'current': current ?? this.current,
        'title': title ?? this.title,
        'target': target ?? this.target,
      });

  Map<String, dynamic> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'current': current,
    'target': target,
  };
  factory SavingsGoal.fromMap(String id, Map<String, dynamic> data) {
    final current = (data['current'] as num?)?.toDouble() ?? 0;
    final target = (data['target'] as num?)?.toDouble() ?? 0;
    final complete = target > 0 && current >= target;
    return SavingsGoal(
      id: id,
      title: (data['title'] as String?) ?? 'Savings goal',
      subtitle: (data['subtitle'] as String?) ?? '',
      current: current,
      target: target,
      icon: Icons.savings_outlined,
      iconColor: const Color(0xFFF59E0B),
      iconBg: const Color(0xFFFFF4E8),
      status: complete ? 'Complete' : 'In progress',
      statusColor: complete ? const Color(0xFF16A34A) : const Color(0xFFB45309),
      statusBg: complete ? const Color(0xFFDCFCE7) : const Color(0xFFFFF4E8),
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) =>
      AppNotification(
        id: id,
        title: (data['title'] as String?) ?? 'Notification',
        body: (data['body'] as String?) ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (data['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );
}
