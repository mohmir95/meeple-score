import 'dart:math' as math;

import 'package:board_game_score_sheet/games/great_western_trail/gwt_argentina_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_city_maps_randomizer_screen.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_setup_hints_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  Finder cover(String city) => find.byKey(ValueKey('gwt-city-cover-$city'));

  test('maps are drawn per city and a first game uses every a-side', () {
    expect(GwtCityMaps.firstGame().values.toSet(), {'a'});

    final seen = <String>{};
    final random = math.Random(1);
    for (var i = 0; i < 50; i++) {
      final sides = GwtCityMaps.random(random);
      expect(sides.keys, GwtSetupHints.cities);
      seen.addAll(sides.values);
    }
    expect(seen, {'a', 'b'});
    expect(
      GwtCityMaps.mapAsset('leHavre', 'b'),
      endsWith('/map-le-havre-b.jpg'),
    );
  });

  testWidgets('the player count places the cover tiles', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtCityMapsRandomizerScreen(
        game: const GreatWesternTrailArgentinaGame(),
        random: math.Random(1),
      ),
    );

    for (final city in GwtSetupHints.cities) {
      expect(cover(city), findsNothing);
    }

    await tester.tap(find.text('3 players'));
    await pumpFor(tester);
    expect(cover('rotterdam'), findsOneWidget);
    expect(cover('leHavre'), findsNothing);
    expect(cover('liverpool'), findsNothing);

    await tester.tap(find.text('2 players'));
    await pumpFor(tester);
    for (final city in GwtSetupHints.cities) {
      expect(cover(city), findsOneWidget);
    }
  });

  testWidgets('a thumbnail brings its city up with or without its cover', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtCityMapsRandomizerScreen(
        game: const GreatWesternTrailArgentinaGame(),
        random: math.Random(1),
      ),
    );

    // The whole page fits a phone without scrolling.
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);

    final bigCover = find.byKey(const ValueKey('gwt-city-cover-big'));
    await tester.tap(find.text('3'));
    await pumpFor(tester);
    expect(bigCover, findsNothing);

    await tester.tap(find.byKey(const ValueKey('gwt-city-thumb-rotterdam')));
    await pumpFor(tester);
    expect(bigCover, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gwt-city-thumb-liverpool')));
    await pumpFor(tester);
    expect(bigCover, findsNothing);
  });

  testWidgets('first game locks the a-sides until it is turned off', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      GwtCityMapsRandomizerScreen(
        game: const GreatWesternTrailArgentinaGame(),
        random: math.Random(1),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('gwt-city-maps-first-game')));
    await pumpFor(tester);
    // Le Havre is the big map as well as a thumbnail.
    expect(find.text('Le Havre: Side A'), findsNWidgets(2));
    expect(find.text('Rotterdam: Side A'), findsOneWidget);
    expect(find.text('Liverpool: Side A'), findsOneWidget);

    final button = find.byKey(const ValueKey('gwt-city-maps-randomize'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('gwt-city-maps-first-game')));
    await pumpFor(tester);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });
}
