import 'package:board_game_score_sheet/games/great_western_trail/gwt_2e_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_argentina_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_new_zealand_game.dart';
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

  test('Argentina fills three job market rows and covers cities', () {
    expect(GwtSetupHints.workerTiles(2, rows: 3), 5);
    expect(GwtSetupHints.workerTiles(3, rows: 3), 8);
    expect(GwtSetupHints.workerTiles(4, rows: 3), 11);
    expect(GwtSetupHints.pileShips, 7);
    for (final city in ['leHavre', 'rotterdam', 'liverpool']) {
      expect(GwtSetupHints.cityCovered(city, 2), isTrue);
      expect(GwtSetupHints.cityCovered(city, 3), city == 'rotterdam');
      expect(GwtSetupHints.cityCovered(city, 4), isFalse);
    }
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
    expect(find.text('Teepee (green or blue)'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-7')), findsOneWidget);

    await tester.tap(find.text('2 players'));
    await pumpFor(tester);
    expect(find.text('3 Workers in the Job Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-4')), findsNothing);
  });

  testWidgets('Argentina shows farmers, ships and city covers', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      const GwtSetupHintsScreen(
        game: GreatWesternTrailArgentinaGame(),
        art: GwtSetupHintsArt.argentina,
      ),
    );

    final order = [
      find.text('5 Farmer Tiles'),
      find.text('18 Ship Tiles'),
      find.byKey(const ValueKey('gwt-setup-players')),
      find.text('11 Workers in the Job Market'),
      find.text('3 City Maps'),
    ];
    for (var i = 1; i < order.length; i++) {
      expect(
        tester.getTopLeft(order[i - 1]).dy,
        lessThan(tester.getTopLeft(order[i]).dy),
      );
    }

    // Only the first section starts open.
    expect(find.text('Farmer (green, blue or orange)'), findsOneWidget);
    expect(find.text('Le Havre'), findsNothing);

    await tester.tap(find.text('5 Farmer Tiles'));
    await pumpFor(tester);
    expect(find.text('Farmer (green, blue or orange)'), findsNothing);

    await tester.tap(find.text('11 Workers in the Job Market'));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-setup-worker-11')), findsOneWidget);

    await tester.tap(find.text('3 City Maps'));
    await pumpFor(tester);
    expect(find.text('Return all cover tiles to the box.'), findsOneWidget);

    await tester.tap(find.text('3 players'));
    await pumpFor(tester);
    expect(find.text('8 Workers in the Job Market'), findsOneWidget);
    expect(find.text('3 City Maps, One Map Covered'), findsOneWidget);
    expect(
      find.textContaining('Cover the city center of Rotterdam'),
      findsOneWidget,
    );

    await tester.tap(find.text('2 players'));
    await pumpFor(tester);
    expect(find.text('3 City Maps, All Maps Covered'), findsOneWidget);

    final left = tester.getCenter(find.text('Le Havre'));
    final right = tester.getCenter(find.text('Liverpool'));
    expect(left.dx, lessThan(right.dx));
  });

  test('New Zealand draws 1 more A tile per player', () {
    const art = GwtSetupHintsArt.newZealand;
    expect(art.boardTilesFor(2), 12);
    expect(art.boardTilesFor(3), 13);
    expect(art.boardTilesFor(4), 14);
    expect(art.playersFirst, isTrue);
    expect(GwtSetupHintsArt.argentina.playersFirst, isFalse);
  });

  testWidgets('New Zealand fills the bonus tiles market', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      const GwtSetupHintsScreen(
        game: GreatWesternTrailNewZealandGame(),
        art: GwtSetupHintsArt.newZealand,
      ),
    );

    // The selector comes first, since it changes both sections.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('gwt-setup-players'))).dy,
      lessThan(tester.getTopLeft(find.text('14 Worker & Hazard Tiles')).dy),
    );
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Hazard (flood or rockfall)'), findsOneWidget);
    expect(find.text('7 Bonus Tiles in the Market'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-setup-worker-7')), findsOneWidget);

    await tester.tap(find.text('2 players'));
    await pumpFor(tester);
    expect(find.text('12 Worker & Hazard Tiles'), findsOneWidget);
    expect(find.text('3 Bonus Tiles in the Market'), findsOneWidget);
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
