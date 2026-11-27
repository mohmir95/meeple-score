import 'package:board_game_score_sheet/games/century/century_east_to_west_ew_game.dart';
import 'package:board_game_score_sheet/games/century/century_east_to_west_ew_rules.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_ew_how_to_play_screen.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_ew_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(EastToWestEwRules.boards, [
      ['A2', 'B2'],
      ['C1', 'F2'],
    ]);
    expect(EastToWestEwRules.bonusTilesInPlay, 17);
    expect(EastToWestEwRules.explorationOnIcons, 7);
    expect(EastToWestEwRules.explorationOnTwoThree(3), 2);
    expect(EastToWestEwRules.explorationToBox(3), 1);
    expect(EastToWestEwRules.explorationToBox(4), 3);
    expect(EastToWestEwRules.marketTiles, 12);
    expect(EastToWestEwRules.outpostsPerPlayer, 12);
    expect(EastToWestEwRules.bonusSpaces, 4);
    expect(EastToWestEwRules.outpostCostPerOutpost(2), 2);
    expect(EastToWestEwRules.pointCardsToEnd, 8);
  });

  test('has four help pages and no scoresheet', () {
    const game = CenturyEastToWestEwGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.name, 'Eastern Wonders + A New World');
    expect(game.buildGuide(), isNotNull);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints follow the player count (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestEwSetupHintsScreen());
      expect(find.text('F2'), findsOneWidget);
      expect(find.text('Cards with a white star'), findsOneWidget);
      // On icons: 7 each. On 2-3: 2, 2, none. To the box: 1, 1, 3. The
      // header pills add a 2 and a 3.
      expect(_in('etwew-setup-exploration-table', '7'), findsNWidgets(3));
      expect(_in('etwew-setup-exploration-table', '2'), findsNWidgets(3));
      expect(_in('etwew-setup-exploration-table', '1'), findsNWidgets(2));
      expect(_in('etwew-setup-exploration-table', '3'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('etwew-setup-island-map')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources and scoring add the Eastern Wonders pieces '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const game = CenturyEastToWestEwGame();
      await pumpWithL10n(tester, game.buildStartingResources()!);
      expect(_in('nw-start-outposts', '12'), findsOneWidget);
      expect(find.byKey(const ValueKey('nw-start-boat')), findsOneWidget);

      await pumpWithL10n(tester, game.buildScoringHints()!);
      expect(find.byKey(const ValueKey('nw-score-outposts')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nw-score-bonus-merchants')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('how to play covers the new locations (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestEwHowToPlayScreen());
      expect(find.text('Work'), findsNWidgets(2));
      expect(find.text('Rest'), findsNWidgets(2));
      // The new locations sit inside the Work panel.
      for (final key in const [
        'etwew-play-move',
        'etwew-play-boat-trade',
        'etwew-play-outpost-trade',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('etwew-play-work')),
            matching: find.byKey(ValueKey(key)),
          ),
          findsOneWidget,
        );
      }
      // Forts give no Bonus tiles in this game.
      await tester.tap(find.byKey(const ValueKey('nw-locations-collapsible')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nw-play-fort')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('nw-locations-collapsible')),
          matching: find.byIcon(Icons.workspace_premium_outlined),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
