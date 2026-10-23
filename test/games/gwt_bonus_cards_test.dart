import 'dart:math' as math;

import 'package:board_game_score_sheet/games/great_western_trail/gwt_bonus_cards.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_bonus_cards_randomizer_screen.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_new_zealand_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('draws 4 distinct sets from 1–10 in ascending order', () {
    final random = math.Random(7);
    for (var i = 0; i < 200; i++) {
      final sets = GwtBonusCardsSupply.random(random).sets;
      expect(sets, hasLength(4));
      expect(sets.toSet(), hasLength(4));
      expect(sets.every((set) => set >= 1 && set <= 10), isTrue);
      expect(sets, [...sets]..sort());
    }
  });

  test('stack size follows the player count', () {
    expect(GwtBonusCardsSupply.cardsPerSet(2), 3);
    expect(GwtBonusCardsSupply.cardsPerSet(3), 5);
    expect(GwtBonusCardsSupply.cardsPerSet(4), 6);
  });

  test(
    'lowest set goes below the steering wheel, highest below the compass',
    () {
      final supply = GwtBonusCardsSupply([2, 5, 7, 10]);
      expect(supply.setFor(GwtBonusTile.steeringWheel), 2);
      expect(supply.setFor(GwtBonusTile.barrel), 5);
      expect(supply.setFor(GwtBonusTile.bell), 7);
      expect(supply.setFor(GwtBonusTile.compass), 10);
    },
  );

  testWidgets('shows each tile with its set and stack size', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      GwtBonusCardsRandomizerScreen(
        game: const GreatWesternTrailNewZealandGame(),
        initialSupply: GwtBonusCardsSupply([2, 5, 7, 10]),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-bonus-randomize')),
    );

    for (final (tile, set) in [
      (GwtBonusTile.steeringWheel, 2),
      (GwtBonusTile.barrel, 5),
      (GwtBonusTile.bell, 7),
      (GwtBonusTile.compass, 10),
    ]) {
      final stack = find.byKey(ValueKey('gwt-bonus-${tile.key}'));
      expect(
        find.descendant(of: stack, matching: find.text('Set $set')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: stack,
          matching: find.image(AssetImage(GwtBonusCardsSupply.cardAsset(set))),
        ),
        findsOneWidget,
      );
    }
    expect(find.textContaining('gold'), findsNothing);
    expect(find.text('3 cards'), findsNWidgets(4));

    await tester.tap(find.text('4 players'));
    await pumpFor(tester);
    expect(find.text('6 cards'), findsNWidgets(4));

    await tester.tap(find.byKey(const ValueKey('gwt-bonus-randomize')));
    await pumpFor(tester);
    expect(find.textContaining(RegExp(r'^Set \d+$')), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 900), const Size(412, 1000)]) {
    testWidgets('fits a ${size.width.toInt()}px phone', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWithL10n(
        tester,
        const GwtBonusCardsRandomizerScreen(
          game: GreatWesternTrailNewZealandGame(),
        ),
      );
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('gwt-bonus-randomize')),
      );
      // Two stacks per row on a phone, each capped in width.
      final tops = {
        for (final tile in GwtBonusTile.values)
          tester.getTopLeft(find.byKey(ValueKey('gwt-bonus-${tile.key}'))).dy,
      };
      expect(tops, hasLength(2));
      final stack = tester.getSize(
        find.byKey(const ValueKey('gwt-bonus-bell')),
      );
      expect(stack.width, lessThanOrEqualTo(180));
      if (size.width >= 412) {
        // With room to spare, both rows fit the area without scrolling.
        final area = tester.getRect(find.byType(SingleChildScrollView).last);
        final bottom = tester
            .getBottomLeft(find.byKey(const ValueKey('gwt-bonus-compass')))
            .dy;
        expect(bottom, lessThanOrEqualTo(area.bottom));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
