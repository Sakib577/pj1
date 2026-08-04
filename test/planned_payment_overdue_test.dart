import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/models/finance_models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  // Simulates the PlannedPaymentCard label logic.
  String cardText(PlannedPayment payment, DateTime now) {
    final due = payment.currentDue(from: now);
    final today = _dateOnly(now);
    return switch (due.compareTo(today)) {
      < 0 => 'Overdue',
      0 => 'Due today',
      _ => 'Due ${due.year}-${due.month}-${due.day}',
    };
  }

  test('one-time payment is overdue the day after its date', () {
    final payment = PlannedPayment(
      id: 'o',
      title: 'Once',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.once,
    );
    expect(cardText(payment, DateTime(2026, 8, 1, 23, 59)), 'Due today');
    expect(cardText(payment, DateTime(2026, 8, 2, 0, 30)), 'Overdue');
  });

  test('monthly payment is overdue the day after its occurrence', () {
    final payment = PlannedPayment(
      id: 'm',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.monthly,
    );
    expect(cardText(payment, DateTime(2026, 8, 1, 12)), 'Due today');
    expect(cardText(payment, DateTime(2026, 8, 2, 0, 30)), 'Overdue');
    // Stays overdue until confirmed, does not roll to next month.
    expect(cardText(payment, DateTime(2026, 8, 20)), 'Overdue');
  });

  test('monthly payment shows next occurrence after confirmation', () {
    final payment = PlannedPayment(
      id: 'm2',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.monthly,
      lastConfirmedDate: DateTime(2026, 8, 1),
    );
    expect(cardText(payment, DateTime(2026, 8, 2)), 'Due 2026-9-1');
  });

  test('confirming a repeating payment advances it and stops the prompt', () {
    // Payment is due today (Aug 5) and prompts for confirmation.
    final payment = PlannedPayment(
      id: 'm3',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 5),
      repeat: RepeatFrequency.monthly,
    );
    expect(payment.currentDue(from: DateTime(2026, 8, 5)), DateTime(2026, 8, 5));

    // Mirror confirmPlannedPayment: mark the current occurrence confirmed.
    final confirmed = payment.copyWith(
      lastConfirmedDate: payment.currentDue(from: DateTime(2026, 8, 5)),
    );
    expect(confirmed.currentDue(from: DateTime(2026, 8, 5)), DateTime(2026, 9, 5));
    // Still listed (not deleted) and no longer prompts.
    expect(confirmed.needsConfirmation, isFalse);
    expect(confirmed.isOverdue, isFalse);
  });

  test('confirming an overdue occurrence advances past it', () {
    final payment = PlannedPayment(
      id: 'm4',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.monthly,
    );
    final confirmed = payment.copyWith(
      lastConfirmedDate: payment.currentDue(from: DateTime(2026, 8, 10)),
    );
    // Next month's occurrence is now current, not the missed one.
    expect(confirmed.currentDue(from: DateTime(2026, 8, 10)), DateTime(2026, 9, 1));
    expect(confirmed.isOverdue, isFalse);
  });

  test('weekly payment is overdue the day after its occurrence', () {
    final payment = PlannedPayment(
      id: 'w',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.weekly,
    );
    expect(cardText(payment, DateTime(2026, 8, 1, 12)), 'Due today');
    expect(cardText(payment, DateTime(2026, 8, 2, 0, 30)), 'Overdue');
  });

  test('daily payment is due today and not overdue after midnight', () {
    final payment = PlannedPayment(
      id: 'd',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 8, 1),
      repeat: RepeatFrequency.daily,
    );
    expect(cardText(payment, DateTime(2026, 8, 5)), 'Due today');
    expect(cardText(payment, DateTime(2026, 8, 5, 0, 30)), 'Due today');
  });

  test('future payment is not overdue', () {
    final payment = PlannedPayment(
      id: 'f',
      title: 'Rent',
      amount: 100,
      icon: Icons.home,
      iconColor: Colors.orange,
      categoryName: 'Housing',
      startDate: DateTime(2026, 9, 1),
      repeat: RepeatFrequency.monthly,
    );
    expect(cardText(payment, DateTime(2026, 8, 20)), 'Due 2026-9-1');
    expect(payment.isOverdue, isFalse);
  });
}
