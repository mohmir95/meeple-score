import 'package:board_game_score_sheet/games/takenoko/takenoko_game.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('Takenoko hub offers starting resources', () {
    const game = TakenokoGame();
    expect(game.showStartingResources, isTrue);
    expect(
      game.buildStartingResources(),
      isA<TakenokoStartingResourcesScreen>(),
    );
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('starting resources list what each player takes '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const TakenokoStartingResourcesScreen());
      expect(find.text('Each Player'), findsOneWidget);
      expect(_in('takenoko-start-board', '× 1'), findsOneWidget);
      expect(_in('takenoko-start-tokens', '× 2'), findsOneWidget);
      expect(_in('takenoko-start-hand', '× 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
