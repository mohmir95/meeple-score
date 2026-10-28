import 'package:board_game_score_sheet/games/great_western_trail/gwt_2e_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('job market fills 3 to 7 workers by player count', () {
    expect(GwtSetupHints.workerTiles(2), 3);
    expect(GwtSetupHints.workerTiles(3), 5);
    expect(GwtSetupHints.workerTiles(4), 7);
    expect(GwtSetupHints.kansasCityTiles, 7);
  });

  testWidgets('switching the player count updates the job market', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      const GwtSetupHintsScreen(
        game: GreatWesternTrailGame(),
        art: GwtSetupHintsArt.firstEdition,
      ),
    );

    expect(find.text('7 Kansas City Tiles'), findsOneWidget);
    expect(find.text('Teepee (green or blue)'), findsOneWidget);
    expect(find.text('7 Workers in the Job Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-7')), findsOneWidget);

    await tester.tap(find.text('2 players'));
    await pumpFor(tester);
    expect(find.text('3 Workers in the Job Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-4')), findsNothing);
  });

  testWidgets('Second Edition places outlaws and skips solo', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      const GwtSetupHintsScreen(
        game: GreatWesternTrailSecondEditionGame(),
        art: GwtSetupHintsArt.secondEdition,
      ),
    );

    expect(find.text('Outlaw (green or orange)'), findsOneWidget);
    expect(find.text('Teepee (green or blue)'), findsNothing);
    expect(find.text('1 players'), findsNothing);
    expect(find.text('7 Workers in the Job Market'), findsOneWidget);
  });
}
