import 'package:board_game_score_sheet/games/takenoko/takenoko_game.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('Takenoko hub offers setup hints first', () {
    const game = TakenokoGame();
    expect(game.showSetupHints, isTrue);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.hubTileOrder, [
      'hub-setup-hints',
      'hub-guide',
      'hub-quick-reference',
      'hub-scoring-hints',
    ]);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets(
      'setup hints list the rulebook preparation (${width.toInt()}px)',
      (tester) async {
        tester.view.physicalSize = Size(width, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpWithL10n(tester, const TakenokoSetupHintsScreen());
        expect(_in('takenoko-setup-pond', '× 1'), findsOneWidget);
        expect(_in('takenoko-setup-plots', '× 27'), findsOneWidget);
        expect(_in('takenoko-setup-irrigation', '× 20'), findsOneWidget);
        expect(_in('takenoko-setup-improvements', '× 9'), findsOneWidget);
        expect(_in('takenoko-setup-tokens', '× 2'), findsOneWidget);
        expect(_in('takenoko-setup-hand', '× 3'), findsOneWidget);
        expect(_in('takenoko-setup-emperor', 'Set aside'), findsOneWidget);
        expect(find.text('Face down'), findsNWidgets(3));
        expect(
          find.text('The tallest player starts. Play goes clockwise.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
