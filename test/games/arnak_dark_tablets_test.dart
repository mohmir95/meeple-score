import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_altars_dialog.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_config.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_dark_tablets.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_player_line.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_scoring.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_sheet.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  const red = Player(id: 'red', name: 'Red', colorValue: 0xFFC62828);
  const blue = Player(id: 'blue', name: 'Blue', colorValue: 0xFF1565C0);
  const players = [red, blue];

  ArnakState game({bool spiderTemple = true, Map<String, List<int>>? altars}) {
    return ArnakState(
      players: players,
      config: const ArnakConfig(),
      status: GameStatus.inProgress,
      lines: const {
        'red': ArnakPlayerLine(research: 10),
        'blue': ArnakPlayerLine(research: 10),
      },
      spiderTemple: spiderTemple,
      altarTablets: altars,
    );
  }

  group('dark tablet cost', () {
    test('matches the worked 2-player example', () {
      // Red used 3, Blue used 2: 5 ~/ 2 = 2 spaces emptied -> -2 each.
      final altars = {
        'red': [3, 0, 0, 0, 0],
        'blue': [0, 2, 0, 0, 0],
      };
      expect(ArnakDarkTablets.supplySize(2), 14);
      expect(ArnakDarkTablets.emptiedSpaces(players, altars), 2);
      expect(ArnakDarkTablets.pointsPerTablet(players, altars), -2);

      final results = ArnakDarkTablets.results(players, altars);
      expect(results['red']!.tabletPoints, -6);
      expect(results['blue']!.tabletPoints, -4);
    });

    test('costs nothing until a whole supply space is empty', () {
      final altars = {
        'red': [1, 0, 0, 0, 0],
        'blue': [0, 0, 0, 0, 0],
      };
      expect(ArnakDarkTablets.emptiedSpaces(players, altars), 0);
      expect(ArnakDarkTablets.pointsPerTablet(players, altars), 0);
    });

    test('never goes past the last supply space', () {
      final altars = {
        'red': [3, 3, 3, 3, 3],
        'blue': [3, 3, 3, 3, 3],
      };
      expect(ArnakDarkTablets.emptiedSpaces(players, altars), 7);
      expect(ArnakDarkTablets.pointsPerTablet(players, altars), -5);
    });
  });

  test('altars sit on research rows 1, 2, 3, 5 and 6', () {
    expect(ArnakDarkTablets.altarRows, [1, 2, 3, 5, 6]);
    expect(ArnakDarkTablets.altarValues, [2, 2, 3, 3, 4]);
  });

  group('altar majorities', () {
    test('the most tablets wins the altar; ties are friendly', () {
      final altars = {
        // Altars are worth 2, 2, 3, 3, 4.
        'red': [2, 1, 1, 0, 0],
        'blue': [1, 1, 0, 0, 3],
      };
      final results = ArnakDarkTablets.results(players, altars);
      // Red: altar 1 (2) + tie on altar 2 (2) + altar 3 (3).
      expect(results['red']!.altarPoints, 7);
      // Blue: tie on altar 2 (2) + altar 5 (4).
      expect(results['blue']!.altarPoints, 6);
    });

    test('an altar nobody used scores nothing', () {
      final altars = {
        'red': [0, 0, 0, 0, 0],
        'blue': [0, 0, 0, 0, 0],
      };
      expect(ArnakDarkTablets.altarWinners(players, altars, 4), isEmpty);
    });

    test('totals combine majorities and tablet cost', () {
      final altars = {
        'red': [3, 0, 0, 0, 0],
        'blue': [0, 2, 0, 0, 0],
      };
      final results = ArnakDarkTablets.results(players, altars);
      expect(results['red']!.total, 2 - 6);
      expect(results['blue']!.total, 2 - 4);
    });
  });

  group('pad scoring', () {
    final altars = {
      'red': [3, 0, 0, 0, 0],
      'blue': [0, 2, 0, 0, 0],
    };

    test('dark tablets are unscored until the altars are saved', () {
      expect(ArnakScoring.darkTabletsFor(game(), 'red'), isNull);
      expect(ArnakScoring.totalForPlayer(game(), 'red'), 10);
    });

    test('dark tablets count toward the total only with Spider Temple', () {
      expect(ArnakScoring.darkTabletsFor(game(altars: altars), 'red'), -4);
      expect(ArnakScoring.totalForPlayer(game(altars: altars), 'red'), 6);
      expect(ArnakScoring.totalForPlayer(game(altars: altars), 'blue'), 8);

      final off = game(spiderTemple: false, altars: altars);
      expect(ArnakScoring.darkTabletsFor(off, 'red'), isNull);
      expect(ArnakScoring.totalForPlayer(off, 'red'), 10);
    });

    test('dark tablets break what would be a tie', () {
      expect(ArnakScoring.winners(game(altars: altars)), [blue]);
    });

    test('Spider Temple state survives a save and reload', () {
      final restored = ArnakState.fromJson(game(altars: altars).toJson());
      expect(restored.spiderTemple, isTrue);
      expect(restored.altarTablets, altars);
      expect(ArnakState.fromJson(game().toJson()).altarTablets, isNull);
    });
  });

  testWidgets('Spider Temple adds a Dark Tablets row scored from the altars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    var state = game(spiderTemple: false);
    await pumpWithL10n(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => ArnakSheet(
              state: state,
              readOnly: false,
              onChanged: (next) => setState(() => state = next),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('arnak-dark-tablets-row')), findsNothing);
    expect(find.byKey(const ValueKey('arnak-altars-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('arnak-spider-temple')));
    await pumpFor(tester);
    final row = find.byKey(const ValueKey('arnak-dark-tablets-row'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('—')),
      findsNWidgets(2),
    );

    // Tapping a Dark Tablets cell opens the altars dialog.
    await tester.tap(find.descendant(of: row, matching: find.text('—')).first);
    await pumpFor(tester);
    expect(find.text('Altars & Dark Tablets'), findsOneWidget);

    Future<void> add(int altar, String playerId, int times) async {
      final plus = find.descendant(
        of: find.byKey(ValueKey('arnak-altar-$altar-$playerId')),
        matching: find.byIcon(Icons.add),
      );
      for (var i = 0; i < times; i++) {
        await tester.tap(plus);
        await tester.pump();
      }
    }

    await add(0, 'red', 3);
    await add(1, 'blue', 2);
    int net(String playerId) => tester
        .widget<ArnakVpGem>(find.byKey(ValueKey('arnak-altars-net-$playerId')))
        .value;
    expect(net('red'), -4);
    expect(net('blue'), -2);

    await tester.tap(find.byKey(const ValueKey('arnak-altars-save')));
    await pumpFor(tester);
    expect(state.altarTablets, {
      'red': [3, 0, 0, 0, 0],
      'blue': [0, 2, 0, 0, 0],
    });
    expect(find.descendant(of: row, matching: find.text('-4')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a scored zero shows as 0 in the Dark Tablets row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ArnakSheet(
            state: game(
              altars: {
                'red': [0, 0, 0, 0, 0],
                'blue': [0, 0, 0, 0, 0],
              },
            ),
            readOnly: false,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final row = find.byKey(const ValueKey('arnak-dark-tablets-row'));
    expect(
      find.descendant(of: row, matching: find.text('0')),
      findsNWidgets(2),
    );
    expect(find.descendant(of: row, matching: find.text('—')), findsNothing);
  });

  testWidgets('total shows 0 once dark tablets are scored, blank before', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Nobody has other points, and the altars are scored with no tablets.
    var state = ArnakState(
      players: players,
      config: const ArnakConfig(),
      status: GameStatus.inProgress,
      lines: const {},
      spiderTemple: true,
    );
    late StateSetter rebuild;
    await pumpWithL10n(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return ArnakSheet(
                state: state,
                readOnly: false,
                onChanged: (_) {},
              );
            },
          ),
        ),
      ),
    );

    Finder totalCells() =>
        find.descendant(of: find.byType(ArnakSheet), matching: find.text('0'));
    expect(totalCells(), findsNothing);

    rebuild(
      () => state = state.copyWith(
        altarTablets: {
          'red': [0, 0, 0, 0, 0],
          'blue': [0, 0, 0, 0, 0],
        },
      ),
    );
    await pumpFor(tester);
    // Dark Tablets row and Total row both show 0 for each player.
    expect(totalCells(), findsNWidgets(4));
  });

  testWidgets('altars dialog fits a phone with four players', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final four = [
      for (final (id, color) in [
        ('red', 0xFFC62828),
        ('blue', 0xFF1565C0),
        ('yellow', 0xFFF9A825),
        ('green', 0xFF2E7D32),
      ])
        Player(id: id, name: id, colorValue: color),
    ];
    var state = ArnakState(
      players: four,
      config: const ArnakConfig(),
      status: GameStatus.inProgress,
      lines: const {},
      spiderTemple: true,
    );
    await pumpWithL10n(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setState) => ArnakSheet(
              state: state,
              readOnly: false,
              onChanged: (next) => setState(() => state = next),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('arnak-altars-button')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('arnak-altar-0-green')), findsOneWidget);
    // Results sit below the altars; on a phone they need a scroll.
    await tester.dragUntilVisible(
      find.byKey(const ValueKey('arnak-altars-results')),
      find.byType(ListView).last,
      const Offset(0, -200),
    );
    expect(find.byKey(const ValueKey('arnak-altars-results')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
