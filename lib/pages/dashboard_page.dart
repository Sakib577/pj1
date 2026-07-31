import 'package:flutter/material.dart';

import 'package:pj1/data/mock_data.dart';
import 'package:pj1/models/finance_models.dart';
import 'package:pj1/pages/add_transaction_page.dart';
import 'package:pj1/pages/budget_page.dart';
import 'package:pj1/pages/categories_page.dart';
import 'package:pj1/pages/profile_page.dart';
import 'package:pj1/pages/savings_page.dart';
import 'package:pj1/utils/currency_formatters.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Controls which bottom-tab page is currently visible.
  int _navIndex = 0;

  void _onNavTap(int index) {
    // setState rebuilds UI so selected tab and content update.
    setState(() {
      _navIndex = index;
    });
  }

  Future<void> _openCategories() async {
    // Push categories page and wait for selected category text.
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const CategoriesPage(items: AppMockData.categories),
      ),
    );

    if (selected != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selected selected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _navIndex == 0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        centerTitle: !isHome,
        leading: isHome
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => _onNavTap(0),
              ),
        title: !isHome
            ? Text(
                _navIndex == 1
                    ? 'Monthly Budgets'
                    : _navIndex == 2
                        ? 'Savings Goals'
                        : 'Profile',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.menu, size: 26),
                  ),
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_outlined, size: 24),
                  ),
                ],
              ),
        actions: _navIndex == 1 || _navIndex == 2
            ? [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _navIndex,
        // IndexedStack keeps non-visible tabs alive instead of rebuilding them.
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCard(summary: AppMockData.balance),
                const SizedBox(height: 16),
                _StatsRow(stats: AppMockData.stats),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Categories',
                  trailing: 'View All',
                  onTrailingPressed: _openCategories,
                ),
                const SizedBox(height: 12),
                _CategoriesRow(
                  categories: AppMockData.categories,
                  onCategoryTap: (item) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.label} tapped'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: 'Recent Transactions', trailing: 'View All'),
                const SizedBox(height: 12),
                ...AppMockData.transactions.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TransactionTile(item: item),
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionHeader(title: 'Planned Payments', trailing: 'View All'),
                const SizedBox(height: 12),
                _PlannedPaymentsRow(items: AppMockData.plannedPayments),
                const SizedBox(height: 24),
              ],
            ),
          ),
          BudgetPage(budgets: AppMockData.budgetCategories),
          SavingsPage(overview: AppMockData.savingsOverview, goals: AppMockData.savingsGoals),
          const ProfilePage(),
        ],
      ),
      floatingActionButton: isHome
          ? FloatingActionButton(
              onPressed: () {
                // Open add transaction form from Home tab.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                );
              },
              backgroundColor: const Color(0xFFF59E0B),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        showFab: isHome,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('TOTAL BALANCE', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(formatCurrency(summary.total), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF1D6), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(summary.isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                Text('${summary.deltaPercent}% this month', style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final List<StatCardData> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(child: Padding(padding: EdgeInsets.only(right: i == stats.length - 1 ? 0 : 12), child: _StatCard(data: stats[i]))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final StatCardData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isPositive ? const Color(0xFF16A34A) : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(data.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(formatCurrency(data.amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories, this.onCategoryTap});
  final List<CategoryItem> categories;
  final ValueChanged<CategoryItem>? onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = categories[index];
          return InkWell(
            onTap: () => onCategoryTap?.call(item),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing, this.onTrailingPressed});
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        if (trailing != null)
          TextButton(
            onPressed: onTrailingPressed ?? () {},
            child: Text(trailing!, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});
  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: item.iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(item.subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
              ],
            ),
          ),
          Text('${item.negative ? '-' : ''}${formatCurrency(item.amount)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PlannedPaymentsRow extends StatelessWidget {
  const _PlannedPaymentsRow({required this.items});
  final List<PlannedPayment> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var item in items)
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: _PlannedPaymentCard(item: item))),
      ],
    );
  }
}

class _PlannedPaymentCard extends StatelessWidget {
  const _PlannedPaymentCard({required this.item});
  final PlannedPayment item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: item.background, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use app's dark foreground color for the icon so it matches
          // other primary text/icons across the app.
          Icon(item.icon, color: const Color(0xFF0F172A)),
          const SizedBox(height: 12),
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(item.due, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(formatCurrency(item.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap, required this.showFab});
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showFab;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _NavBarItem(icon: Icons.home_filled, label: 'Home', isSelected: currentIndex == 0, onTap: () => onTap(0))),
          Expanded(child: _NavBarItem(icon: Icons.account_balance_wallet, label: 'Budgets', isSelected: currentIndex == 1, onTap: () => onTap(1))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            width: showFab ? 40 : 0,
          ),
          Expanded(child: _NavBarItem(icon: Icons.savings, label: 'Savings', isSelected: currentIndex == 2, onTap: () => onTap(2))),
          Expanded(child: _NavBarItem(icon: Icons.person, label: 'Profile', isSelected: currentIndex == 3, onTap: () => onTap(3))),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({required this.icon, required this.label, required this.isSelected, required this.onTap});
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}


