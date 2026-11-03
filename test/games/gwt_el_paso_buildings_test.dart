import 'dart:math' as math;

import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_buildings_screen.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('random sides turn at least one stack to b', () {
    final random = math.Random(4);
    for (var i = 0; i < 200; i++) {
      final sides = GwtElPasoBuildings.randomSides(random);
      expect(sides, hasLength(6));
      expect(sides, contains('b'));
    }
    expect(GwtElPasoBuildings.firstGameSides(), everyElement('a'));
  });

  test('neutral tiles are a permutation of B to G', () {
    final random = math.Random(5);
    for (var i = 0; i < 50; i++) {
      final tiles = GwtElPasoBuildings.randomNeutral(random);
      expect([...tiles]..sort(), GwtElPasoBuildings.neutralSpaces);
    }
    expect(
      GwtElPasoBuildings.firstGameNeutral(),
      GwtElPasoBuildings.neutralSpaces,
    );
  });

  testWidgets('common stacks: first game and randomize', (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtElPasoBuildingsScreen(
        game: const GreatWesternTrailElPasoGame(),
        random: math.Random(1),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gwtep-common-first-game')));
    await pumpFor(tester);
    for (var stack = 1; stack <= 6; stack++) {
      expect(
        find.image(AssetImage(GwtElPasoBuildings.commonAsset(stack, 'a'))),
        findsOneWidget,
      );
    }
    final randomize = find.byKey(const ValueKey('gwtep-common-randomize'));
    expect(tester.widget<FilledButton>(randomize).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('gwtep-common-first-game')));
    await pumpFor(tester);
    expect(tester.widget<FilledButton>(randomize).onPressed, isNotNull);
    // Leaving first-game mode draws again, with at least one b-side.
    var bSides = 0;
    for (var stack = 1; stack <= 6; stack++) {
      final b = AssetImage(GwtElPasoBuildings.commonAsset(stack, 'b'));
      bSides += find.image(b).evaluate().length;
    }
    expect(bSides, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('neutral tiles follow the letters in a first game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtElPasoBuildingsScreen(
        game: const GreatWesternTrailElPasoGame(),
        random: math.Random(1),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('gwtep-tab-neutral')));
    await pumpFor(tester);

    expect(find.byKey(const ValueKey('gwtep-el-paso-tile')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('gwtep-neutral-first-game')));
    await pumpFor(tester);
    for (final space in GwtElPasoBuildings.neutralSpaces) {
      final tile = find.byKey(ValueKey('gwtep-space-$space'));
      expect(
        find.descendant(
          of: tile,
          matching: find.image(
            AssetImage(GwtElPasoBuildings.neutralAsset(space)),
          ),
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
