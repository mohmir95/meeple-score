import 'package:board_game_score_sheet/games/century/century_east_to_west_game.dart';
import 'package:board_game_score_sheet/games/century/century_east_to_west_rules.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_how_to_play_screen.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(EastToWestRules.boards, [
      ['A1', 'B1'],
      ['E2', 'C2'],
    ]);
    expect(EastToWestRules.bonusTilesInPlay, 20);
    expect(EastToWestRules.explorationBeside(2), 8);
    expect(EastToWestRules.explorationBeside(3), 8);
    expect(EastToWestRules.explorationBeside(4), 10);
    expect(EastToWestRules.explorationOnBoard(4), 0);
    expect(EastToWestRules.tradeRouteLimit, 5);
    expect(EastToWestRules.routeSettlers(2), 3);
    expect(EastToWestRules.pointCardsToEnd, 8);
  });

  test('From East to West has four help pages and no scoresheet', () {
    const game = CenturyEastToWestGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.maxPlayers, 4);
    expect(game.buildGuide(), isNotNull);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints follow the player count (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestSetupHintsScreen());
      expect(find.text('E2'), findsOneWidget);
      expect(find.text('Cards with a black star'), findsOneWidget);
      expect(
        find.text('All purple starting cards back to the box'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(_in('etw-setup-remove-marks', '3+, =4'), findsOneWidget);
      // Beside the board: 8, 8, 10. On 2-3 locations: 2, 2, none. The
      // header pills add a 2.
      expect(_in('etw-setup-exploration-table', '8'), findsNWidgets(2));
      expect(_in('etw-setup-exploration-table', '10'), findsOneWidget);
      expect(_in('etw-setup-exploration-table', '2'), findsNWidgets(3));
      expect(_in('etw-setup-exploration-table', '–'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources and scoring reuse A New World '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const game = CenturyEastToWestGame();
      await pumpWithL10n(tester, game.buildStartingResources()!);
      expect(find.byKey(const ValueKey('nw-start-seat-4')), findsOneWidget);

      await pumpWithL10n(tester, game.buildScoringHints()!);
      expect(_in('nw-score-end-row', '8th Point card'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('nw-score-bonus-merchants')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('how to play covers Work, Route and Rest '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestHowToPlayScreen());
      for (final title in ['Work', 'Route', 'Rest']) {
        // Once as a chip, once as its panel's title.
        expect(find.text(title), findsNWidgets(2));
      }
      // The three new locations sit inside the Work panel.
      for (final key in const [
        'etw-play-market',
        'etw-play-refresh',
        'etw-play-adjust',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('etw-play-work')),
            matching: find.byKey(ValueKey(key)),
          ),
          findsOneWidget,
        );
      }
      // The A New World location list starts collapsed.
      final fort = find.byKey(const ValueKey('nw-play-fort'));
      expect(fort, findsNothing);
      await tester.tap(find.byKey(const ValueKey('nw-locations-collapsible')));
      await tester.pumpAndSettle();
      expect(fort, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('nw-locations-collapsible')),
          matching: find.byIcon(Icons.workspace_premium_outlined),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
