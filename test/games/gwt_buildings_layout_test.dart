import 'dart:math';

import 'package:board_game_score_sheet/games/great_western_trail/gwt_buildings_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeded random picks A or B for all ten buildings', () {
    final layout = GwtBuildingsLayout.random(random: Random(42));

    expect(layout.sides, hasLength(10));
    expect(layout.sides, contains(GwtBuildingSide.a));
    expect(layout.sides, contains(GwtBuildingSide.b));
    expect(GwtBuildingsLayout.random(random: Random(42)), layout);
  });

  test('Rails to the North adds buildings 11 and 12', () {
    final base = GwtBuildingsLayout.random(random: Random(1));
    expect(base.sides, hasLength(10));
    expect(base.includesRailsToTheNorth, isFalse);

    final expanded = base.withRailsToTheNorth(true, Random(2));
    expect(expanded.sides, hasLength(12));
    expect(expanded.includesRailsToTheNorth, isTrue);
    expect(expanded.sides.sublist(0, 10), base.sides);
    expect(expanded.withRailsToTheNorth(false).sides, base.sides);
    expect(
      GwtBuildingsLayout.random(
        random: Random(42),
        railsToTheNorth: true,
      ).sides,
      hasLength(12),
    );
  });

  test('13th Building adds building 13 without requiring Rails', () {
    final base = GwtBuildingsLayout.random(random: Random(1));
    final thirteenth = base.withThirteenthBuilding(true, Random(3));

    expect(thirteenth.sides, hasLength(11));
    expect(thirteenth.visibleNumbers, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13,
    ]);
    expect(thirteenth.includesThirteenthBuilding, isTrue);
    expect(thirteenth.includesRailsToTheNorth, isFalse);
    expect(thirteenth.sides.sublist(0, 10), base.sides);

    final both = thirteenth.withRailsToTheNorth(true, Random(4));
    expect(both.visibleNumbers, [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
    ]);
    expect(both.sideOf(13), thirteenth.sideOf(13));
    expect(both.withRailsToTheNorth(false).visibleNumbers, thirteenth.visibleNumbers);
  });
}
