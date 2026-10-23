import 'package:board_game_score_sheet/app/app.dart';
import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/shared/update/app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  AppUpdateController controller({
    String current = 'abc',
    String? latest = 'abc',
    void Function()? onApply,
  }) {
    return AppUpdateController(
      currentBuild: current,
      fetchLatestBuild: () async => latest,
      applyUpdate: () async => onApply?.call(),
      watchVisibility: (_) {},
    );
  }

  test('flags an update only when the deployed build differs', () async {
    final same = controller();
    await same.check();
    expect(same.available, isFalse);

    final newer = controller(latest: 'def');
    await newer.check();
    expect(newer.available, isTrue);

    newer.dismiss();
    expect(newer.available, isFalse);
  });

  test('local builds without APP_BUILD never check', () async {
    var fetched = false;
    final local = AppUpdateController(
      currentBuild: '',
      fetchLatestBuild: () async {
        fetched = true;
        return 'def';
      },
      watchVisibility: (_) {},
    );
    await local.check();
    expect(fetched, isFalse);
    expect(local.available, isFalse);
  });

  test('a failed check is ignored', () async {
    final offline = AppUpdateController(
      currentBuild: 'abc',
      fetchLatestBuild: () async => throw StateError('offline'),
      watchVisibility: (_) {},
    );
    await offline.check();
    expect(offline.available, isFalse);
  });

  testWidgets('banner offers the update and applies it', (tester) async {
    var applied = false;
    final updates = controller(latest: 'def', onApply: () => applied = true);
    await tester.pumpWidget(
      BoardGameScoreSheetApp(
        repository: MemorySessionRepository(),
        registry: GameRegistry(),
        localeController: await createTestLocale(),
        updateController: updates,
      ),
    );
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('app-update-banner')), findsNothing);

    await updates.check();
    await pumpFor(tester);
    expect(
      find.text('A new version of Meeple Score is available.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('app-update-now')));
    await tester.pump();
    expect(applied, isTrue);
  });
}
