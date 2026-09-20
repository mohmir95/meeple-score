import 'dart:math';

import 'package:board_game_score_sheet/games/great_western_trail/gwt_public_buildings_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first game places each public tile on its own letter', () {
    final layout = GwtPublicBuildingsLayout.firstGame();

    expect(layout.tiles, GwtPublicBuildingsLayout.classicLocations);
    expect(layout.tileOn('A'), 'A');
    expect(layout.tileOn('G'), 'G');
  });

  test('random public setup is a permutation of A–G', () {
    final layout = GwtPublicBuildingsLayout.random(Random(42));

    expect(layout.tiles, hasLength(7));
    expect(
      layout.tiles.toSet(),
      GwtPublicBuildingsLayout.classicLocations.toSet(),
    );
    expect(GwtPublicBuildingsLayout.random(Random(42)), layout);
  });

  test('Argentina random public setup is a permutation of A–H', () {
    final layout = GwtPublicBuildingsLayout.random(
      Random(42),
      GwtPublicBuildingsLayout.argentinaLocations,
    );

    expect(layout.tiles, hasLength(8));
    expect(layout.locations, GwtPublicBuildingsLayout.argentinaLocations);
    expect(
      layout.tiles.toSet(),
      GwtPublicBuildingsLayout.argentinaLocations.toSet(),
    );
    expect(layout.tileOn('H'), isNotEmpty);
  });
}
