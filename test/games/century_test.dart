import 'package:board_game_score_sheet/games/century/century_game.dart';
import 'package:board_game_score_sheet/games/century/century_rules.dart';
import 'package:board_game_score_sheet/games/century/century_scoring_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/century_setup_hints_screen.dart';
import 'package:board_game_score_sheet/games/century/century_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook numbers', () {
    expect(
      [for (final n in CenturyRules.playerCounts) CenturyRules.coinsPerPile(n)],
      [4, 6, 8, 10],
    );
    expect(
      [
        for (final n in CenturyRules.playerCounts)
          CenturyRules.startingCardsToBox(n),
      ],
      [6, 4, 2, 0],
    );
    expect(
      [
        for (final n in CenturyRules.playerCounts)
          CenturyRules.pointCardsToEnd(n),
      ],
      [6, 6, 5, 5],
    );
    expect(CenturyRules.startingSpices(1), {CenturySpice.turmeric: 3});
    expect(CenturyRules.startingSpices(2), {CenturySpice.turmeric: 4});
    expect(CenturyRules.startingSpices(3), {CenturySpice.turmeric: 4});
    for (final seat in [4, 5]) {
      expect(CenturyRules.startingSpices(seat), {
        CenturySpice.turmeric: 3,
        CenturySpice.saffron: 1,
      });
    }
  });

  test('Century is a two-part title with three help pages', () {
    const game = CenturySpiceRoadGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.buildSetupHints(), isNotNull);
    expect(game.buildStartingResources(), isNotNull);
    expect(game.buildScoringHints(), isNotNull);
    expect(game.maxPlayers, 5);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('setup hints follow the player count (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const CenturySetupHintsScreen());
      expect(_in('century-setup-gold', '× 8'), findsOneWidget);
      expect(_in('century-setup-silver', '× 8'), findsOneWidget);
      expect(_in('century-setup-starting-cards', '8'), findsOneWidget);
      expect(find.text('2 starting cards back to the box'), findsOneWidget);
      expect(find.text('Caravans & First Player'), findsNothing);

      await tester.tap(find.text('5 players'));
      await pumpFor(tester);
      expect(_in('century-setup-gold', '× 10'), findsOneWidget);
      expect(find.byKey(const ValueKey('century-setup-to-box')), findsNothing);

      await tester.tap(find.text('2 players'));
      await pumpFor(tester);
      expect(_in('century-setup-silver', '× 4'), findsOneWidget);
      expect(find.text('6 starting cards back to the box'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('starting resources always list all 5 seats '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const CenturyStartingResourcesScreen());
      expect(find.byKey(const ValueKey('century-players')), findsNothing);
      expect(_in('century-start-seat-1', '3 Yellow'), findsOneWidget);
      expect(_in('century-start-seat-2', '4'), findsOneWidget);
      expect(_in('century-start-seat-3', '4'), findsOneWidget);
      expect(_in('century-start-seat-4', '3 Yellow + 1 Red'), findsOneWidget);
      expect(_in('century-start-seat-5', '3 Yellow + 1 Red'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scoring hints show final score and game end only '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const CenturyScoringHintsScreen());
      expect(find.text('Final Score'), findsOneWidget);
      expect(find.text('Game End'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Game End')).dy,
        lessThan(tester.getTopLeft(find.text('Final Score')).dy),
      );
      expect(find.text('Example'), findsNothing);
      expect(find.text('Earning Coins'), findsNothing);
      expect(find.text('Tips'), findsNothing);
      expect(_in('century-score-end-2', '6th card'), findsOneWidget);
      expect(_in('century-score-end-4', '5th card'), findsOneWidget);
      // The coin face and the value both read 3.
      expect(_in('century-score-gold', '3'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
