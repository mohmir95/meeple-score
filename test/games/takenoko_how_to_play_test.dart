import 'package:board_game_score_sheet/games/takenoko/takenoko_game.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_how_to_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('Takenoko hub offers How to Play after Setup Hints', () {
    const game = TakenokoGame();
    expect(game.buildGuide(), isA<TakenokoHowToPlayScreen>());
    expect(game.guideTitleKey, 'hub.howToPlay');
    expect(game.hubTileOrder, [
      'hub-setup-hints',
      'hub-starting-resources',
      'hub-guide',
      'hub-quick-reference',
      'hub-scoring-hints',
    ]);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('How to Play covers the turn (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const TakenokoHowToPlayScreen());
      for (final face in TakenokoHowToPlayScreen.weather) {
        expect(
          find.byKey(ValueKey('takenoko-play-weather-${face.key}')),
          findsOneWidget,
        );
      }
      for (final action in TakenokoHowToPlayScreen.actions) {
        expect(
          find.byKey(ValueKey('takenoko-play-action-${action.key}')),
          findsOneWidget,
        );
      }
      for (final improvement in TakenokoHowToPlayScreen.improvements) {
        expect(
          find.byKey(ValueKey('takenoko-play-improvement-${improvement.key}')),
          findsOneWidget,
        );
      }
      // Follows the 2nd edition: unchosen plots go under the pile.
      expect(
        find.textContaining(
          'put the other 2 under the pile',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('You can hold at most 5.', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
