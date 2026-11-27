import 'package:board_game_score_sheet/games/century/century_east_to_west_all_game.dart';
import 'package:board_game_score_sheet/games/century/century_east_to_west_all_rules.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_all_how_to_play_screen.dart';
import 'package:board_game_score_sheet/games/century/east_to_west_all_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(EastToWestAllRules.boards, [
      ['A2', 'B2', 'E2', 'D2'],
      ['C1', 'F2'],
    ]);
    expect(EastToWestAllRules.bonusTiles, 25);
    expect(EastToWestAllRules.explorationOnIcons, 7);
    expect(EastToWestAllRules.explorationToBox(2), 1);
    expect(EastToWestAllRules.merchantCardsPerBonus, 4);
    expect(EastToWestAllRules.bonusSpaces, 4);
    expect(EastToWestAllRules.marketTiles, 12);
    expect(EastToWestAllRules.outpostsPerPlayer, 12);
    expect(EastToWestAllRules.pointCardsToEnd, 8);
  });

  test('has four help pages and no scoresheet', () {
    const game = CenturyEastToWestAllGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.name, 'Spice Road + Eastern Wonders + A New World');
    expect(game.buildGuide(), isNotNull);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints cover all three games (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 3800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestAllSetupHintsScreen());
      expect(find.text('D2'), findsOneWidget);
      expect(find.text('Cards with a black star'), findsOneWidget);
      expect(find.textContaining('Shuffle all 25 bonus tiles'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('etwall-setup-island-map')),
        findsOneWidget,
      );
      expect(
        find.text('All purple starting cards back to the box'),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(_in('etwall-setup-remove-marks', '=4'), findsOneWidget);
      expect(_in('etwall-setup-exploration-table', '2'), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'starting resources and scoring match Eastern Wonders + A New World '
      '(${width.toInt()}px)',
      (tester) async {
        tester.view.physicalSize = Size(width, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const game = CenturyEastToWestAllGame();
        await pumpWithL10n(tester, game.buildStartingResources()!);
        expect(_in('nw-start-outposts', '12'), findsOneWidget);

        await pumpWithL10n(tester, game.buildScoringHints()!);
        expect(find.byKey(const ValueKey('nw-score-outposts')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('how to play covers market, boat and trade locations '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 7000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EastToWestAllHowToPlayScreen());
      // The new locations and the card actions sit inside the Work panel.
      for (final key in const [
        'etwall-play-market',
        'etwall-play-cards',
        'etwall-play-refresh',
        'etwall-play-move',
        'etwall-play-boat-trade',
        'etwall-play-outpost-trade',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('etwall-play-work')),
            matching: find.byKey(ValueKey(key)),
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Adjust Trade Route Location'), findsNothing);
      // The A New World location list starts collapsed; no Bonus tiles here.
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
        findsNothing,
      );
      expect(find.textContaining('board D2 (not B2 or F2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
