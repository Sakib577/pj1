import 'package:flutter_test/flutter_test.dart';
import 'package:pj1/models/finance_models.dart';

void main() {
  DebtItem debt({
    double amount = 100,
    DebtType type = DebtType.borrowed,
    DebtType? createdType,
    double? remainingAmount,
    List<DebtRepayment> repaymentLog = const [],
  }) => DebtItem(
    id: 'd1',
    person: 'Alex',
    amount: amount,
    type: type,
    createdType: createdType,
    remainingAmount: remainingAmount,
    repaymentLog: repaymentLog,
    createdAt: DateTime(2026, 1, 1),
  );

  test('remaining defaults to full amount when never partially repaid', () {
    expect(debt().remaining, 100);
    expect(debt().hasPartialRepayment, isFalse);
  });

  test('remaining reflects partial repayments', () {
    final d = debt(remainingAmount: 40);
    expect(d.remaining, 40);
    expect(d.hasPartialRepayment, isTrue);
  });

  test('originType falls back to type when createdType is not set', () {
    expect(debt(type: DebtType.lent).originType, DebtType.lent);
    expect(
      debt(type: DebtType.lent, createdType: DebtType.borrowed).originType,
      DebtType.borrowed,
    );
  });

  test('serializes and restores repayment history', () {
    final d = debt(
      type: DebtType.lent,
      createdType: DebtType.borrowed,
      remainingAmount: 20,
      repaymentLog: const [
        DebtRepayment(transactionId: 'repaid-1', amount: 80),
        DebtRepayment(transactionId: 'repaid-2', amount: 100),
      ],
    );
    final restored = DebtItem.fromMap('d1', d.toMap());
    expect(restored.originType, DebtType.borrowed);
    expect(restored.type, DebtType.lent);
    expect(restored.remaining, 20);
    expect(restored.repaymentLog.length, 2);
    expect(restored.repaymentLog.first.transactionId, 'repaid-1');
    expect(restored.repaymentLog.last.amount, 100);
  });

  test('restores createdType as null when absent (legacy records)', () {
    final data = {
      'person': 'Alex',
      'amount': 50.0,
      'type': 'lent',
      'settlement': 'active',
      'createdAt': 1767225600000,
    };
    final restored = DebtItem.fromMap('d1', data);
    expect(restored.originType, DebtType.lent);
    expect(restored.remaining, 50);
    expect(restored.repaymentLog, isEmpty);
  });

  test('round-trips a flipped legacy debt (origin recovered via createdType)', () {
    // A debt that was overpaid so it flipped to borrowed, but whose origin was
    // created as lent and amount kept the original principal.
    final d = DebtItem(
      id: 'd1',
      person: 'sazid',
      amount: 19,
      type: DebtType.borrowed,
      createdType: DebtType.lent,
      remainingAmount: 6,
      repaymentLog: const [
        DebtRepayment(transactionId: 'repaid-1', amount: 25),
      ],
      createdAt: DateTime(2026, 1, 1),
    );
    expect(d.originType, DebtType.lent);
    expect(d.remaining, 6);
  });
}