import 'package:board_game_score_sheet/games/takenoko/takenoko_game.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_rules.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_scoring_hints_screen.dart';
import 'package:board_game_score_sheet/games/takenoko/takenoko_second_edition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _in(String key, String text) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

void main() {
  test('matches the rulebook end-of-game numbers', () {
    expect(TakenokoRules.playerCounts, [2, 3, 4]);
    expect(
      [
        for (final n in TakenokoRules.playerCounts)
          TakenokoRules.objectivesToEnd(n),
      ],
      [9, 8, 7],
    );
    expect(TakenokoRules.emperorPoints, 2);
    expect(TakenokoRules.handLimit, 5);
  });

  test('Takenoko hub has scoring hints and updated rules, no scoresheet', () {
    const game = TakenokoGame();
    expect(game.hasScoresheet, isFalse);
    expect(game.showScoringHints, isTrue);
    expect(game.buildScoringHints(), isNotNull);
    expect(game.showQuickReference, isTrue);
    expect(game.quickReferenceTitleKey, 'hub.updatedRules');
    expect(game.minPlayers, 2);
    expect(game.maxPlayers, 4);
  });

  for (final width in [1200.0, 360.0]) {
    testWidgets(
      'scoring hints list the end and final score (${width.toInt()}px)',
      (tester) async {
        tester.view.physicalSize = Size(width, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpWithL10n(tester, const TakenokoScoringHintsScreen());
        expect(_in('takenoko-score-end-2', '9th objective'), findsOneWidget);
        expect(_in('takenoko-score-end-3', '8th objective'), findsOneWidget);
        expect(_in('takenoko-score-end-4', '7th objective'), findsOneWidget);
        expect(_in('takenoko-score-emperor', '2'), findsOneWidget);
        expect(_in('takenoko-score-hand', '0'), findsOneWidget);
        expect(find.text('Printed'), findsNWidgets(3));
        expect(find.textContaining('panda objectives wins'), findsOneWidget);
        expect(find.textContaining('at most 5 objectives'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('2nd edition page lists every change (${width.toInt()}px)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpWithL10n(tester, const TakenokoSecondEditionScreen());
      final changes = [
        for (final group in TakenokoSecondEdition.groups) ...group.changes,
      ];
      expect(changes, hasLength(8));
      for (final change in changes) {
        expect(find.byKey(ValueKey('takenoko-second-$change')), findsOneWidget);
      }
      expect(
        find.text('Gardener objectives need the gardener'),
        findsOneWidget,
      );
      expect(find.text('1st edition'), findsNWidgets(8));
      expect(find.text('2nd edition'), findsNWidgets(8));
      expect(find.text('8'), findsOneWidget);

      // The 1st edition rule stays hidden until its box is tapped.
      const oldRule =
          "You put the 2 plots you didn't choose back on top of the deck, "
          'face down, in the order of your choice.';
      expect(find.text(oldRule), findsNothing);
      await tester.tap(find.text('1st edition').first);
      await pumpFor(tester);
      expect(find.text(oldRule), findsOneWidget);
      await tester.tap(find.text('1st edition').first);
      await pumpFor(tester);
      expect(find.text(oldRule), findsNothing);

      // Removed rules lead with the 1st edition; the 2nd edition is open too.
      const removedOld =
          'If you drew an objective that was already met in the garden, you '
          'discarded it and drew another of the same category.';
      const removedNew =
          'Dropped from the rulebook. Keep it as a house rule if you like.';
      final variant = find.byKey(const ValueKey('takenoko-second-variant'));
      expect(
        find.descendant(of: variant, matching: find.text(removedOld)),
        findsOneWidget,
      );
      expect(find.text(removedNew), findsOneWidget);
      expect(
        find.descendant(of: variant, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
