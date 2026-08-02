import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:pj1/models/finance_models.dart';
import 'package:pj1/pages/add_transaction_page.dart';
import 'package:pj1/pages/budget_page.dart';
import 'package:pj1/pages/categories_page.dart';
import 'package:pj1/pages/debts_page.dart';
import 'package:pj1/pages/finance_tools_page.dart';
import 'package:pj1/pages/planned_payments_page.dart';
import 'package:pj1/pages/profile_page.dart';
import 'package:pj1/pages/savings_page.dart';
import 'package:pj1/pages/settings_page.dart';
import 'package:pj1/pages/shopping_list_page.dart';
import 'package:pj1/pages/transactions_page.dart';
import 'package:pj1/state/finance_app_state.dart';
import 'package:pj1/utils/currency_formatters.dart';
import 'package:pj1/widgets/empty_state_card.dart';
import 'package:pj1/widgets/planned_payment_card.dart';
import 'package:pj1/widgets/transaction_actions.dart';
import 'package:pj1/widgets/transaction_tile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late FinanceAppState _appState;
  bool _categoriesSynced = false;
  bool _dueCheckDone = false;

  // Controls which bottom-tab page is currently visible.
  int _navIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appState = FinanceAppScope.of(context);
    if (!_categoriesSynced) {
      _categoriesSynced = true;
      _initUserData();
    }
  }

  Future<void> _initUserData() async {
    await _appState.syncUserData();
    if (!mounted) return;
    await _promptDefaultCurrencyIfNeeded();
    await _checkDuePayments();
  }

  bool _currencyPromptDone = false;

  // First-run setup: if the signed-in account has no default currency stored
  // yet, ask the user to pick one and save it to Firestore so later logins
  // start with that currency.
  Future<void> _promptDefaultCurrencyIfNeeded() async {
    if (_currencyPromptDone) return;
    _currencyPromptDone = true;
    if (!_appState.currencyNeedsSetup) return;
    try {
      await _appState.ensureCurrencyAvailable();
    } catch (_) {}
    if (!mounted) return;
    final code = await showCurrencyPicker(
      context,
      codes: _appState.availableCurrencyCodes,
      selectedCode: _appState.currencyCode,
    );
    if (!mounted) return;
    // Record the choice (or the current default if the user dismissed the
    // picker) so the account is not asked again on every login.
    _appState.changeCurrency(code ?? _appState.currencyCode);
  }

  // Prompts once per session for planned payments whose occurrence is due
  // today or overdue. Confirming records them as real transactions.
  Future<void> _checkDuePayments() async {
    if (_dueCheckDone || !mounted) return;
    _dueCheckDone = true;
    final due = _appState.plannedPayments
        .where((payment) => payment.needsConfirmation)
        .toList();
    if (due.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payments due'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: due.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final payment = due[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(payment.icon, color: payment.iconColor),
                title: Text(
                  payment.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(payment.categoryName),
                trailing: Text(
                  '${payment.isIncome ? '+' : '-'}'
                  '${formatCurrency(payment.amount)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'skip'),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'confirm'),
            child: const Text('Confirm & record'),
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == 'skip') return;

    if (action == 'delete') {
      for (final payment in due) {
        _appState.removePlannedPayment(payment.id);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            due.length == 1
                ? 'Planned payment deleted'
                : '${due.length} planned payments deleted',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final payment in due) {
      _appState.confirmPlannedPayment(payment.id);
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          due.length == 1
              ? 'Payment recorded as '
                    '${due.first.isIncome ? 'income' : 'expense'}'
              : '${due.length} payments recorded',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _appState.stopCategorySync();
    super.dispose();
  }

  void _onNavTap(int index) {
    // setState rebuilds UI so selected tab and content update.
    setState(() {
      _navIndex = index;
    });
  }

  Future<void> _openCategories() async {
    // Push categories page and wait for selected category text.
    final selected = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const CategoriesPage()));

    if (selected != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selected selected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTool(FinanceTool tool) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FinanceToolsPage(tool: tool)));
  }

  void _openPlannedPayments() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PlannedPaymentsPage()));
  }

  void _openDebts() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DebtsPage()));
  }

  void _openShoppingList() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ShoppingListPage()));
  }

  Future<void> _openFromDrawer(VoidCallback action) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (mounted) action();
  }

  @override
  Widget build(BuildContext context) {
    final appState = FinanceAppScope.of(context);
    final summary = appState.balanceSummary;
    final stats = appState.stats;
    final transactions = appState.transactions;
    final isHome = _navIndex == 0;

    return Scaffold(
      key: _scaffoldKey,
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
                    : 'Profile & Settings',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Open menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu, size: 26),
                  ),
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      size: 24,
                    ),
                  ),
                ],
              ),
        actions: _navIndex == 1 || _navIndex == 2
            ? [
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('More options tapped'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          _SyncStatusBanner(status: appState.syncStatus),
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceCard(summary: summary),
                      const SizedBox(height: 16),
                      _StatsRow(stats: stats),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Recent Transactions',
                        trailing: 'View All',
                        onTrailingPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransactionsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (transactions.isEmpty)
                        const EmptyStateCard(
                          title: 'No transactions yet',
                          subtitle:
                              'Add your first transaction to start tracking.',
                          icon: Icons.receipt_long,
                        )
                      else
                        ...transactions
                            .take(3)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TransactionTile(
                                  item: item,
                                  onTap: () =>
                                      showTransactionActions(context, item),
                                ),
                              ),
                            ),
                      const SizedBox(height: 12),
                      _SectionHeader(
                        title: 'Planned Payments',
                        trailing: 'View All',
                        onTrailingPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PlannedPaymentsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      if (appState.plannedPayments.isEmpty)
                        const EmptyStateCard(
                          title: 'No planned payments yet',
                          subtitle:
                              'Schedule upcoming bills once you create them.',
                          icon: Icons.event_note_outlined,
                        )
                      else
                        ...appState.plannedPayments
                            .take(3)
                            .map(
                              (payment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PlannedPaymentCard(
                                  payment: payment,
                                  onTap: () => showPlannedPaymentActions(
                                    context,
                                    payment,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                BudgetPage(budgets: appState.budgets),
                SavingsPage(
                  overview: appState.savingsOverview,
                  goals: appState.savingsGoals,
                ),
                const ProfilePage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isHome
          ? FloatingActionButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const AddTransactionPage()),
                );
                if (saved == true && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Transaction saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFFF59E0B),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      drawer: _AppDrawer(
        selectedIndex: _navIndex,
        onNavigate: (index) {
          Navigator.of(context).pop();
          _onNavTap(index);
        },
        onOpenCategories: () {
          _openFromDrawer(() => _openCategories());
        },
        onOpenPlannedPayments: () {
          _openFromDrawer(_openPlannedPayments);
        },
        onOpenDebts: () {
          _openFromDrawer(_openDebts);
        },
        onOpenShoppingList: () {
          _openFromDrawer(_openShoppingList);
        },
        onOpenTool: (tool) {
          _openFromDrawer(() => _openTool(tool));
        },
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        showFab: isHome,
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selectedIndex,
    required this.onNavigate,
    required this.onOpenCategories,
    required this.onOpenPlannedPayments,
    required this.onOpenDebts,
    required this.onOpenShoppingList,
    required this.onOpenTool,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenCategories;
  final VoidCallback onOpenPlannedPayments;
  final VoidCallback onOpenDebts;
  final VoidCallback onOpenShoppingList;
  final ValueChanged<FinanceTool> onOpenTool;

  @override
  Widget build(BuildContext context) {
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Signed-in account';

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(color: Color(0xFFF59E0B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Expense Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Verified account',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _DrawerNavigationItem(
              icon: Icons.home_outlined,
              label: 'Dashboard',
              selected: selectedIndex == 0,
              onTap: () => onNavigate(0),
            ),
            _DrawerNavigationItem(
              icon: Icons.grid_view_rounded,
              label: 'Categories',
              selected: false,
              onTap: onOpenCategories,
            ),
            _DrawerNavigationItem(
              icon: Icons.event_note_outlined,
              label: 'Planned Payments',
              selected: false,
              onTap: onOpenPlannedPayments,
            ),
            _DrawerNavigationItem(
              icon: Icons.handshake_outlined,
              label: 'Debts',
              selected: false,
              onTap: onOpenDebts,
            ),
            _DrawerNavigationItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Shopping List',
              selected: false,
              onTap: onOpenShoppingList,
            ),
            _DrawerNavigationItem(
              icon: Icons.pie_chart_outline_rounded,
              label: 'Budgets',
              selected: selectedIndex == 1,
              onTap: () => onNavigate(1),
            ),
            _DrawerNavigationItem(
              icon: Icons.savings_outlined,
              label: 'Savings Goals',
              selected: selectedIndex == 2,
              onTap: () => onNavigate(2),
            ),
            _DrawerNavigationItem(
              icon: Icons.person_outline,
              label: 'Profile & Settings',
              selected: selectedIndex == 3,
              onTap: () => onNavigate(3),
            ),
            _DrawerNavigationItem(
              icon: Icons.swap_horiz_rounded,
              label: 'Currency Converter',
              selected: false,
              onTap: () => onOpenTool(FinanceTool.converter),
            ),
            _DrawerNavigationItem(
              icon: Icons.ios_share_rounded,
              label: 'Export Report',
              selected: false,
              onTap: () => onOpenTool(FinanceTool.report),
            ),
            const Divider(height: 32),
            const ListTile(
              leading: Icon(Icons.lock_outline, color: Color(0xFF22C55E)),
              title: Text('Your data is protected'),
              subtitle: Text('Only your verified account can access its data.'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                if (Firebase.apps.isNotEmpty) {
                  await FirebaseAuth.instance.signOut();
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavigationItem extends StatelessWidget {
  const _DrawerNavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFFF59E0B) : const Color(0xFF475569),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFFF59E0B) : const Color(0xFF0F172A),
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFFFF4E8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final BalanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = formatCurrency(summary.total);
    // Shrink the number so a very large balance never overflows the card.
    final balanceFontSize = _amountFontSize(total.length, base: 44, min: 24);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL BALANCE',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                total,
                style: TextStyle(
                  fontSize: balanceFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  summary.isPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 6),
                Text(
                  '${summary.deltaPercent.toStringAsFixed(1)}% this month',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
    // Pick ONE font size for all stat cards based on the longest amount, so a
    // huge Income value shrinks both cards equally and they always keep the
    // same height.
    var longest = 0;
    for (final stat in stats) {
      final length = formatCurrency(stat.amount).length;
      if (length > longest) longest = length;
    }
    final amountFontSize = _amountFontSize(longest);
    return Row(
      children: [
        for (int i = 0; i < stats.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == stats.length - 1 ? 0 : 12),
              child: _StatCard(data: stats[i], amountFontSize: amountFontSize),
            ),
          ),
      ],
    );
  }
}

// Maps a formatted amount's character length to a font size, with a floor, so
// long numbers automatically render smaller instead of overflowing.
double _amountFontSize(int length, {double base = 22, double min = 14}) {
  if (length <= 10) return base;
  final size = base - ((length - 10) * 1.5).clamp(0, 20);
  return size < min ? min : size;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data, required this.amountFontSize});
  final StatCardData data;
  final double amountFontSize;

  @override
  Widget build(BuildContext context) {
    final color = data.isPositive
        ? const Color(0xFF16A34A)
        : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fixed-height box + FittedBox keeps both cards the same height even
          // when one amount is much longer than the other.
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatCurrency(data.amount),
                style: TextStyle(
                  fontSize: amountFontSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTrailingPressed,
  });
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (trailing != null)
          TextButton(
            onPressed: onTrailingPressed ?? () {},
            child: Text(
              trailing!,
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.showFab,
  });
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
          Expanded(
            child: _NavBarItem(
              icon: Icons.home_filled,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _NavBarItem(
              icon: Icons.account_balance_wallet,
              label: 'Budgets',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            width: showFab ? 40 : 0,
          ),
          Expanded(
            child: _NavBarItem(
              icon: Icons.savings,
              label: 'Savings',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
          Expanded(
            child: _NavBarItem(
              icon: Icons.person,
              label: 'Profile',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFFF59E0B)
        : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// A slim status strip shown at the top of the body when the user's records are
// offline (served from the local cache) or have writes still waiting to sync.
// Hidden entirely when fully synced so it never distracts the user.
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.synced) return const SizedBox.shrink();

    final offline = status == SyncStatus.offline;
    return Container(
      width: double.infinity,
      color: offline ? const Color(0xFFFFF7ED) : const Color(0xFFFFFCE8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            offline ? Icons.cloud_off_rounded : Icons.cloud_sync_outlined,
            size: 16,
            color: offline ? const Color(0xFFF97316) : const Color(0xFFCA8A04),
          ),
          const SizedBox(width: 8),
          Text(
            offline ? 'Offline — changes saved locally' : 'Syncing…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: offline
                  ? const Color(0xFFF97316)
                  : const Color(0xFFCA8A04),
            ),
          ),
        ],
      ),
    );
  }
}
