import 'package:board_game_score_sheet/shared/navigation/browser_back_sync.dart';
import 'package:board_game_score_sheet/shared/navigation/browser_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A browser history with a stack of entries, like the real one.
class _FakeHistory implements BrowserHistory {
  int entries = 1;
  void Function()? _onBack;

  @override
  void push() => entries++;

  @override
  void back() {
    entries--;
    _onBack?.call();
  }

  @override
  void listen(void Function() onBack) => _onBack = onBack;

  /// The user swipes back from the screen edge.
  void userGoesBack() => back();
}

void main() {
  late _FakeHistory history;
  late GlobalKey<NavigatorState> navigator;

  Future<void> pumpApp(WidgetTester tester) async {
    history = _FakeHistory();
    navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [BrowserBackSync(history: history)],
        home: const Text('home'),
      ),
    );
  }

  Future<void> open(
    WidgetTester tester,
    String name, {
    bool guarded = false,
  }) async {
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            guarded ? PopScope(canPop: false, child: Text(name)) : Text(name),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('each opened page adds one history entry', (tester) async {
    await pumpApp(tester);
    expect(history.entries, 1);
    await open(tester, 'game');
    await open(tester, 'setup');
    expect(history.entries, 3);
  });

  testWidgets('browser back closes pages down to home', (tester) async {
    await pumpApp(tester);
    await open(tester, 'game');
    await open(tester, 'setup');

    history.userGoesBack();
    await tester.pumpAndSettle();
    expect(find.text('game'), findsOneWidget);
    expect(history.entries, 2);

    history.userGoesBack();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(history.entries, 1);
  });

  testWidgets('closing a page in the app drops its entry', (tester) async {
    await pumpApp(tester);
    await open(tester, 'game');
    await open(tester, 'setup');

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('game'), findsOneWidget);
    expect(history.entries, 2);

    // The next browser back still lands on home, not on a stale entry.
    history.userGoesBack();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(history.entries, 1);
  });

  testWidgets('a page that refuses to close keeps its entry', (tester) async {
    await pumpApp(tester);
    await open(tester, 'game', guarded: true);

    history.userGoesBack();
    await tester.pumpAndSettle();
    expect(find.text('game'), findsOneWidget);
    expect(history.entries, 2);
  });
}
