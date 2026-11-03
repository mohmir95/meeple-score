import 'dart:math' as math;

import 'package:board_game_score_sheet/games/great_western_trail/gwt_el_paso_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_train_cards_randomizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('random draws always turn at least one card to the star side', () {
    final random = math.Random(1);
    for (var i = 0; i < 200; i++) {
      final sides = GwtTrainCards.random(random);
      expect(sides, hasLength(4));
      expect(sides, contains(true));
    }
    expect(GwtTrainCards.firstGame(), [false, false, false, false]);
    expect(
      GwtTrainCards.asset(1, star: true),
      'assets/games/great_western_trail_el_paso/icons/train-1-star.png',
    );
  });

  test('El Paso offers the train cards randomizer', () {
    const game = GreatWesternTrailElPasoGame();
    expect(game.showTrainCardsRandomizer, isTrue);
    expect(game.buildTrainCardsRandomizer(), isNotNull);
  });

  testWidgets('first game, flips and randomize', (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtTrainCardsRandomizerScreen(
        game: const GreatWesternTrailElPasoGame(),
        random: math.Random(3),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gwt-train-cards-first-game')));
    await pumpFor(tester);
    expect(find.text('0 of 4 cards on the ★ side'), findsOneWidget);
    expect(find.text('Front side'), findsNWidgets(4));
    expect(find.text('1 · Locomotive'), findsOneWidget);
    expect(find.text('4 · Wagon'), findsOneWidget);
    final randomize = find.byKey(const ValueKey('gwt-train-cards-randomize'));
    expect(tester.widget<FilledButton>(randomize).onPressed, isNull);

    // Turning a card over leaves first-game mode.
    await tester.tap(find.byKey(const ValueKey('gwt-train-card-3')));
    await pumpFor(tester);
    expect(find.text('1 of 4 cards on the ★ side'), findsOneWidget);
    expect(
      find.image(AssetImage(GwtTrainCards.asset(3, star: true))),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(randomize).onPressed, isNotNull);

    await tester.tap(randomize);
    await pumpFor(tester);
    expect(find.text('★ side'), findsWidgets);
    expect(find.text('0 of 4 cards on the ★ side'), findsNothing);

    // Locomotive first, wagons to its right, even in two rows.
    final one = tester.getTopLeft(
      find.byKey(const ValueKey('gwt-train-card-1')),
    );
    final two = tester.getTopLeft(
      find.byKey(const ValueKey('gwt-train-card-2')),
    );
    expect(one.dx, lessThan(two.dx));
    expect(tester.takeException(), isNull);
  });
}
