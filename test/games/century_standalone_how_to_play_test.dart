import 'package:board_game_score_sheet/games/century/century_eastern_wonders_game.dart';
import 'package:board_game_score_sheet/games/century/century_game.dart';
import 'package:board_game_score_sheet/games/century/century_new_world_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  final games = {
    const CenturySpiceRoadGame(): ['Play', 'Acquire', 'Rest', 'Claim'],
    const CenturyEasternWondersGame(): ['Move', 'Market', 'Port', 'Harvest'],
    const CenturyNewWorldGame(): ['Work', 'Rest'],
  };

  for (final MapEntry(key: game, value: actions) in games.entries) {
    for (final width in [1200.0, 360.0]) {
      testWidgets('${game.name} how to play lists its actions '
          '(${width.toInt()}px)', (tester) async {
        tester.view.physicalSize = Size(width, 6000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        expect(game.guideTitleKey, 'hub.howToPlay');
        await pumpWithL10n(tester, game.buildGuide()!);
        for (final action in actions) {
          // Once as a chip, once as its panel's title.
          expect(find.text(action), findsNWidgets(2));
        }
        if (game is CenturyEasternWondersGame) {
          // Move is an optional step before the action, not an action.
          expect(
            find.byKey(const ValueKey('century-turn-flow')),
            findsOneWidget,
          );
          expect(find.text('Optional'), findsOneWidget);
        }
        if (game is CenturyNewWorldGame) {
          // Forts are one of the location types, not a panel of their own.
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('nw-play-locations')),
              matching: find.byKey(const ValueKey('nw-play-fort')),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
