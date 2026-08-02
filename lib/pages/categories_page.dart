import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../widgets/category_logo.dart';
import 'category_detail_page.dart';

enum _CategoryPageMenuAction { expense, income }

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({
    super.key,
    this.selectionMode = false,
    this.isIncome = false,
  });

  final bool selectionMode;
  final bool isIncome;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  late bool _isIncome = widget.isIncome;

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final categories = _isIncome
        ? state.incomeCategories
        : state.expenseCategories;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_CategoryPageMenuAction>(
            onSelected: (action) {
              setState(() {
                _isIncome = action == _CategoryPageMenuAction.income;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CategoryPageMenuAction.expense,
                child: Text('Expense categories'),
              ),
              PopupMenuItem(
                value: _CategoryPageMenuAction.income,
                child: Text('Income categories'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, state),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Expense',
                      selected: !_isIncome,
                      onTap: () => setState(() => _isIncome = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Income',
                      selected: _isIncome,
                      onTap: () => setState(() => _isIncome = true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: categories.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) => _CategoryCard(
                category: categories[index],
                onAddSubcategory: () =>
                    _addSubcategory(context, state, categories[index]),
                onDeleteCategory: categories[index].isUserDefined
                    ? () => _deleteCategory(context, state, categories[index])
                    : null,
                onDeleteSubcategory: (subcategory) => state.deleteSubcategory(
                  category: categories[index],
                  subcategory: subcategory,
                  isIncome: _isIncome,
                ),
                onSelect: widget.selectionMode
                    ? (subcategory) => Navigator.of(context).pop(
                        CategorySelection(
                          category: categories[index],
                          subcategory: subcategory,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, FinanceAppState state) async {
    final result = await _showCategoryDialog(context);
    if (result == null) return;
    await state.addExpenseCategory(
      name: result.name,
      emoji: result.emoji,
      isIncome: _isIncome,
    );
  }

  Future<void> _addSubcategory(
    BuildContext context,
    FinanceAppState state,
    ExpenseCategory category,
  ) async {
    final result = await promptSubCategoryLogo(context);
    if (result == null) return;
    final (name, emoji) = result;
    await state.addSubcategory(
      categoryId: category.id,
      name: name,
      emoji: emoji,
      isIncome: _isIncome,
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    FinanceAppState state,
    ExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: const Text(
          'Transactions in this category will be moved to Missing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.deleteCategory(category: category, isIncome: _isIncome);
    }
  }

  Future<_NewCategory?> _showCategoryDialog(BuildContext context) async {
    final result = await showDialog<_NewCategory>(
      context: context,
      builder: (dialogContext) => const _NewCategoryDialog(),
    );
    return result;
  }
}

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emojiController = TextEditingController(
    text: '🏷️',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emojiController,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Emoji logo'),
          ),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Category name'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final emoji = _emojiController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(
                context,
                _NewCategory(name, emoji.isEmpty ? '🏷️' : emoji),
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onAddSubcategory,
    required this.onDeleteSubcategory,
    this.onDeleteCategory,
    this.onSelect,
  });
  final ExpenseCategory category;
  final VoidCallback onAddSubcategory;
  final ValueChanged<String> onDeleteSubcategory;
  final VoidCallback? onDeleteCategory;
  final ValueChanged<String?>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: category.isUserDefined
              ? Text(
                  category.emoji ?? '🏷️',
                  style: const TextStyle(fontSize: 24),
                )
              : Icon(category.icon, color: const Color(0xFFF59E0B)),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          category.subcategories.isEmpty
              ? 'No subcategories yet'
              : '${category.subcategories.length} subcategories',
        ),
        trailing: onSelect != null
            ? IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFFF59E0B),
                ),
                onPressed: () => onSelect!(null),
              )
            : onDeleteCategory == null
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                ),
                onPressed: onDeleteCategory,
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subcategory in category.subcategories)
                  onSelect == null
                      ? Chip(
                          avatar: SubcategoryLogo(
                            category: category,
                            subcategory: subcategory,
                          ),
                          label: Text(subcategory),
                          backgroundColor: const Color(0xFFFFF4E8),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                          deleteIcon:
                              category.userDefinedSubcategories.contains(
                                subcategory,
                              )
                              ? const Icon(Icons.close, size: 18)
                              : null,
                          onDeleted:
                              category.userDefinedSubcategories.contains(
                                subcategory,
                              )
                              ? () => onDeleteSubcategory(subcategory)
                              : null,
                        )
                      : ActionChip(
                          avatar: SubcategoryLogo(
                            category: category,
                            subcategory: subcategory,
                          ),
                          label: Text(subcategory),
                          backgroundColor: const Color(0xFFFFF4E8),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w600,
                          ),
                          onPressed: () => onSelect!(subcategory),
                        ),
                ActionChip(
                  avatar: const Icon(
                    Icons.add,
                    size: 17,
                    color: Color(0xFFF59E0B),
                  ),
                  label: const Text('Add subcategory'),
                  onPressed: onAddSubcategory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewCategory {
  const _NewCategory(this.name, this.emoji);
  final String name;
  final String emoji;
}
