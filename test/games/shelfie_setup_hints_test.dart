import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('matches the rulebook setup for each player count', () {
    expect(ShelfieSetup.diceInBag(4), 88);
    expect(ShelfieSetup.removedPerColor(4), 0);
    expect(ShelfieSetup.removedPerColor(3), 5);
    expect(ShelfieSetup.diceInBag(3), 68);
    expect(ShelfieSetup.removedPerColor(2), 10);
    expect(ShelfieSetup.diceInBag(2), 48);
    expect(ShelfieSetup.diceInBag(1), 48);
    for (var players = 1; players <= 4; players++) {
      expect(ShelfieSetup.deliveryBoxes(players), players + 1);
    }
    expect(
      ShelfieSetupHintsScreen.boxAssets.length,
      greaterThanOrEqualTo(ShelfieSetup.deliveryBoxes(4)),
    );
  });

  testWidgets('switching the player count updates boxes and dice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(tester, const ShelfieSetupHintsScreen());

    expect(find.text('5 Delivery Boxes'), findsOneWidget);
    expect(find.text('88 Dice in the Bag'), findsOneWidget);
    expect(find.text('× 22'), findsNWidgets(4));
    expect(find.text('−5 to the box'), findsNothing);

    await tester.tap(find.text('3 players'));
    await pumpFor(tester);
    expect(find.text('4 Delivery Boxes'), findsOneWidget);
    expect(find.text('68 Dice in the Bag'), findsOneWidget);
    expect(find.text('× 17'), findsNWidgets(4));
    expect(find.text('−5 to the box'), findsNWidgets(4));

    await tester.tap(find.text('Solo'));
    await pumpFor(tester);
    expect(find.text('2 Delivery Boxes'), findsOneWidget);
    expect(find.text('48 Dice in the Bag'), findsOneWidget);
    expect(find.text('× 12'), findsNWidgets(4));
  });
}
