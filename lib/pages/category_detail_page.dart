import 'package:flutter/material.dart';

import '../models/finance_models.dart';

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key, required this.category});
  final ExpenseCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
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
                    CategorySelection(category: category),
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
                          child: category.isUserDefined
                              ? Text(category.emoji ?? '🏷️', style: const TextStyle(fontSize: 26))
                              : Icon(category.icon, color: const Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to use the general category.',
                                style: const TextStyle(color: Color(0xFF64748B)),
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
          if (category.subcategories.isEmpty)
            const _EmptySubcategoryState()
          else
            ...category.subcategories.map(
              (subcategory) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  category: category,
                  label: subcategory,
                  onTap: () => Navigator.pop(
                    context,
                    CategorySelection(
                      category: category,
                      subcategory: subcategory,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({required this.category, required this.label, required this.onTap});
  final ExpenseCategory category;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF4E8),
          child: category.isUserDefined
              ? Text(category.emoji ?? '🏷️')
              : Icon(category.icon, color: const Color(0xFFF59E0B)),
        ),
        title: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
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
          'No subcategories yet. Use the main category or add one from the categories page.',
          style: TextStyle(color: Color(0xFF475569)),
        ),
      );
    }
  }
