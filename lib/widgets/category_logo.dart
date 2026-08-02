import 'package:flutter/material.dart';

import '../models/finance_models.dart';

// Renders the logo for a category: the orange Material icon for built-in
// categories (matching the app theme) or the user-chosen emoji for
// user-defined categories.
class CategoryLogo extends StatelessWidget {
  const CategoryLogo({
    super.key,
    required this.category,
    this.iconSize = 26,
    this.emojiSize = 22,
    this.color = const Color(0xFFF59E0B),
  });

  final ExpenseCategory category;
  final double iconSize;
  final double emojiSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!category.isUserDefined && category.icon != null) {
      return Icon(category.icon, size: iconSize, color: color);
    }
    return Text(
      category.emoji ?? '🏷️',
      style: TextStyle(fontSize: emojiSize),
    );
  }
}

// Renders the logo for a subcategory: a curated orange Material icon for
// built-in subcategories, or the emoji for user-defined ones.
class SubcategoryLogo extends StatelessWidget {
  const SubcategoryLogo({
    super.key,
    required this.category,
    required this.subcategory,
    this.iconSize = 20,
    this.emojiSize = 18,
    this.color = const Color(0xFFF59E0B),
  });

  final ExpenseCategory category;
  final String subcategory;
  final double iconSize;
  final double emojiSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = subcategoryIcon(category, subcategory);
    if (icon != null) return Icon(icon, size: iconSize, color: color);
    return Text(
      subcategoryEmoji(category, subcategory),
      style: TextStyle(fontSize: emojiSize),
    );
  }
}
