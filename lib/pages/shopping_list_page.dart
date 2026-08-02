import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';
import '../utils/currency_settings.dart';
import '../widgets/empty_state_card.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  Future<void> _openAddPage() async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddShoppingItemPage()),
    );
    if (added == true && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Shopping item added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeItem(ShoppingItem item) async {
    final controller = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Price for ${item.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: '0',
            prefixText: '${CurrencySettings.symbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.trim()) ?? 0,
            ),
            child: const Text('Add to expenses'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (price == null || price <= 0 || !mounted) return;
    await FinanceAppScope.of(context).completeShoppingItem(
      id: item.id,
      price: price,
      subcategory: item.subcategory ?? '',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to expenses'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDelete(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('${item.name} will be removed from your shopping list.'),
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
    if (confirmed == true && mounted) {
      FinanceAppScope.of(context).deleteShoppingItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = FinanceAppScope.of(context);
    final items = state.shoppingItems;

    final groups = <String, List<ShoppingItem>>{};
    for (final item in items) {
      groups
          .putIfAbsent(item.subcategory ?? 'General', () => [])
          .add(item);
    }
    final groupKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == 'General') return -1;
        if (b == 'General') return 1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping List',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          const Text(
            'Items',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const EmptyStateCard(
              title: 'No shopping items yet',
              subtitle:
                  'Add items below, then tick them off to record their price as an expense.',
              icon: Icons.shopping_cart_outlined,
            )
          else
            for (final key in groupKeys) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    key,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Text(
                    '${groups[key]!.length}',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final item in groups[key]!) ...[
                _ShoppingItemCard(
                  item: item,
                  onComplete: () => _completeItem(item),
                  onDelete: () => _confirmDelete(item),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class AddShoppingItemPage extends StatefulWidget {
  const AddShoppingItemPage({super.key});

  @override
  State<AddShoppingItemPage> createState() => _AddShoppingItemPageState();
}

class _AddShoppingItemPageState extends State<AddShoppingItemPage> {
  Future<String?> _promptNewSubcategory() async {
    final controller = TextEditingController();
    final appState = FinanceAppScope.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New shopping subcategory'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Subcategory name',
            hintText: 'e.g. Kitchen',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return null;
    await appState.addSubcategory(
      categoryId: 'shopping',
      name: name,
      isIncome: false,
    );
    return name;
  }

  Future<void> _promptItemName(String subcategory) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          subcategory.isEmpty
              ? 'Add item to General'
              : 'Add item to $subcategory',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Item name',
            hintText: 'e.g. Milk',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    FinanceAppScope.of(context).addShoppingItem(
      ShoppingItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: trimmed,
        subcategory: subcategory.isEmpty ? null : subcategory,
        createdAt: DateTime.now(),
      ),
    );
    Navigator.of(context).pop(true);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Shopping item added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = FinanceAppScope.of(context).shoppingSubcategories;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Shopping Item',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a subcategory, then name the item.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SubcategoryChip(
                    label: 'General',
                    onTap: () => _promptItemName(''),
                  ),
                  for (final subcategory in subcategories)
                    _SubcategoryChip(
                      label: subcategory,
                      onTap: () => _promptItemName(subcategory),
                    ),
                  ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 17,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text('Add subcategory'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final added = await _promptNewSubcategory();
                      if (added != null && messenger.mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Subcategory added'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubcategoryChip extends StatelessWidget {
  const _SubcategoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFFFF4E8),
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: Color(0xFFB45309),
        fontWeight: FontWeight.w600,
      ),
      onPressed: onTap,
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({
    required this.item,
    required this.onComplete,
    required this.onDelete,
  });

  final ShoppingItem item;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _CheckCircle(
            done: item.isDone,
            onTap: () {
              if (item.isDone) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Already added to expenses'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                onComplete();
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: item.isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isDone ? const Color(0xFF9CA3AF) : null,
                  ),
                ),
                if (item.isDone && item.price != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(item.price!),
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (item.subcategory != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subcategory!,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFDC2626),
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? const Color(0xFF22C55E) : Colors.white,
          border: Border.all(
            color: done ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB),
            width: 2,
          ),
        ),
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
