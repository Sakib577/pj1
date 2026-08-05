import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pj1/firebase_options.dart';
import 'package:pj1/pages/budget_page.dart';
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

  testWidgets('create budget dialog: type, pick category, save', (tester) async {
    final state = FinanceAppState();

    await tester.pumpWidget(
      FinanceAppScope(
        state: state,
        revision: 0,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showCreateBudgetDialog(context),
                  child: const Text('New budget'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    expect(find.text('Create budget'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Budget name'), 'Food');
    await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), '1000');

    // Open the category dropdown and pick the first real category.
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Drinks').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.budgets.length, 1);
  });

  testWidgets('create budget dialog: save without touching category dropdown',
      (tester) async {
    final state = FinanceAppState();

    await tester.pumpWidget(
      FinanceAppScope(
        state: state,
        revision: 0,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showCreateBudgetDialog(context),
                  child: const Text('New budget'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Budget name'), 'Food');
    await tester.enterText(find.widgetWithText(TextField, 'Monthly limit'), '1000');

    // Let the onChanged rebuild run so Save becomes enabled.
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.budgets.length, 1);
  });

  testWidgets('create budget: switch period to custom repeat then save',
      (tester) async {
    final state = FinanceAppState();

    await tester.pumpWidget(
      FinanceAppScope(
        state: state,
        revision: 0,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showCreateBudgetDialog(context),
                  child: const Text('New budget'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Budget name'),
      'Food',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Monthly limit'),
      '1000',
    );

    // Switch the period dropdown to "Custom repeat".
    await tester.tap(find.text('Calendar month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom repeat'));
    await tester.pumpAndSettle();

    // A "Repeat every days" field appears.
    await tester.enterText(
      find.widgetWithText(TextField, 'Repeat every days'),
      '7',
    );

    // Open the category dropdown, then save.
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Drinks').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.budgets.length, 1);
    expect(state.budgets.first.period, 'custom');
    expect(state.budgets.first.customDays, 7);
  });

  testWidgets('create budget: edit dialog keeps text controllers alive',
      (tester) async {
    final state = FinanceAppState();

    await tester.pumpWidget(
      FinanceAppScope(
        state: state,
        revision: 0,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showCreateBudgetDialog(context),
                  child: const Text('New budget'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New budget'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Budget name'),
      'Food',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Monthly limit'),
      '1000',
    );

    // Rapidly toggle the period dropdown a few times: open the menu, pick the
    // other option, repeat.
    var displayed = 'Calendar month';
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(displayed));
      await tester.pumpAndSettle();
      displayed = displayed == 'Calendar month' ? 'Every 30 days' : 'Calendar month';
      await tester.tap(find.text(displayed).last);
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
