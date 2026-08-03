import 'package:flutter/material.dart';

import '../models/finance_models.dart';
import '../widgets/category_logo.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({
    super.key,
    required this.category,
    this.onAddSubcategory,
  });

  final ExpenseCategory category;
  final Future<void> Function(String name, String? emoji)? onAddSubcategory;

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late final List<String> _subcategories = List.of(
    widget.category.subcategories,
  );

  Future<void> _addSubcategory() async {
    final result = await promptSubCategoryLogo(context);
    if (result == null) return;
    final (name, emoji) = result;
    final onAdd = widget.onAddSubcategory;
    if (onAdd != null) {
      await onAdd(name, emoji);
    }
    if (!mounted) return;
    setState(() {
      if (!_subcategories.contains(name)) {
        _subcategories.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(
                    context,
                    CategorySelection(category: widget.category),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4E8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: CategoryLogo(
                            category: widget.category,
                            iconSize: 30,
                            emojiSize: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.category.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to use the general category.',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'SUBCATEGORIES',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          if (_subcategories.isEmpty)
            const _EmptySubcategoryState()
          else
            ..._subcategories.map(
              (subcategory) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  category: widget.category,
                  label: subcategory,
                  onTap: () => Navigator.pop(
                    context,
                    CategorySelection(
                      category: widget.category,
                      subcategory: subcategory,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.onAddSubcategory != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 17,
                  color: Color(0xFFF59E0B),
                ),
                label: const Text('Add subcategory'),
                onPressed: _addSubcategory,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Logo (icon or emoji) used for the category header and subcategory rows.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.category,
    required this.label,
    required this.onTap,
  });
  final ExpenseCategory category;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SubcategoryLogo(
          category: category,
          subcategory: label,
          iconSize: 22,
          emojiSize: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _EmptySubcategoryState extends StatelessWidget {
  const _EmptySubcategoryState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No subcategories yet. Use the main category or add one below.',
        style: TextStyle(color: Color(0xFF475569)),
      ),
    );
  }
}

/// Shows a dialog to enter a new subcategory name and an optional emoji logo.
/// Returns a record (name, emojiOrNull), or null when cancelled.
Future<(String, String?)?> promptSubCategoryLogo(BuildContext context) async {
  final nameController = TextEditingController();
  final emojiController = TextEditingController(text: '🏷️');
  final result = await showDialog<(String, String?)>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add subcategory'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emojiController,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Emoji logo'),
          ),
          TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Subcategory name',
              hintText: 'e.g. Bakery',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isEmpty) return;
            final emoji = emojiController.text.trim();
            Navigator.pop(
              dialogContext,
              (name, emoji.isEmpty ? null : emoji),
            );
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
  // showDialog completes as soon as the route starts popping. Keep the
  // controllers alive through the closing animation so TextField does not
  // rebuild with a disposed controller.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  nameController.dispose();
  emojiController.dispose();
  return result;
}
