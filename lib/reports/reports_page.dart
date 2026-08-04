import 'package:flutter/material.dart';

import '../analytics/utils/date_ranges.dart';
import '../state/finance_app_state.dart';
import '../utils/currency_formatters.dart';
import 'models/report_models.dart';
import 'services/report_service.dart';
import 'widgets/report_line_list.dart';
import 'widgets/statement_section_card.dart';

const _service = ReportService();

/// Reports page: lists every accounting/economic report and opens a detail view
/// for the selected report. Pure read-only; never writes to Firestore.
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _startDate = _defaultStart();
  DateTime _endDate = DateTime.now();
  DateRange _range = const DateRange.preset(DateRangePreset.thisMonth);

  static DateTime _defaultStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _pickRange() async {
    final selected = await showModalBottomSheet<DateRange>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report period',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final preset in const [
                        DateRangePreset.today,
                        DateRangePreset.last7,
                        DateRangePreset.last30,
                        DateRangePreset.thisMonth,
                        DateRangePreset.lastMonth,
                        DateRangePreset.thisYear,
                        DateRangePreset.all,
                      ])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.date_range_outlined),
                          title: Text(DateRange.preset(preset).label),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(sheetContext).pop(
                            DateRange.preset(preset),
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Custom range'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final now = DateTime.now();
                          final navigator = Navigator.of(sheetContext);
                          final picked = await showDateRangePicker(
                            context: sheetContext,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 1),
                            currentDate: now,
                            helpText: 'Select custom range',
                            saveText: 'Apply',
                          );
                          if (picked != null) {
                            navigator.pop(
                              DateRange.custom(
                                start: picked.start,
                                end: picked.end,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _range = selected;
      final now = DateTime.now();
      final window = buildWindowFromDateRange(now: now, range: selected);
      _startDate = window.start;
      _endDate = window.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = FinanceAppScope.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Reports',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: Text(_range.label),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _HeroCard(rangeLabel: _range.label),
          const SizedBox(height: 16),
          _ReportCard(
            kind: ReportKind.cashFlowStatement,
            summary: _cashFlowSummary(state),
            onTap: () => _openReport(state, ReportKind.cashFlowStatement),
          ),
          _ReportCard(
            kind: ReportKind.incomeStatement,
            summary: _incomeSummary(state),
            onTap: () => _openReport(state, ReportKind.incomeStatement),
          ),
          _ReportCard(
            kind: ReportKind.balanceSheet,
            summary: _balanceSheetSummary(state),
            onTap: () => _openReport(state, ReportKind.balanceSheet),
          ),
          _ReportCard(
            kind: ReportKind.budgetVsActual,
            summary: _budgetSummary(state),
            onTap: () => _openReport(state, ReportKind.budgetVsActual),
          ),
          _ReportCard(
            kind: ReportKind.debt,
            summary: _debtSummary(state),
            onTap: () => _openReport(state, ReportKind.debt),
          ),
          _ReportCard(
            kind: ReportKind.savingsNetWorth,
            summary: _savingsSummary(state),
            onTap: () => _openReport(state, ReportKind.savingsNetWorth),
          ),
          const SizedBox(height: 8),
          Text(
            'Amounts are converted to your display currency '
            '(${state.currencyCode.toUpperCase()}).',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _openReport(FinanceAppState state, ReportKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ReportDetailPage(
          kind: kind,
          rangeLabel: _range.label,
          start: _startDate,
          end: _endDate,
        ),
      ),
    );
  }

  // ----- Summary strings for the list cards -----

  String _cashFlowSummary(FinanceAppState state) {
    final report = _service.calculateCashFlowStatement(
      state.transactions,
      _startDate,
      _endDate,
    );
    final net = formatCurrency(report.netCashFlow);
    return 'Net cash flow: ${report.netCashFlow < 0 ? '-' : '+'}$net';
  }

  String _incomeSummary(FinanceAppState state) {
    final report = _service.calculateIncomeStatement(
      state.transactions,
      _startDate,
      _endDate,
    );
    return 'Net ${report.netIncome < 0 ? 'loss' : 'profit'}: '
        '${formatCurrency(report.netIncome.abs())}';
  }

  String _balanceSheetSummary(FinanceAppState state) {
    final report = _service.calculateBalanceSheet(
      state.transactions,
      state.debts,
      state.savingsGoals,
    );
    return 'Net worth: ${formatCurrency(report.netWorth)}';
  }

  String _budgetSummary(FinanceAppState state) {
    final report = _service.calculateBudgetVsActual(
      state.budgets,
      state.transactions,
    );
    if (report.rows.isEmpty) return 'No budgets set';
    return 'Budget: ${formatCurrency(report.totalBudget)} spent '
        '${formatCurrency(report.totalActual)}';
  }

  String _debtSummary(FinanceAppState state) {
    final report = _service.calculateDebtReport(state.debts);
    if (report.totalBorrowed == 0 && report.totalLent == 0) {
      return 'No debts recorded';
    }
    return 'Owed: ${formatCurrency(report.totalBorrowed)} · Owed to you: '
        '${formatCurrency(report.totalLent)}';
  }

  String _savingsSummary(FinanceAppState state) {
    final report = _service.calculateSavingsNetWorth(
      state.savingsGoals,
      state.transactions,
      _startDate,
      _endDate,
    );
    if (report.goals.isEmpty) return 'No savings goals yet';
    return 'Saved ${formatCurrency(report.totalSaved)} of '
        '${formatCurrency(report.totalTarget)}';
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F59E0B),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Accounting Reports',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Formal statements from your transactions: cash flow by activity, '
            'profit & loss, net worth, budget variance, debt and savings.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Period: $rangeLabel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.kind,
    required this.summary,
    required this.onTap,
  });

  final ReportKind kind;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  kind.icon,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kind.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full read-only detail view for one report.
class _ReportDetailPage extends StatelessWidget {
  const _ReportDetailPage({
    required this.kind,
    required this.rangeLabel,
    required this.start,
    required this.end,
  });

  final ReportKind kind;
  final String rangeLabel;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = FinanceAppScope.of(context);
    final txns = state.transactions;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 72,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          kind.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          _PeriodHeader(rangeLabel: rangeLabel),
          const SizedBox(height: 16),
          switch (kind) {
            ReportKind.cashFlowStatement => _CashFlowStatementView(
              report: _service.calculateCashFlowStatement(txns, start, end),
            ),
            ReportKind.incomeStatement => _IncomeStatementView(
              report: _service.calculateIncomeStatement(txns, start, end),
            ),
            ReportKind.balanceSheet => _BalanceSheetView(
              report: _service.calculateBalanceSheet(
                txns,
                state.debts,
                state.savingsGoals,
              ),
            ),
            ReportKind.budgetVsActual => _BudgetVsActualView(
              report: _service.calculateBudgetVsActual(
                state.budgets,
                txns,
              ),
            ),
            ReportKind.debt => _DebtReportView(
              report: _service.calculateDebtReport(state.debts),
            ),
            ReportKind.savingsNetWorth => _SavingsNetWorthView(
              report: _service.calculateSavingsNetWorth(
                state.savingsGoals,
                txns,
                start,
                end,
              ),
            ),
          },
        ],
      ),
    );
  }
}

class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Period: $rangeLabel',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report detail bodies
// ---------------------------------------------------------------------------

class _CashFlowStatementView extends StatelessWidget {
  const _CashFlowStatementView({required this.report});

  final CashFlowStatementReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBanner(
          title: 'Net cash flow',
          value: _signed(report.netCashFlow),
          color: report.netCashFlow < 0
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        StatementSectionCard(section: report.operating),
        const SizedBox(height: 12),
        StatementSectionCard(section: report.investing),
        const SizedBox(height: 12),
        StatementSectionCard(section: report.financing),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CashRow(
                  label: 'Cash at beginning of period',
                  value: formatCurrency(report.beginningCash),
                ),
                const SizedBox(height: 8),
                _CashRow(
                  label: 'Net increase (decrease) in cash',
                  value: _signed(report.netCashFlow),
                  valueColor: report.netCashFlow < 0
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF16A34A),
                ),
                const Divider(height: 24),
                _CashRow(
                  label: 'Cash at end of period',
                  value: formatCurrency(report.endingCash),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _signed(double value) {
    final formatted = formatCurrency(value.abs());
    if (value == 0) return formatted;
    return value < 0 ? '-$formatted' : '+$formatted';
  }
}

class _IncomeStatementView extends StatelessWidget {
  const _IncomeStatementView({required this.report});

  final IncomeStatementReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profit = report.netIncome >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBanner(
          title: profit ? 'Net profit' : 'Net loss',
          value: formatCurrency(report.netIncome.abs()),
          color: profit ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          subtitle: 'Margin: ${report.grossMargin.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Income',
          icon: Icons.arrow_downward,
          color: const Color(0xFF16A34A),
          child: ReportLineList(
            items: report.incomeItems,
            emptyMessage: 'No income recorded',
          ),
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Expenses',
          icon: Icons.arrow_upward,
          color: const Color(0xFFDC2626),
          child: ReportLineList(
            items: report.expenseItems,
            emptyMessage: 'No expenses recorded',
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CashRow(
                  label: 'Total income',
                  value: formatCurrency(report.totalIncome),
                  valueColor: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 8),
                _CashRow(
                  label: 'Total expenses',
                  value: formatCurrency(report.totalExpenses),
                  valueColor: const Color(0xFFDC2626),
                ),
                const Divider(height: 24),
                _CashRow(
                  label: profit ? 'Net income' : 'Net loss',
                  value: formatCurrency(report.netIncome.abs()),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceSheetView extends StatelessWidget {
  const _BalanceSheetView({required this.report});

  final BalanceSheetReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBanner(
          title: 'Net worth',
          value: formatCurrency(report.netWorth),
          color: report.netWorth < 0
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Assets',
          icon: Icons.savings_rounded,
          color: const Color(0xFF16A34A),
          child: ReportLineList(
            items: report.assetItems,
            emptyMessage: 'No assets',
          ),
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Liabilities',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFFDC2626),
          child: ReportLineList(
            items: report.liabilityItems,
            emptyMessage: 'No liabilities — you owe nothing',
          ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
          ),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CashRow(
                  label: 'Total assets',
                  value: formatCurrency(report.totalAssets),
                  valueColor: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 8),
                _CashRow(
                  label: 'Total liabilities',
                  value: formatCurrency(report.totalLiabilities),
                  valueColor: const Color(0xFFDC2626),
                ),
                const Divider(height: 24),
                _CashRow(
                  label: 'Net worth',
                  value: formatCurrency(report.netWorth),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetVsActualView extends StatelessWidget {
  const _BudgetVsActualView({required this.report});

  final BudgetVsActualReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.rows.isEmpty) {
      return const _EmptyCard(
        icon: Icons.donut_large_rounded,
        title: 'No budgets set',
        subtitle:
            'Create a budget in the Budget tab to compare your plan with actual spending.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CashRow(
                  label: 'Total budget',
                  value: formatCurrency(report.totalBudget),
                ),
                const SizedBox(height: 8),
                _CashRow(
                  label: 'Actual spend',
                  value: formatCurrency(report.totalActual),
                  valueColor: const Color(0xFFDC2626),
                ),
                const Divider(height: 24),
                _CashRow(
                  label: 'Remaining',
                  value: formatCurrency(report.totalVariance),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final row in report.rows) ...[
          _BudgetVarianceRowView(row: row),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DebtReportView extends StatelessWidget {
  const _DebtReportView({required this.report});

  final DebtReport report;

  @override
  Widget build(BuildContext context) {
    if (report.totalBorrowed == 0 && report.totalLent == 0) {
      return const _EmptyCard(
        icon: Icons.handshake_rounded,
        title: 'No debts recorded',
        subtitle:
            'Debts you borrow or lend appear on your balance sheet automatically.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBanner(
          title: 'Net debt position',
          value: formatCurrency(report.netPosition),
          color: report.netPosition < 0
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
          subtitle: 'Owed: ${formatCurrency(report.totalBorrowed)} · '
              'Owed to you: ${formatCurrency(report.totalLent)}',
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Money you owe (borrowed)',
          icon: Icons.arrow_upward,
          color: const Color(0xFFDC2626),
          child: ReportLineList(
            items: report.borrowedActive,
            emptyMessage: 'No active borrowings',
          ),
        ),
        const SizedBox(height: 12),
        _StatementCard(
          title: 'Money owed to you (lent)',
          icon: Icons.arrow_downward,
          color: const Color(0xFF16A34A),
          child: ReportLineList(
            items: report.lentActive,
            emptyMessage: 'No active loans to others',
          ),
        ),
        if (report.borrowedSettled.isNotEmpty || report.lentSettled.isNotEmpty) ...[
          const SizedBox(height: 12),
          _StatementCard(
            title: 'Settled',
            icon: Icons.check_circle_outline_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            child: Column(
              children: [
                if (report.borrowedSettled.isNotEmpty)
                  ReportLineList(
                    items: report.borrowedSettled,
                    emptyMessage: '',
                  ),
                if (report.lentSettled.isNotEmpty) ...[
                  const Divider(height: 1),
                  ReportLineList(
                    items: report.lentSettled,
                    emptyMessage: '',
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SavingsNetWorthView extends StatelessWidget {
  const _SavingsNetWorthView({required this.report});

  final SavingsNetWorthReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (report.goals.isEmpty && report.totalSaved == 0) {
      return const _EmptyCard(
        icon: Icons.savings_rounded,
        title: 'No savings goals yet',
        subtitle:
            'Create savings goals to track how much of your income you keep.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryBanner(
          title: 'Total saved',
          value: formatCurrency(report.totalSaved),
          color: const Color(0xFF16A34A),
          subtitle:
              'Savings rate: ${(report.savingsRate * 100).toStringAsFixed(0)}%',
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
          ),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _CashRow(
                  label: 'Contributions this period',
                  value: formatCurrency(report.periodContribution),
                  valueColor: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 8),
                _CashRow(
                  label: 'Withdrawals this period',
                  value: formatCurrency(report.periodWithdrawal),
                  valueColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final goal in report.goals) ...[
          _SavingsGoalCard(goal: goal),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared building blocks
// ---------------------------------------------------------------------------

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class _CashRow extends StatelessWidget {
  const _CashRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BudgetVarianceRowView extends StatelessWidget {
  const _BudgetVarianceRowView({required this.row});

  final BudgetVarianceRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final over = row.actual > row.budget;
    final color = over ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row.category,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  over ? 'Over budget' : 'On track',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: row.ratio,
                minHeight: 8,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniValue(
                    label: 'Budget',
                    value: formatCurrency(row.budget),
                  ),
                ),
                Expanded(
                  child: _MiniValue(
                    label: 'Actual',
                    value: formatCurrency(row.actual),
                    valueColor: const Color(0xFFDC2626),
                  ),
                ),
                Expanded(
                  child: _MiniValue(
                    label: 'Remaining',
                    value: formatCurrency(row.variance),
                    valueColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({required this.goal});

  final SavingsGoalRow goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = goal.progress >= 1;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(goal.progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: complete
                        ? const Color(0xFF16A34A)
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                color: complete
                    ? const Color(0xFF16A34A)
                    : theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MiniValue(
                    label: 'Saved',
                    value: formatCurrency(goal.current),
                    valueColor: const Color(0xFF16A34A),
                  ),
                ),
                Expanded(
                  child: _MiniValue(
                    label: 'Target',
                    value: formatCurrency(goal.target),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}