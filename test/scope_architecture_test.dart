import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors FinanceAppScope + ListenableBuilder architecture used in main.dart:
// a plain InheritedWidget exposing a ChangeNotifier, with the app rebuilt from
// the root by a ListenableBuilder (NOT by InheritedNotifier dependents).
class Repo extends ChangeNotifier {
  int count = 0;
}

class RepoScope extends InheritedWidget {
  const RepoScope({super.key, required this.notifier, required super.child});
  final Repo notifier;
  @override
  bool updateShouldNotify(RepoScope oldWidget) => false;
  static Repo of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepoScope>()!.notifier;
}

Widget harness() {
  final repo = Repo();
  return RepoScope(
    notifier: repo,
    child: ListenableBuilder(
      listenable: repo,
      builder: (context, child) => MaterialApp(
        home: Builder(builder: (context) {
          final r = RepoScope.of(context);
          return Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  );
                  r.count++;
                  r.notifyListeners();
                },
                child: const Text('Open'),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

void main() {
  testWidgets('dialog closes and notifier fires without assertion', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('multiple rapid notifies do not crash', (tester) async {
    await tester.pumpWidget(harness());
    final repo = RepoScope.of(tester.element(find.text('Open')));
    for (var i = 0; i < 50; i++) {
      repo.notifyListeners();
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}