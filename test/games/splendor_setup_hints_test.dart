import 'package:board_game_score_sheet/games/splendor/splendor_game.dart';
import 'package:board_game_score_sheet/games/splendor/splendor_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('matches the rulebook setup for each player count', () {
    expect(SplendorSetup.gemsPerColor(4), 7);
    expect(SplendorSetup.gemsPerColor(3), 5);
    expect(SplendorSetup.gemsPerColor(2), 4);
    expect(SplendorSetup.nobles(4), 5);
    expect(SplendorSetup.nobles(3), 4);
    expect(SplendorSetup.nobles(2), 3);
    expect(SplendorSetup.deckSizes, [40, 30, 20]);
  });

  test('Splendor has no scoresheet tile', () {
    const game = SplendorGame();
    expect(game.showScoresheet, isFalse);
    expect(game.hasScoresheet, isFalse);
    expect(game.buildSetupHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('switching the player count updates gems and nobles '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const SplendorSetupHintsScreen());

      expect(find.text('7 of each Gem + 5 Gold'), findsOneWidget);
      expect(find.text('× 7'), findsNWidgets(5));
      expect(find.text('× 5'), findsOneWidget);
      expect(find.text('5 Noble Tiles'), findsOneWidget);
      expect(find.text('−2 to the box'), findsNothing);
      expect(find.text('3 Decks · 12 Face-up Cards'), findsOneWidget);

      await tester.tap(find.text('3 players'));
      await pumpFor(tester);
      expect(find.text('5 of each Gem + 5 Gold'), findsOneWidget);
      expect(find.text('× 5'), findsNWidgets(6));
      expect(find.text('−2 to the box'), findsNWidgets(5));
      expect(find.text('4 Noble Tiles'), findsOneWidget);

      await tester.tap(find.text('2 players'));
      await pumpFor(tester);
      expect(find.text('4 of each Gem + 5 Gold'), findsOneWidget);
      expect(find.text('× 4'), findsNWidgets(5));
      expect(find.text('−3 to the box'), findsNWidgets(5));
      expect(find.text('3 Noble Tiles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
