import 'package:board_game_score_sheet/games/alchemists/alchemists_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String row, String text) => find.descendant(
  of: find.byKey(ValueKey('alchemists-setup-$row')),
  matching: find.text(text),
);

void main() {
  test('matches the Player\'s Laboratory rulebook page', () {
    expect(AlchemistsSetup.actionCubes(2), 6);
    expect(AlchemistsSetup.actionCubes(3), 5);
    expect(AlchemistsSetup.actionCubes(4), 4);
    expect(AlchemistsSetup.firstRoundCubes, 3);
    expect(AlchemistsSetup.gold, 2);
    expect(AlchemistsSetup.ingredients(master: false), 3);
    expect(AlchemistsSetup.ingredients(master: true), 2);
    expect(
      AlchemistsSetup.hedgeSeals.length * AlchemistsSetup.hedgeSealsPerColour,
      6,
    );
    expect(AlchemistsSetup.starSeals.map((s) => s.count), [3, 2]);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('player count and variant update the counts '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const AlchemistsStartingResourcesScreen());
      expect(_in('cubes', '4'), findsOneWidget);
      expect(_in('ingredients', '3'), findsOneWidget);
      expect(_in('gold', '2'), findsOneWidget);
      expect(_in('favors', 'Favor cards: draw 2, keep 1'), findsOneWidget);
      expect(_in('favors', '1'), findsOneWidget);
      expect(_in('hedge', '6'), findsOneWidget);

      await tester.tap(find.text('2 players'));
      await pumpFor(tester);
      expect(_in('cubes', '6'), findsOneWidget);
      expect(
        find.textContaining('Put the other 3 on the adventurer stack'),
        findsOneWidget,
      );

      await tester.tap(find.text('Master'));
      await pumpFor(tester);
      expect(_in('ingredients', '2'), findsOneWidget);
      // The old value animates out; after it settles only the new one shows.
      await tester.pump(const Duration(milliseconds: 400));
      expect(_in('ingredients', '3'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
