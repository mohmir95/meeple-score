import 'package:board_game_score_sheet/games/century/century_sand_to_sea_game.dart';
import 'package:board_game_score_sheet/games/century/century_sand_to_sea_rules.dart';
import 'package:board_game_score_sheet/games/century/sand_to_sea_how_to_play_screen.dart';
import 'package:board_game_score_sheet/games/century/sand_to_sea_scoring_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/sand_to_sea_setup_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/sand_to_sea_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(SandToSeaRules.faceUpMerchantCards, 4);
    expect(SandToSeaRules.marketTilesRemoved, 8);
    expect(SandToSeaRules.seaTiles, 4);
    expect(SandToSeaRules.outpostsPerPlayer, 16);
    expect(SandToSeaRules.outpostCostPerOutpost(2), 2);
    expect(SandToSeaRules.outpostCostPerOutpost(3), 1);
    expect(SandToSeaRules.outpostCostPerOutpost(4), 1);
    expect(SandToSeaRules.vpTilesToEnd, 4);
    expect(
      [
        for (final n in SandToSeaRules.playerCounts)
          SandToSeaRules.startingCardsToBox(n),
      ],
      [6, 4, 2],
    );
  });

  test('From Sand to Sea has four help pages and no scoresheet', () {
    const game = CenturySandToSeaGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.maxPlayers, 4);
    expect(game.buildGuide(), isNotNull);
    expect(game.guideTitleKey, 'hub.howToPlay');
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

      await pumpWithL10n(tester, const SandToSeaSetupHintsScreen());
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(_in('fs-setup-to-box', '6'), findsOneWidget);
      // 4 and 2 also head the 4- and 2-player columns.
      expect(_in('fs-setup-to-box', '4'), findsNWidgets(2));
      expect(_in('fs-setup-to-box', '2'), findsNWidgets(2));
      expect(find.text('8 market tiles back to the box'), findsOneWidget);
      expect(find.byKey(const ValueKey('ew-mini-map-columns')), findsOneWidget);
      expect(find.byIcon(Icons.waves_rounded), findsNWidgets(4));
      expect(find.byIcon(Icons.anchor_rounded), findsNWidgets(4));
      expect(find.byKey(const ValueKey('fs-setup-own-maps')), findsOneWidget);
      expect(
        find.textContaining('land in random places', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Top 6 of the pile'), findsOneWidget);
      expect(_in('fs-setup-bonus-6', 'On top'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources combine both games (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const SandToSeaStartingResourcesScreen());
      expect(_in('fs-start-create', 'Create 2'), findsOneWidget);
      expect(_in('fs-start-outposts', '16'), findsOneWidget);
      expect(_in('fs-start-set-3', '1 Yellow + 1 Green'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scoring hints show game end before final score '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const SandToSeaScoringHintsScreen());
      expect(_in('fs-score-end-row', '4th VP tile'), findsOneWidget);
      expect(_in('fs-score-bonus-vp', '6/5/4/3'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Game End')).dy,
        lessThan(tester.getTopLeft(find.text('Final Score')).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('how to play lists the four actions (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const SandToSeaHowToPlayScreen());
      for (final title in [
        '1. Acquire a Card',
        '2. Play a Card',
        '3. Move',
        '4. Rest',
      ]) {
        // Once as a chip, once as its panel's title.
        expect(find.text(title), findsNWidgets(2));
      }
      expect(find.text('3.1 Market'), findsOneWidget);
      expect(find.text('3.2 Port'), findsOneWidget);
      expect(
        find.textContaining('moving 3 tiles costs 3 cards'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
