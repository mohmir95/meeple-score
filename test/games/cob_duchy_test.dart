import 'dart:math' as math;

import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_duchy.dart';
import 'package:board_game_score_sheet/games/castles_of_burgundy/cob_duchy_randomizer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

const _partners = {
  '1': '2',
  '2': '1',
  '3': '4',
  '4': '3',
  '5': '6',
  '6': '5',
  '7': '8',
  '8': '7',
  '9': '10',
  '10': '9',
  '11': '12',
  '12': '11',
  '13': '14',
  '14': '13',
  '15': '16',
  '16': '15',
  '17': '18',
  '18': '17',
  '19': '20',
  '20': '19',
  '21': '22',
  '22': '21',
  '23': '24',
  '24': '23',
  '25': '26',
  '26': '25',
  '27': '28',
  '28': '27',
  '29': '30',
  '30': '29',
  '33': '34',
  '34': '33',
};

void main() {
  test('base deal uses four copies of each double-sided board', () {
    for (var seed = 0; seed < 200; seed++) {
      final deal = dealCobDuchies(
        playerCount: 4,
        pool: CobDuchyPool.base,
        random: math.Random(seed),
      );
      expect(deal, hasLength(4));
      final copies = <String, int>{};
      for (final assignment in deal) {
        expect(_partners[assignment.boardId], assignment.otherSide);
        final pair = [assignment.boardId, assignment.otherSide]..sort();
        final key = pair.join('/');
        copies[key] = (copies[key] ?? 0) + 1;
      }
      for (final count in copies.values) {
        expect(count, lessThanOrEqualTo(4));
      }
    }
  });

  test('a first game gives every player the same beginner side', () {
    final seen = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final deal = dealCobDuchies(
        playerCount: 4,
        pool: CobDuchyPool.base,
        firstGame: true,
        random: math.Random(seed),
      );
      expect(
        deal.map((assignment) => assignment.boardId).toSet(),
        hasLength(1),
      );
      expect(deal.first.boardId, anyOf('1', '2'));
      expect(deal.first.otherSide, _partners[deal.first.boardId]);
      seen.add(deal.first.boardId);
    }
    expect(seen, {'1', '2'});
  });

  test('expansion deals stay on the printed numbers', () {
    void expectFaces(CobDuchyPool pool, Set<String> faces) {
      for (var seed = 0; seed < 30; seed++) {
        final deal = dealCobDuchies(
          playerCount: 4,
          pool: pool,
          random: math.Random(seed),
        );
        final copies = <String, int>{};
        for (final assignment in deal) {
          expect(faces, contains(assignment.boardId));
          expect(assignment.otherSide, _partners[assignment.boardId]);
          final pair = [assignment.boardId, assignment.otherSide]..sort();
          final key = pair.join('/');
          copies[key] = (copies[key] ?? 0) + 1;
        }
        for (final count in copies.values) {
          expect(count, lessThanOrEqualTo(4));
        }
      }
    }

    expectFaces(CobDuchyPool.firstExpansion, {
      for (var number = 11; number <= 18; number++) '$number',
    });
    expectFaces(CobDuchyPool.championship, {'19', '20'});
    expectFaces(CobDuchyPool.specialEdition, {'21', '22'});
    expectFaces(CobDuchyPool.borderPosts, {
      for (var number = 23; number <= 30; number++) '$number',
    });
  });

  test('solo deal is side 33 or 34', () {
    final sides = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final deal = dealCobDuchies(
        playerCount: 1,
        pool: CobDuchyPool.solo,
        random: math.Random(seed),
      );
      expect(deal, hasLength(1));
      expect(deal.single.otherSide, _partners[deal.single.boardId]);
      sides.add(deal.single.boardId);
    }
    expect(sides, {'33', '34'});
  });

  test('both teams receive the same team board', () {
    final sides = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final deal = dealCobDuchies(
        playerCount: 2,
        pool: CobDuchyPool.team,
        random: math.Random(seed),
      );
      expect(deal, hasLength(2));
      expect(deal[0].boardId, deal[1].boardId);
      expect(deal[0].boardId, anyOf('31a & 32a', '31b & 32b'));
      expect(deal[0].flipped().boardId, deal[0].otherSide);
      sides.add(deal[0].boardId);
    }
    expect(sides, {'31a & 32a', '31b & 32b'});
  });

  test('rejects a player count the setup does not use', () {
    expect(
      () => dealCobDuchies(playerCount: 1, pool: CobDuchyPool.base),
      throwsArgumentError,
    );
    expect(
      () => dealCobDuchies(playerCount: 5, pool: CobDuchyPool.base),
      throwsArgumentError,
    );
    expect(
      () => dealCobDuchies(playerCount: 2, pool: CobDuchyPool.solo),
      throwsArgumentError,
    );
    expect(
      () => dealCobDuchies(playerCount: 4, pool: CobDuchyPool.team),
      throwsArgumentError,
    );
    expect(
      () => dealCobDuchies(
        playerCount: 2,
        pool: CobDuchyPool.firstExpansion,
        firstGame: true,
      ),
      throwsArgumentError,
    );
  });

  test('the same seed deals the same duchies', () {
    final first = dealCobDuchies(
      playerCount: 3,
      pool: CobDuchyPool.base,
      random: math.Random(19),
    );
    final second = dealCobDuchies(
      playerCount: 3,
      pool: CobDuchyPool.base,
      random: math.Random(19),
    );
    expect(
      first.map(
        (assignment) => '${assignment.boardId}:${assignment.otherSide}',
      ),
      second.map(
        (assignment) => '${assignment.boardId}:${assignment.otherSide}',
      ),
    );
  });

  testWidgets('hub opens the duchy board randomizer', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(tester, find.text('Special Edition'));
    await tester.tap(find.text('Special Edition'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Duchy Board Randomizer'));
    await tester.tap(find.text('Duchy Board Randomizer'));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('cob-duchy-randomize')),
    );

    expect(find.text('Base game'), findsOneWidget);
    expect(find.text('1st Expansion'), findsOneWidget);
    expect(find.text('Championship'), findsOneWidget);
    expect(find.text('Border Posts'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-card-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-card-2')), findsNothing);
    expect(find.text('Tap a board to choose its other side.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('cob-duchy-first-game')));
    await pumpFor(tester);
    expect(find.textContaining('center space numbered 6'), findsOneWidget);

    await tester.tap(find.byTooltip('Add player'));
    await pumpFor(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuItem<int>),
        matching: find.text('Yellow'),
      ),
    );
    await pumpFor(tester);
    await tester.tap(find.byTooltip('Add player'));
    await pumpFor(tester);
    expect(find.byType(PopupMenuItem<int>), findsNothing);
    expect(find.byTooltip('Purple'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cob-duchy-pool-border')));
    await pumpFor(tester);
    expect(find.textContaining('23–30'), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-card-3')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cob-duchy-pool-team')));
    await pumpFor(tester);
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(find.textContaining('31'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cob-duchy-pool-solo')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('cob-duchy-card-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-card-1')), findsNothing);
    expect(
      find.text('33').evaluate().isNotEmpty ||
          find.text('34').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byKey(const ValueKey('cob-duchy-turn-order')), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('duchy randomizer screen shows a seeded deal', (tester) async {
    final deal = dealCobDuchies(
      playerCount: 2,
      pool: CobDuchyPool.base,
      random: math.Random(7),
    );

    await pumpWithL10n(
      tester,
      CobDuchyRandomizerScreen(random: math.Random(7)),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('cob-duchy-card-1')),
    );

    expect(find.text(deal[0].boardId), findsWidgets);
    expect(find.text(deal[1].boardId), findsWidgets);
    expect(find.byKey(const ValueKey('cob-duchy-card-2')), findsNothing);
    expect(find.byTooltip('Red'), findsOneWidget);
    expect(find.byTooltip('Blue'), findsOneWidget);
    expect(find.byTooltip('Add player'), findsOneWidget);

    await tester.tap(find.byTooltip('Red'));
    await pumpFor(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuItem<int>),
        matching: find.text('Purple'),
      ),
    );
    await pumpFor(tester);

    expect(find.byTooltip('Purple'), findsOneWidget);
    expect(find.byTooltip('Blue'), findsOneWidget);
    expect(find.text('Purple'), findsWidgets);

    await tester.tap(find.byTooltip('Purple'));
    await pumpFor(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(PopupMenuItem<int>),
        matching: find.text('Blue'),
      ),
    );
    await pumpFor(tester);

    expect(find.byTooltip('Blue'), findsOneWidget);
    expect(find.byTooltip('Purple'), findsOneWidget);
    expect(find.text('Blue'), findsWidgets);
    expect(find.text('Purple'), findsWidgets);
  });

  testWidgets('duchy tiles are square and turn order settles', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      CobDuchyRandomizerScreen(random: math.Random(7)),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('cob-duchy-card-0')),
    );

    final cardSize = tester.getSize(
      find.byKey(const ValueKey('cob-duchy-card-0')),
    );
    expect(cardSize.height, closeTo(cardSize.width, 1));

    final cardTop = tester
        .getTopLeft(find.byKey(const ValueKey('cob-duchy-card-0')))
        .dy;
    final randomizeTop = tester
        .getTopLeft(find.byKey(const ValueKey('cob-duchy-randomize')))
        .dy;
    expect(randomizeTop, greaterThan(cardTop));
    expect(find.byKey(const ValueKey('cob-duchy-turn-order')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('cob-duchy-turn-order')),
    );
    await tester.tap(find.byKey(const ValueKey('cob-duchy-turn-order')));
    await tester.pump();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(find.byKey(const ValueKey('cob-duchy-card-0')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('cob-duchy-order-settled')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cob-duchy-rank-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cob-duchy-rank-1')), findsOneWidget);
    expect(find.text('1st'), findsOneWidget);
    expect(find.text('2nd'), findsOneWidget);
    expect(find.text('3rd'), findsNothing);
  });

  testWidgets('four duchy tiles stay on one row on a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      const CobDuchyRandomizerScreen(initialPlayerCount: 4),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('cob-duchy-card-3')),
    );

    final tops = [
      for (var i = 0; i < 4; i++)
        tester.getTopLeft(find.byKey(ValueKey('cob-duchy-card-$i'))).dy,
    ];
    expect(tops.every((top) => (top - tops.first).abs() < 1), isTrue);
  });
}
