import 'package:flutter/material.dart';

import '../models/finance_models.dart';

// Central place for demo data used across the app.
// Later you can replace values here with API/database results.
class AppMockData {
  // Home tab summary values.
  static const balance = BalanceSummary(
    total: 4250.80,
    deltaPercent: 12.5,
    isPositive: true,
  );

  static const stats = [
    StatCardData(
      label: 'Income',
      amount: 2840.00,
      icon: Icons.arrow_downward,
      color: Color(0xFF22C55E),
      isPositive: true,
    ),
    StatCardData(
      label: 'Expenses',
      amount: 1589.20,
      icon: Icons.arrow_upward,
      color: Color(0xFFF97316),
      isPositive: false,
    ),
  ];

  // Category options for dashboard and forms.
  static const categories = [
    CategoryItem(label: 'Food', icon: Icons.restaurant, color: Color(0xFFF59E0B)),
    CategoryItem(label: 'Transport', icon: Icons.directions_car, color: Color(0xFF3B82F6)),
    CategoryItem(label: 'Utilities', icon: Icons.bolt, color: Color(0xFF8B5CF6)),
    CategoryItem(label: 'Shopping', icon: Icons.shopping_bag_outlined, color: Color(0xFFEC4899)),
    CategoryItem(label: 'Health', icon: Icons.health_and_safety_outlined, color: Color(0xFF22C55E)),
    CategoryItem(label: 'Travel', icon: Icons.flight_takeoff, color: Color(0xFF0EA5E9)),
    CategoryItem(label: 'Subscriptions', icon: Icons.subscriptions_outlined, color: Color(0xFF6366F1)),
    CategoryItem(label: 'Education', icon: Icons.school_outlined, color: Color(0xFFEF4444)),
  ];

  static const transactions = [
    TransactionItem(
      title: 'Starbucks Coffee',
      subtitle: 'Today, 10:24 AM',
      amount: 4.50,
      icon: Icons.restaurant,
      iconColor: Color(0xFFF59E0B),
      negative: true,
    ),
    TransactionItem(
      title: 'Uber Ride',
      subtitle: 'Yesterday, 8:15 PM',
      amount: 12.80,
      icon: Icons.directions_car,
      iconColor: Color(0xFF3B82F6),
      negative: true,
    ),
  ];

  static const plannedPayments = [
    PlannedPayment(
      title: 'Rent Payment',
      due: 'Due Oct 28, 2023',
      amount: 1200.00,
      icon: Icons.receipt_long,
      background: Color(0xFFFEEFE0),
      tagText: 'In 3 days',
    ),
    PlannedPayment(
      title: 'Streaming Service',
      due: 'Due Nov 01, 2023',
      amount: 15.99,
      icon: Icons.subscriptions_outlined,
      background: Color(0xFFE8F0FF),
      tagText: 'Monthly',
    ),
  ];

  static const budgetCategories = [
    BudgetCategory(
      label: 'Food & Dining',
      spent: 450,
      limit: 600,
      daysLeft: 12,
      status: 'Near limit',
      statusColor: Color(0xFFE36306),
      icon: Icons.restaurant,
      iconBg: Color(0xFFFFF4E8),
    ),
    BudgetCategory(
      label: 'Shopping',
      spent: 120,
      limit: 400,
      daysLeft: 18,
      status: 'On track',
      statusColor: Color(0xFF16A34A),
      icon: Icons.shopping_bag_outlined,
      iconBg: Color(0xFFFFF4E8),
    ),
    BudgetCategory(
      label: 'Transport',
      spent: 280,
      limit: 300,
      daysLeft: 5,
      status: 'Critical',
      statusColor: Color(0xFFEF4444),
      icon: Icons.directions_car,
      iconBg: Color(0xFFFFF4E8),
    ),
    BudgetCategory(
      label: 'Entertainment',
      spent: 50,
      limit: 150,
      daysLeft: 22,
      status: 'Healthy',
      statusColor: Color(0xFF16A34A),
      icon: Icons.movie_outlined,
      iconBg: Color(0xFFFFF4E8),
    ),
  ];

  static const savingsOverview = SavingsOverview(
    totalSavings: 13000,
    progress: 0.72,
    message: "You've saved \$1,200 more than last month. Keep it up!",
  );

  static const savingsGoals = [
    SavingsGoal(
      title: 'New MacBook Pro',
      subtitle: 'Target: Dec 20, 2026 (45 days left)',
      current: 1800,
      target: 2400,
      icon: Icons.laptop_mac_outlined,
      iconColor: Color(0xFFF59E0B),
      iconBg: Color(0xFFFFF4E8),
      status: 'ON TRACK',
      statusColor: Color(0xFF16A34A),
      statusBg: Color(0xFFDCFCE7),
    ),
    SavingsGoal(
      title: 'Summer Vacation',
      subtitle: 'Target: Jun 15, 2027 (222 days left)',
      current: 1200,
      target: 5000,
      icon: Icons.beach_access_outlined,
      iconColor: Color(0xFF3B82F6),
      iconBg: Color(0xFFDBEAFE),
      status: 'BEHIND',
      statusColor: Color(0xFFB45309),
      statusBg: Color(0xFFFEF3C7),
    ),
    SavingsGoal(
      title: 'Emergency Fund',
      subtitle: 'Target reached on Oct 12, 2026',
      current: 10000,
      target: 10000,
      icon: Icons.shield_outlined,
      iconColor: Color(0xFF22C55E),
      iconBg: Color(0xFFDCFCE7),
      status: 'COMPLETED',
      statusColor: Color(0xFFD97706),
      statusBg: Color(0xFFFFF4E8),
    ),
  ];

  // Quick categories shown in Add Transaction page.
  static const addTransactionCategories = [
    CategoryItem(label: 'Food', icon: Icons.restaurant, color: Color(0xFFF59E0B)),
    CategoryItem(label: 'Transport', icon: Icons.directions_car, color: Color(0xFF3B82F6)),
    CategoryItem(label: 'Shopping', icon: Icons.shopping_bag_outlined, color: Color(0xFF9CA3AF)),
    CategoryItem(label: 'More', icon: Icons.grid_view_rounded, color: Color(0xFF9CA3AF)),
  ];
}

