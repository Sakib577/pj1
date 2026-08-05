import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/firebase_options.dart';
import 'package:pj1/pages/dashboard_page.dart';
import 'package:pj1/state/finance_app_state.dart';

class _MockFirebaseCoreHostApi extends TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions options,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: options,
      pluginConstants: const <String?, Object?>{},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async {
    return CoreFirebaseOptions(
      apiKey: 'mock',
      appId: 'mock',
      messagingSenderId: 'mock',
      projectId: 'mock',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestFirebaseCoreHostApi.setUp(_MockFirebaseCoreHostApi());
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  Widget harness(FinanceAppState state) => FinanceAppScope(
        state: state,
        revision: 0,
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF59E0B)),
            scaffoldBackgroundColor: const Color(0xFFF7F5EF),
            useMaterial3: true,
          ),
          home: DashboardPage(),
        ),
      );

  testWidgets('create budget with transactions and category pick', (
    tester,
  ) async {
    final state = FinanceAppState();
    final food = state.expenseCategories.firstWhere(
      (c) => c.name == 'Food & Drinks',
    );
    final shop = state.expenseCategories.firstWhere(
      (c) => c.name == 'Shopping',
    );
    state.addTransaction(
      amount: 150,
      icon: Icons.restaurant,
      iconColor: const Color(0xFFF59E0B),
      isIncome: false,
      category: food,
      subcategory: 'Groceries',
      note: 'weekly shop',
    );
    state.addTransaction(
      amount: 300,
      icon: Icons.shopping_bag,
      iconColor: const Color(0xFFF59E0B),
      isIncome: false,
      category: shop,
      subcategory: 'Clothes & Shoes',
    );

    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();

    // Switch to the Budgets tab.
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    expect(find.text('Create budget'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Budget name'),
      'Food',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Monthly limit'),
      '5000',
    );

    // Pick a category from the dropdown.
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Drinks').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.budgets.length, 1);
    expect(state.budgets.first.category, 'Food & Drinks');
  });
}
