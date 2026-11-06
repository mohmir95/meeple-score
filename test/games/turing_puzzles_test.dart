import 'package:board_game_score_sheet/features/hub/game_hub_screen.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_game.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_puzzles.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_puzzles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  test('the 20 rulebook puzzles match their printed setup', () {
    final puzzles = TuringPuzzle.rulebook;
    expect(puzzles, hasLength(20));
    expect([
      for (final p in puzzles) p.label,
    ], List.generate(20, (i) => '${i + 1}'.padLeft(2, '0')));
    for (final p in puzzles) {
      expect(p.verifiers.length, inInclusiveRange(4, 6));
      expect(p.difficulty, inInclusiveRange(1, 3));
      expect(p.luck, inInclusiveRange(1, 3));
      for (final v in p.verifiers) {
        expect(v.criteriaCard, inInclusiveRange(1, 48));
        expect(v.verificationCard, inInclusiveRange(200, 799));
      }
    }
    // The rulebook's setup example uses puzzle 01.
    final first = puzzles.first;
    expect([for (final v in first.verifiers) v.criteriaCard], [4, 9, 11, 14]);
    expect(
      [for (final v in first.verifiers) v.verificationCard],
      [447, 646, 566, 322],
    );
    // Verification card sets, as coloured in the rulebook.
    expect(first.cardSet, TuringCardSet.green);
    expect(puzzles[1].cardSet, TuringCardSet.orange);
    expect(puzzles[2].cardSet, TuringCardSet.blue);
    expect(puzzles[3].cardSet, TuringCardSet.purple);
    expect(
      TuringCardSet.values.map(
        (set) => puzzles.where((p) => p.cardSet == set).length,
      ),
      [5, 5, 5, 5],
    );
    expect(puzzles[15].verifiers, hasLength(6));
    expect(puzzles[19].verifiers.last.verificationCard, 615);
    // SOLUTIONS, p. 3.
    expect(first.solution, [2, 4, 1]);
    expect(puzzles[4].solution, [3, 5, 4]);
    expect(puzzles[19].solution, [4, 1, 1]);
    for (final p in puzzles) {
      expect(p.solution, hasLength(3));
      expect(p.solution, everyElement(inInclusiveRange(1, 5)));
    }
  });

  test('the Offline Challenge Bank matches its 16 printed sheets', () {
    final bank = TuringPuzzle.challengeBank;
    expect(bank, hasLength(16));
    expect(
      [for (final s in bank) s.puzzles.length],
      [for (var i = 0; i < 16; i++) i < 6 ? 30 : 24],
    );
    expect(bank.fold(0, (sum, s) => sum + s.puzzles.length), 420);
    expect(
      [for (final s in bank) s.difficulty],
      [1, 1, 2, 2, 3, 3, 1, 1, 2, 2, 3, 3, 2, 2, 3, 3],
    );
    expect(
      [for (final s in bank) s.puzzles.first.verifiers.length],
      [4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6],
    );

    final all = [...TuringPuzzle.rulebook, for (final s in bank) ...s.puzzles];
    // Every Verification card belongs to one colour set, everywhere.
    final colours = <int, TuringCardSet>{};
    for (final p in all) {
      expect(p.solution, hasLength(3), reason: p.label);
      expect(p.solution, everyElement(inInclusiveRange(1, 5)));
      var last = 0;
      for (final v in p.verifiers) {
        expect(v.criteriaCard, greaterThan(last), reason: p.label);
        last = v.criteriaCard;
        expect(v.verificationCard, inInclusiveRange(200, 799));
        expect(
          colours.putIfAbsent(v.verificationCard, () => p.cardSet),
          p.cardSet,
          reason: '${p.label} ${v.verificationCard}',
        );
      }
    }
    for (final s in bank) {
      for (final p in s.puzzles) {
        expect(p.difficulty, s.difficulty);
        expect(p.luck, isNull);
        expect(p.verifiers, hasLength(s.puzzles.first.verifiers.length));
        expect(p.machineRounds, inInclusiveRange(2, 5));
        expect(p.machineQuestions, greaterThan(p.machineRounds!));
      }
    }

    // Spot checks against the sheets.
    final first = bank.first.puzzles.first;
    expect(first.label, 'A41 AA5');
    expect(first.cardSet, TuringCardSet.orange);
    expect([for (final v in first.verifiers) v.criteriaCard], [2, 10, 11, 16]);
    expect(
      [for (final v in first.verifiers) v.verificationCard],
      [599, 635, 289, 515],
    );
    expect(first.solution, [3, 1, 4]);
    expect((first.machineRounds, first.machineQuestions), (2, 5));
    final hardest = bank[14].puzzles.first;
    expect(hardest.label, 'C64 NM0B');
    expect((hardest.machineRounds, hardest.machineQuestions), (5, 14));
    expect(bank.last.puzzles.last.label, 'C63 GMD6');
    expect(bank.last.puzzles.last.code, '314');
  });

  testWidgets('bank sheets and code search', (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await pumpWithL10n(tester, const TuringPuzzlesScreen());

    await tester.tap(find.text('Challenge Bank'));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('turing-puzzle-A41AA5')), findsOneWidget);
    expect(find.byKey(const ValueKey('turing-puzzle-01')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('turing-sheet-16')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('turing-puzzle-C632P1O')), findsOneWidget);
    expect(find.textContaining('sheet 16: 24 puzzles with 6'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Search ignores spaces and case, across the rulebook and every sheet.
    await tester.enterText(
      find.byKey(const ValueKey('turing-puzzles-search')),
      'a41 aa5',
    );
    await pumpFor(tester);
    expect(find.text('1 puzzles match.'), findsOneWidget);
    final tile = find.byKey(const ValueKey('turing-puzzle-A41AA5'));
    expect(tile, findsOneWidget);

    // The back shows how fast the machine solved it.
    final hold = await tester.startGesture(tester.getCenter(tile));
    await tester.pump(const Duration(milliseconds: 1000));
    await hold.up();
    await pumpFor(tester, duration: const Duration(milliseconds: 600));
    expect(find.text('Machine: 2 rounds, 5 questions'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('turing-puzzles-search')),
      'zzz',
    );
    await pumpFor(tester);
    expect(find.text('No puzzle has that code.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1200.0]) {
    testWidgets('hub opens the puzzles at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await pumpWithL10n(
        tester,
        GameHubScreen(
          game: const TuringMachineGame(),
          repository: MemorySessionRepository(),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('hub-puzzles')));
      await pumpFor(tester);
      await pumpUntilFound(tester, find.byType(TuringPuzzlesScreen));
      expect(find.byKey(const ValueKey('turing-puzzle-01')), findsOneWidget);
      expect(find.text('447'), findsOneWidget);

      // A short press does not flip; holding shows the solution.
      final tile = find.byKey(const ValueKey('turing-puzzle-01'));
      const solution = ValueKey('turing-solution-01');
      await tester.longPress(tile);
      await pumpFor(tester);
      expect(find.byKey(solution), findsNothing);
      final hold = await tester.startGesture(tester.getCenter(tile));
      await tester.pump(const Duration(milliseconds: 1000));
      await hold.up();
      await pumpFor(tester, duration: const Duration(milliseconds: 600));
      expect(find.byKey(solution), findsOneWidget);
      for (final digit in ['2', '4', '1']) {
        expect(
          find.descendant(of: find.byKey(solution), matching: find.text(digit)),
          findsOneWidget,
        );
      }
      // Tap flips it back.
      await tester.tap(find.byKey(solution));
      await pumpFor(tester, duration: const Duration(milliseconds: 600));
      expect(find.byKey(solution), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('turing-puzzle-20')),
        300,
        scrollable: find
            .descendant(
              of: find.byType(TuringPuzzlesScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('615'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
