import '../../state/finance_app_state.dart';
import '../models/analytics_models.dart';
import '../models/stat_models.dart';
import '../services/analytics_service.dart';
import '../utils/date_ranges.dart';

/// Reads the raw data needed by the analytics engine straight from the app's
/// already-synced in-memory state. No new Firestore reads — the state is the
/// single source of truth and works offline.
class AnalyticsRepository {
  const AnalyticsRepository();

  final AnalyticsService _service = const AnalyticsService();

  /// Computes the full [StatisticsBundle] for a window against the current
  /// in-memory state.
  StatisticsBundle bundleFor(
    FinanceAppState state,
    PeriodWindow window, {
    BucketGranularity granularity = BucketGranularity.daily,
  }) {
    final transactions = state.transactions;
    final budgets = state.budgets;
    final debts = state.debts;
    final goals = state.savingsGoals;

    final daily = BucketGranularity.daily;
    return StatisticsBundle(
      window: window,
      balanceTrend: _service.calculateBalance(transactions, window),
      cashFlow: _service.calculateCashFlow(transactions, window),
      cashFlowTrend: _service.calculateCashFlowTrend(
        transactions,
        window,
        daily,
      ),
      categorySpending: _service.calculateCategorySpending(transactions, window),
      spendingTrend: _service.calculateSpendingTrend(
        transactions,
        window,
        daily,
      ),
      topExpenses: _service.calculateTopExpenses(transactions, window),
      debtRatio: _service.calculateDebtRatio(debts, _incomeFor(state, window)),
      incomeExpenseComparison: _service.calculateIncomeExpenseComparison(
        transactions,
        window,
        daily,
      ),
      monthlyOverview: _service.calculateMonthlyOverview(
        transactions,
        window,
        daily,
      ),
      financialHealth: _service.calculateFinancialHealth(
        transactions,
        window,
      ),
      categoryAnalytics: _service.calculateCategoryAnalytics(
        transactions,
        window,
      ),
      incomeAnalytics: _service.calculateIncomeAnalytics(transactions, window),
      weeklyPattern: _service.calculateWeeklyPattern(transactions, window),
      hourlyPattern: _service.calculateHourlyPattern(transactions, window),
      budgetProgress: _service.calculateBudgetProgress(
        budgets,
        transactions,
      ),
      savingsTrend: _service.calculateSavingsTrend(
        transactions,
        window,
        goals,
      ),
      cashFlowForecast: _service.calculateCashFlowForecast(
        transactions,
        window,
      ),
      balanceHistory: _service.calculateBalanceHistory(transactions, window),
    );
  }

  double _incomeFor(FinanceAppState state, PeriodWindow window) {
    return state.transactions
        .where(
          (t) =>
              !t.negative &&
              t.createdAt != null &&
              !t.createdAt!.isBefore(window.start) &&
              !t.createdAt!.isAfter(window.end.add(
                const Duration(days: 1),
              )),
        )
        .fold<double>(0, (s, t) => s + t.amount);
  }
}