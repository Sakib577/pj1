import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/models/finance_models.dart';

void main() {
  group('budgetAlertStatus', () {
    test('is healthy below 70% of the limit', () {
      expect(budgetAlertStatus(0, 1000), 'Healthy');
      expect(budgetAlertStatus(699, 1000), 'Healthy');
    });

    test('is risky at 70% or more of the limit', () {
      expect(budgetAlertStatus(700, 1000), 'Risky');
      expect(budgetAlertStatus(850, 1000), 'Risky');
      expect(budgetAlertStatus(999, 1000), 'Risky');
    });

    test('is overspent at or beyond the limit', () {
      expect(budgetAlertStatus(1000, 1000), 'Overspent');
      expect(budgetAlertStatus(1250, 1000), 'Overspent');
    });

    test('is healthy when the limit is not positive', () {
      expect(budgetAlertStatus(500, 0), 'Healthy');
      expect(budgetAlertStatus(500, -10), 'Healthy');
    });
  });

  test('BudgetCategory persists and restores alertStatus', () {
    final original = BudgetCategory(
      id: 'b1',
      label: 'Food',
      spent: 0,
      limit: 1000,
      daysLeft: 10,
      status: 'Healthy',
      statusColor: const Color(0xFF16A34A),
      icon: Icons.account_balance_wallet_outlined,
      iconBg: const Color(0xFFFFF4E8),
      startDate: DateTime(2026, 1, 1),
      alertStatus: 'Risky',
    );
    final restored = BudgetCategory.fromMap(
      original.id,
      original.toMap(),
    );
    expect(restored.alertStatus, 'Risky');

    final cleared = original.copyWith(clearAlertStatus: true);
    expect(cleared.alertStatus, isNull);
  });
}
