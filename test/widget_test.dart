// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/main.dart';

void main() {
  testWidgets('Dashboard renders key sections', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('\$4,250.80'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Planned Payments'), findsOneWidget);
  });
}
