import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('matches setup steps 5 and 12 of the El Paso rulebook', () {
    expect(GwtElPasoSetup.tilesPerPile, 20);
    expect(GwtElPasoSetup.faceUpPerPile, 3);
    expect(
      {for (final c in GwtElPasoSetup.herd) c.key: c.count},
      {'criollo': 4, 'pineywoods': 2, 'galloway': 2, 'santaGertrudis': 2},
    );
    expect(GwtElPasoSetup.herdSize, 10);
    expect(GwtElPasoSetup.startingHand, 4);
    const game = GreatWesternTrailElPasoGame();
    expect(game.showSetupHints, isTrue);
    expect(game.buildSetupHints(), isNotNull);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('shows the train supply and herd deck (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(
        tester,
        const GwtElPasoSetupHintsScreen(game: GreatWesternTrailElPasoGame()),
      );
      expect(find.text('Train Supply'), findsOneWidget);
      expect(find.text('× 20'), findsNWidgets(2));
      expect(
        find.image(const AssetImage(GwtElPasoSetup.objectiveAsset)),
        findsNWidgets(6),
      );
      expect(
        find.image(const AssetImage(GwtElPasoSetup.bonusAsset)),
        findsNWidgets(6),
      );
      expect(find.text('3 face up'), findsNWidgets(2));
      expect(find.text('Herd Deck (10 Cards)'), findsOneWidget);
      expect(find.text('× 4'), findsOneWidget);
      expect(find.text('× 2'), findsNWidgets(3));
      expect(find.text('Green Santa Gertrudis'), findsOneWidget);
      for (final breed in GwtElPasoSetup.herd) {
        expect(find.image(AssetImage(breed.asset)), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
