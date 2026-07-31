import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/main.dart';

void main() {
  testWidgets('Dashboard renders and saves a transaction', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('\$0.00'), findsWidgets);
    expect(find.text('No categories yet'), findsOneWidget);
    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('No planned payments yet'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Transaction'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('transaction-title')), 'Coffee');
    await tester.tap(find.byKey(const ValueKey('key-2')));
    await tester.tap(find.byKey(const ValueKey('key-5')));
    await tester.tap(find.byKey(const ValueKey('key-.')));
    await tester.tap(find.byKey(const ValueKey('key-5')));
    await tester.tap(find.byKey(const ValueKey('key-0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('save-transaction')));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('-\$25.50'), findsWidgets);
  });
}
