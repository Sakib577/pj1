import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/models/finance_models.dart';
import 'package:pj1/utils/currency_formatters.dart';

void main() {
  testWidgets('compact payments due dialog builds without exception',
      (tester) async {
    final due = <PlannedPayment>[
      PlannedPayment(
        id: '1',
        title: 'Rent',
        amount: 800,
        icon: Icons.home,
        iconColor: const Color(0xFFF59E0B),
        categoryName: 'Housing',
        startDate: DateTime.now(),
      ),
      PlannedPayment(
        id: '2',
        title: 'Electricity bill',
        amount: 45.5,
        icon: Icons.bolt,
        iconColor: const Color(0xFFF97316),
        categoryName: 'Housing · Utilities',
        startDate: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: const Color(0xFFFFFCF7),
                      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      title: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Payments due',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      content: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: SizedBox(
                          width: 300,
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: due.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final payment = due[index];
                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  payment.icon,
                                  color: payment.iconColor,
                                  size: 20,
                                ),
                                title: Text(
                                  payment.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  payment.categoryName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  '${payment.isIncome ? '+' : '-'}'
                                  '${formatCurrency(payment.amount)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, 'skip'),
                              child: const Text('Skip'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, 'delete'),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFFDC2626)),
                              ),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, 'confirm'),
                              child: const Text('Confirm & record'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Payments due'), findsOneWidget);
    expect(find.text('Confirm & record'), findsOneWidget);
  });
}
