import 'package:board_game_score_sheet/games/century/century_new_world_game.dart';
import 'package:board_game_score_sheet/games/century/century_new_world_rules.dart';
import 'package:board_game_score_sheet/games/century/century_rules.dart';
import 'package:board_game_score_sheet/games/century/new_world_scoring_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/new_world_setup_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/new_world_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(NewWorldRules.pointCardMarksRemoved(2), ['3+', '=4']);
    expect(NewWorldRules.pointCardMarksRemoved(3), ['=4']);
    expect(NewWorldRules.pointCardMarksRemoved(4), isEmpty);
    expect(NewWorldRules.explorationOnTwoThree(2), 2);
    expect(NewWorldRules.explorationOnTwoThree(3), 2);
    expect(NewWorldRules.explorationOnTwoThree(4), 0);
    expect(NewWorldRules.settlersOnBoard(2), 7);
    expect(NewWorldRules.settlersOnBoard(4), 6);
    expect(NewWorldRules.pointCardsToEnd, 8);
    expect(NewWorldRules.startingCubes(4), {
      CenturySpice.turmeric: 3,
      CenturySpice.saffron: 1,
    });
  });

  test('A New World has three help pages and no scoresheet', () {
    const game = CenturyNewWorldGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.maxPlayers, 4);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints follow the player count (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const NewWorldSetupHintsScreen());
      expect(find.text('2 location boards back to the box'), findsOneWidget);
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(find.text('Cards with a white star'), findsOneWidget);
      expect(
        find.textContaining(
          'showing I or III at their bottom',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(_in('nw-setup-remove-marks', '3+, =4'), findsOneWidget);
      expect(_in('nw-setup-remove-marks', '=4'), findsOneWidget);
      expect(_in('nw-setup-remove-marks', '–'), findsOneWidget);
      expect(_in('nw-setup-exploration-table', '8'), findsNWidgets(3));
      // 2-3 locations: 2, 2, none; to the box: none, none, 2; plus the
      // 2-player header.
      expect(_in('nw-setup-exploration-table', '2'), findsNWidgets(4));
      expect(_in('nw-setup-exploration-table', '–'), findsNWidgets(3));
      expect(find.text('Corn'), findsOneWidget);
      expect(find.text('Fur'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources list settlers and 4 seats '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const NewWorldStartingResourcesScreen());
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      // On the board: 7, 6, 6. In reserve: 5, 6, 6.
      expect(_in('nw-start-settlers', '7'), findsOneWidget);
      expect(_in('nw-start-settlers', '5'), findsOneWidget);
      expect(_in('nw-start-settlers', '6'), findsNWidgets(4));
      expect(
        _in('nw-start-settlers', 'Left of your board, not available yet'),
        findsOneWidget,
      );
      expect(_in('nw-start-seat-1', '3 Yellow'), findsOneWidget);
      expect(_in('nw-start-seat-4', '3 Yellow + 1 Red'), findsOneWidget);
      expect(find.byKey(const ValueKey('nw-start-seat-5')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scoring hints show game end, final score and bonus tiles '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const NewWorldScoringHintsScreen());
      expect(_in('nw-score-end-row', '8th Point card'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nw-score-bonus-merchants')),
        findsNothing,
      );
      expect(_in('nw-score-bonus-pair', '3'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Game End')).dy,
        lessThan(tester.getTopLeft(find.text('Final Score')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
