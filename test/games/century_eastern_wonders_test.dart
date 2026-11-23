import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/domain/game_series.dart';
import 'package:board_game_score_sheet/games/century/century_eastern_wonders_game.dart';
import 'package:board_game_score_sheet/games/century/century_eastern_wonders_rules.dart';
import 'package:board_game_score_sheet/games/century/century_game.dart';
import 'package:board_game_score_sheet/games/century/century_new_world_game.dart';
import 'package:board_game_score_sheet/games/century/century_rules.dart';
import 'package:board_game_score_sheet/games/century/eastern_wonders_scoring_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/eastern_wonders_setup_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/eastern_wonders_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(EasternWondersRules.bonusVp, [6, 5, 4, 3]);
    expect(EasternWondersRules.vpTilesToEnd, 4);
    expect(EasternWondersRules.outpostsPerPlayer, 20);
    expect(EasternWondersRules.cargoLimit, 10);
    expect(EasternWondersRules.startingSets, [
      {CenturySpice.turmeric: 4},
      {CenturySpice.turmeric: 2, CenturySpice.saffron: 1},
      {CenturySpice.saffron: 2},
      {CenturySpice.turmeric: 1, CenturySpice.cardamom: 1},
    ]);
  });

  test('every Century game shares one home banner', () {
    const game = CenturyEasternWondersGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.maxPlayers, 4);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);

    final century = HomeEntry.group(GameRegistry().games)
        .whereType<SeriesEntry>()
        .singleWhere((entry) => entry.series == GameSeries.century);
    expect(century.games.map((g) => g.id), [
      CenturySpiceRoadGame.idValue,
      CenturyEasternWondersGame.idValue,
      CenturyNewWorldGame.idValue,
    ]);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints show map, VP tiles, bonus tiles and spices '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EasternWondersSetupHintsScreen());
      expect(find.text('4 market tiles back to the box'), findsOneWidget);
      expect(find.text('Top 6 of the pile'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ew-setup-closed-port')),
        findsOneWidget,
      );
      expect(_in('ew-setup-bonus-6', 'On top'), findsOneWidget);
      expect(find.text('Ginger'), findsOneWidget);
      expect(find.text('Cloves'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources list the four cube sets '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EasternWondersStartingResourcesScreen());
      expect(_in('ew-start-outposts', '20'), findsOneWidget);
      expect(_in('ew-start-cargo', '10'), findsOneWidget);
      expect(_in('ew-start-set-0', '4 Yellow'), findsOneWidget);
      expect(_in('ew-start-set-1', '2 Yellow + 1 Red'), findsOneWidget);
      expect(_in('ew-start-set-2', '2 Red'), findsOneWidget);
      expect(_in('ew-start-set-3', '1 Yellow + 1 Green'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scoring hints show game end before final score '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const EasternWondersScoringHintsScreen());
      expect(_in('ew-score-end-row', '4th VP tile'), findsOneWidget);
      expect(_in('ew-score-bonus-vp', '6/5/4/3'), findsOneWidget);
      expect(_in('ew-score-harvest', '1'), findsOneWidget);
      expect(_in('ew-score-upgrade', '2'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Game End')).dy,
        lessThan(tester.getTopLeft(find.text('Final Score')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
