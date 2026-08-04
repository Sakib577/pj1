import '../models/analytics_models.dart';
import '../models/stat_models.dart';

/// Derived, stable lookups on a [StatisticsBundle]. Keeping these as small pure
/// getters lets dependent widgets rebuild narrowly instead of re-reading the
/// whole bundle.
class StatSelectors {
  const StatSelectors(this.bundle);

  final StatisticsBundle bundle;

  TrendSeries get balanceTrend => bundle.balanceTrend;
  CashFlowSummary get cashFlow => bundle.cashFlow;
  List<CategoryStat> get categorySpending => bundle.categorySpending;
  List<TopExpense> get topExpenses => bundle.topExpenses;
  GaugeResult? get debtRatio => bundle.debtRatio;
  List<GroupedBar> get incomeExpenseComparison => bundle.incomeExpenseComparison;
  MonthlyOverview get monthlyOverview => bundle.monthlyOverview;
  List<FinancialHealthMetric> get financialHealth => bundle.financialHealth;
  CategoryAnalytics get categoryAnalytics => bundle.categoryAnalytics;
  IncomeAnalytics get incomeAnalytics => bundle.incomeAnalytics;
  List<SeriesPoint> get weeklyPattern => bundle.weeklyPattern;
  List<SeriesPoint> get hourlyPattern => bundle.hourlyPattern;
  List<BudgetProgress> get budgetProgress => bundle.budgetProgress;
  List<TrendSeries> get savingsTrend => bundle.savingsTrend;
  List<ForecastPoint> get cashFlowForecast => bundle.cashFlowForecast;
  List<TrendSeries> get balanceHistory => bundle.balanceHistory;
}