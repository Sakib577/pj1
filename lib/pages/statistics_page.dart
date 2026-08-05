import 'package:flutter/material.dart';

import '../analytics/models/analytics_models.dart';
import '../analytics/models/stat_models.dart';
import '../analytics/providers/statistics_controller.dart';
import '../analytics/services/analytics_service.dart';
import '../analytics/utils/date_ranges.dart';
import '../models/finance_models.dart';
import '../analytics/widgets/budget_progress_card.dart';
import '../analytics/widgets/cash_flow_forecast_card.dart';
import '../analytics/widgets/cash_flow_summary_card.dart';
import '../analytics/widgets/category_donut_card.dart';
import '../analytics/widgets/date_range_picker.dart';
import '../analytics/widgets/debt_ratio_card.dart';
import '../analytics/widgets/income_analytics_card.dart';
import '../analytics/widgets/monthly_overview_card.dart';
import '../analytics/widgets/next_month_estimate_card.dart';
import '../analytics/widgets/spending_pattern_card.dart';
import '../analytics/widgets/top_expenses_card.dart';
import '../analytics/widgets/trends_card.dart';
import '../analytics/widgets/balance_history_card.dart';
import '../state/finance_app_state.dart';

const _service = AnalyticsService();

/// The statistics screen: a composable Scaffold placing all 20 statistic cards.
/// Owns a [StatisticsController] bound to the app's [FinanceAppState].
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final selected = await showStatisticsRangePicker(context);
    if (selected != null) {
      _controller?.setRange(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resolve the app scope in build (never initState) so inherited-widget
    // concerns are respected; the controller is created once on first build.
    final controller =
        _controller ??= StatisticsController(state: FinanceAppScope.of(context));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bundle = controller.bundle;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: 72,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              'Statistics',
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
                label: Text(bundle.window.label),
              ),
            ],
          ),
          body: _StatisticsGrid(
            bundle: bundle,
            state: FinanceAppScope.of(context),
            onRangeTap: _pickRange,
          ),
        );
      },
    );
  }
}

/// Lays out the statistic cards in a responsive column/grid.
class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({
    required this.bundle,
    required this.state,
    required this.onRangeTap,
  });

  final StatisticsBundle bundle;
  final FinanceAppState state;
  final VoidCallback onRangeTap;

  @override
  Widget build(BuildContext context) {
    final cards = _buildCards(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 900
            ? 2
            : maxWidth >= 600
            ? 2
            : 1;
        const gap = 16.0;
        final childWidth = (maxWidth - (gap * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(gap),
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards)
                SizedBox(width: childWidth, child: card),
            ],
          ),
        );
      },
    );
  }
  List<Widget> _buildCards(BuildContext context) {
    final window = bundle.window;
    final txns = state.transactions;
    final cards = <Widget>[];
    void add(Widget card) => cards.add(card);

    // 1. Trends (balance / spending / cash flow / income vs expense /
    //    savings / history) chosen from a dropdown.
    add(
      TrendsCard(
        balanceTrend: bundle.balanceTrend,
        defaultGranularity: _defaultGranularity(window),
        spendingByGranularity: {
          BucketGranularity.daily: _firstPoints(
            _service.calculateSpendingTrend(
              txns,
              window,
              BucketGranularity.daily,
            ),
          ),
          BucketGranularity.weekly: _firstPoints(
            _service.calculateSpendingTrend(
              txns,
              window,
              BucketGranularity.weekly,
            ),
          ),
          BucketGranularity.monthly: _firstPoints(
            _service.calculateSpendingTrend(
              txns,
              window,
              BucketGranularity.monthly,
            ),
          ),
        },
        cashFlowBars: _service.calculateIncomeExpenseComparison(
          txns,
          window,
          BucketGranularity.daily,
        ),
        incomeExpenseByGranularity: {
          BucketGranularity.daily: _service.calculateIncomeExpenseComparison(
            txns,
            window,
            BucketGranularity.daily,
          ),
          BucketGranularity.weekly: _service.calculateIncomeExpenseComparison(
            txns,
            window,
            BucketGranularity.weekly,
          ),
          BucketGranularity.monthly: _service.calculateIncomeExpenseComparison(
            txns,
            window,
            BucketGranularity.monthly,
          ),
        },
        savingsSeries: bundle.savingsTrend,
        savingsGoal: _totalSavingsGoal(state),
        historyByRange: {
          BalanceHistoryRange.week: _balancePoints(txns, 7),
          BalanceHistoryRange.month: _balancePoints(txns, 30),
          BalanceHistoryRange.threeMonths: _balancePoints(txns, 90),
          BalanceHistoryRange.sixMonths: _balancePoints(txns, 180),
          BalanceHistoryRange.year: _balancePoints(txns, 365),
        },
        rangeLabel: window.label,
      ),
    );

    // 2. Cash Flow Summary
    add(
      CashFlowSummaryCard(
        summary: bundle.cashFlow,
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 3. Spending by Categories
    add(
      CategoryDonutCard(
        categories: bundle.categorySpending,
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 4. Spending Pattern (hourly/daily/weekly/monthly)
    add(
      SpendingPatternCard(
        hourly: bundle.hourlyPattern,
        daily: _firstPoints(
          _service.calculateSpendingTrend(txns, window, BucketGranularity.daily),
        ),
        weekly: bundle.weeklyPattern,
        monthly: _firstPoints(
          _service.calculateSpendingTrend(
            txns,
            window,
            BucketGranularity.monthly,
          ),
        ),
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 5. Top Expenses
    add(
      TopExpensesCard(
        expenses: bundle.topExpenses,
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 6. Debt-to-Income
    if (bundle.debtRatio != null) {
      add(
        DebtRatioCard(
          gauge: bundle.debtRatio!,
          rangeLabel: window.label,
          onRangeTap: onRangeTap,
        ),
      );
    }

    // 7. Monthly Overview
    add(
      MonthlyOverviewCard(
        overview: bundle.monthlyOverview,
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 8. Income Analytics
    add(
      IncomeAnalyticsCard(
        analytics: bundle.incomeAnalytics,
        rangeLabel: window.label,
        onRangeTap: onRangeTap,
      ),
    );

    // 9. Budget Progress
    add(
      BudgetProgressCard(
        progress: bundle.budgetProgress,
        rangeLabel: window.label,
      ),
    );

    // 10. Cash Flow Forecast
    add(
      CashFlowForecastCard(
        points: bundle.cashFlowForecast,
        rangeLabel: window.label,
      ),
    );

    // 11. Estimated Next Month's Expense
    final estimate = _service.estimateNextMonthExpense(
      txns,
      state.plannedPayments,
    );
    if (estimate != null) {
      add(NextMonthEstimateCard(estimate: estimate));
    }

    return cards;
  }

  List<SeriesPoint> _firstPoints(List<TrendSeries> series) =>
      series.isEmpty ? const <SeriesPoint>[] : series.first.points;

  /// Picks a bucket size that produces enough points to draw a full line for
  /// the given window (mirrors `calculateSavingsTrend`).
  BucketGranularity _defaultGranularity(PeriodWindow window) {
    final days = window.end.difference(window.start).inDays + 1;
    if (days <= 45) return BucketGranularity.daily;
    if (days <= 180) return BucketGranularity.weekly;
    return BucketGranularity.monthly;
  }

  List<SeriesPoint> _balancePoints(List<TransactionItem> txns, int days) {
    final now = DateTime.now();
    final window = PeriodWindow(
      start: now.subtract(Duration(days: days - 1)),
      end: now,
      previousStart: now,
      previousEnd: now,
      label: '$days days',
    );
    return _service.calculateBalance(txns, window).points;
  }

  double _totalSavingsGoal(FinanceAppState state) =>
      state.savingsGoals.fold<double>(0, (s, g) => s + g.target);
}