import 'package:board_game_score_sheet/games/project_l/project_l_game.dart';
import 'package:board_game_score_sheet/games/project_l/project_l_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('matches the base-game setup for each player count', () {
    expect(ProjectLSetup.playerCounts, [2, 3, 4]);
    expect(ProjectLSetup.blackPuzzles(2), 12);
    expect(ProjectLSetup.blackPuzzles(3), 14);
    expect(ProjectLSetup.blackPuzzles(4), 16);
  });

  test('Project L has no scoresheet tile', () {
    const game = ProjectLGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.buildSetupHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('player count switches the setup (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const ProjectLSetupHintsScreen());
      expect(find.text('16 Black Puzzles'), findsOneWidget);
      expect(find.text('× 32'), findsOneWidget);
      expect(find.text('× 4'), findsNWidgets(2));
      expect(find.text('Solo'), findsNothing);
      expect(find.text('5 players'), findsNothing);

      await tester.tap(find.text('2 players'));
      await pumpFor(tester);
      expect(find.text('12 Black Puzzles'), findsOneWidget);
      expect(find.text('× 2'), findsNWidgets(2));

      await tester.tap(find.text('3 players'));
      await pumpFor(tester);
      expect(find.text('14 Black Puzzles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
