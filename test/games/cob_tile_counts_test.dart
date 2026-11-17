import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_game.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_tile_counts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('matches the rulebook and the expansion tile lists', () {
    const none = <String>{};
    final all = CobTileCounts.allExpansions;
    expect(all, {'second', 'whiteCastles', 'inns'});

    expect(CobTileCounts.colouredTotal(none), 124);
    expect(CobTileCounts.black(none), 40);
    expect(CobTileCounts.total(none), 164);

    expect(CobTileCounts.coloured('buildings', all), 46);
    expect(CobTileCounts.coloured('monasteries', all), 23);
    expect(CobTileCounts.coloured('inns', all), 5);
    expect(CobTileCounts.coloured('inns', none), 0);
    expect(CobTileCounts.black(all), 44);
    expect(CobTileCounts.blackOf('buildings', none), 16);
    expect(CobTileCounts.blackOf('buildings', all), 19);
    expect(CobTileCounts.blackOf('livestock', all), 9);
    expect(CobTileCounts.blackOf('mines', all), 2);
    expect(CobTileCounts.blackOf('castles', all), 2);
    expect(CobTileCounts.baseBlack, 40);
    expect(CobTileCounts.total(all), 182);

    expect(
      {
        for (final e in CobTileCounts.expansions)
          e.key: CobTileCounts.tilesIn(e),
      },
      {'second': 4, 'whiteCastles': 9, 'inns': 5},
    );
    expect(CobTileCounts.silverCoins, 24);
    expect(CobTileCounts.workers, 26);
    expect(CobTileCounts.tradeGoods, 42);
    expect(CobTileCounts.shieldTiles, 18);
    expect(CobTileCounts.tradeRouteTiles, 12);
    expect(CobTileCounts.vineyardDoubleHexes, 51);
    expect(CobTileCounts.vineBonusTiles, 24);
    expect(
      const CastlesOfBurgundySpecialEditionGame().buildTileCounts(),
      isNotNull,
    );
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets('expansion switches start on and update the counts '
        '(${width.toInt()}px)', (tester) async {
      tester.view.physicalSize = Size(width, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> toggle(String key) async {
        await tester.tap(find.byKey(ValueKey('cob-tile-expansion-$key')));
        await pumpFor(tester);
      }

      await pumpWithL10n(tester, const CobTileCountsScreen());
      for (final key in CobTileCounts.toggles) {
        final toggle = tester.widget<Switch>(
          find.descendant(
            of: find.byKey(ValueKey('cob-tile-expansion-$key')),
            matching: find.byType(Switch),
          ),
        );
        // Hex tile expansions start on; the others start off.
        expect(
          toggle.value,
          CobTileCounts.otherExpansions.contains(key) ? isFalse : isTrue,
        );
      }

      // Extras show only the base components until their switches are on.
      expect(
        find.byKey(const ValueKey('cob-tile-counts-vineyards')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cob-tile-extra-shields')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('cob-tile-extra-tradeRoutes')),
        findsNothing,
      );
      expect(find.text('42'), findsOneWidget);
      await toggle('vineyards');
      await toggle('shields');
      await toggle('tradeRoutes');
      expect(find.text('51'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cob-tile-vineyards-bonus')),
        findsOneWidget,
      );
      expect(find.text('18'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('182 Hex Tiles'), findsOneWidget);
      expect(find.text('138'), findsOneWidget);
      expect(find.text('44'), findsOneWidget);
      expect(find.text('40 + 4'), findsOneWidget);
      expect(find.text('+2 monasteries', findRichText: true), findsNothing);
      expect(find.text('40 + 6'), findsOneWidget);
      expect(find.text('20 + 3'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cob-tile-coloured-inns')),
        findsOneWidget,
      );

      // The black market details start closed and open on tap.
      expect(
        find.byKey(const ValueKey('cob-tile-black-buildings')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('cob-tile-black-toggle')));
      await pumpFor(tester);
      final buildings = find.byKey(const ValueKey('cob-tile-black-buildings'));
      expect(
        find.descendant(of: buildings, matching: find.text('19')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: buildings, matching: find.text('16 + 3')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cob-tile-black-livestock')),
          matching: find.text('8 + 1'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('cob-tile-black-inns')), findsNothing);

      await toggle('inns');
      expect(
        find.byKey(const ValueKey('cob-tile-coloured-inns')),
        findsNothing,
      );
      expect(find.text('177 Hex Tiles'), findsOneWidget);

      await toggle('whiteCastles');
      expect(find.text('40 + 2'), findsOneWidget);
      expect(find.text('20 + 2'), findsOneWidget);
      expect(find.text('40 + 6'), findsNothing);

      await toggle('second');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('cob-tile-black-buildings')),
          matching: find.text('16'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('cob-tile-black-toggle')));
      await pumpFor(tester);
      expect(
        find.byKey(const ValueKey('cob-tile-black-buildings')),
        findsNothing,
      );
      expect(find.text('164 Hex Tiles'), findsOneWidget);
      expect(find.text('124'), findsOneWidget);
      expect(find.textContaining('40 + '), findsNothing);
      for (final (key, count) in [
        ('silver', '24'),
        ('workers', '26'),
        ('goods', '42'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('cob-tile-extra-$key')),
            matching: find.text(count),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
