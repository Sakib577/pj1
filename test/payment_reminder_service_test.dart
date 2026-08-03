import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:pj1/models/finance_models.dart';
import 'package:pj1/services/payment_reminder_service.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    // getLocation reads from the in-memory database. In some test VMs the
    // database hasn't fully loaded, so fall back to constructing UTC manually.
    try {
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {
      tz.setLocalLocation(tz.TZDateTime.utc(2026, 1, 1).location);
    }
  });

  test('plans two-day, one-day, and due-day reminders', () {
    final payment = PlannedPayment(
      id: 'reminder-test',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime.utc(2026, 8, 3),
    );

    final plans = PaymentReminderService.buildReminderPlan(
      payment,
      now: tz.TZDateTime.utc(2026, 8, 1, 8),
    );

    expect(plans.map((plan) => plan.daysBefore), [2, 1, 0]);
    expect(plans.map((plan) => plan.title), [
      'Payment coming up in 2 days',
      'Payment coming up in 1 day',
      'Payment due today',
    ]);
    expect(plans.map((plan) => plan.body), [
      'Rent is due in 2 days · -\$100',
      'Rent is due in 1 day · -\$100',
      'Rent · -\$100',
    ]);
  });

  test('does not include reminder dates that have already passed', () {
    final payment = PlannedPayment(
      id: 'reminder-test-2',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime.utc(2026, 8, 3),
    );

    final plans = PaymentReminderService.buildReminderPlan(
      payment,
      now: tz.TZDateTime.utc(2026, 8, 2, 10),
    );

    expect(plans.map((plan) => plan.daysBefore), [0]);
  });
}
