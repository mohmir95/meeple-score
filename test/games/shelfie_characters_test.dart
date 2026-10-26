import 'dart:math' as math;

import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_character_randomizer_screen.dart';
import 'package:board_game_score_sheet/games/shelfie_stacker/shelfie_characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('deals each player 8 different cards in number order', () {
    final hands = ShelfieCharacterDeal.deal(4, math.Random(7));
    expect(hands, hasLength(4));
    for (final hand in hands) {
      final numbers = [for (final card in hand) card.number];
      expect(numbers, hasLength(8));
      expect(numbers.toSet(), hasLength(8));
      expect(numbers, orderedEquals([...numbers]..sort()));
      expect(numbers.every((n) => n >= 1 && n <= 16), isTrue);
    }
  });

  test('the first game uses cards 1–8 for everyone', () {
    final hands = ShelfieCharacterDeal.deal(3, math.Random(1), firstGame: true);
    for (final hand in hands) {
      expect([for (final card in hand) card.number], [1, 2, 3, 4, 5, 6, 7, 8]);
    }
  });

  testWidgets('shows a hand per player and opens a card rules dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpWithL10n(
      tester,
      ShelfieCharacterRandomizerScreen(random: math.Random(3)),
    );
    await pumpFor(tester);

    // Starts on the first game: one shared hand of cards 1–8.
    expect(find.byKey(const ValueKey('shelfie-chars-hand-0')), findsNothing);
    expect(find.byKey(const ValueKey('shelfie-chars-hand-all')), findsOneWidget);
    expect(find.text('All players'), findsOneWidget);
    expect(find.text('1. Bad Lender'), findsOneWidget);
    expect(find.text('8. Shelfie Snapper'), findsOneWidget);
    expect(find.text('16. The Shuffler'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('shelfie-char-1')));
    await pumpFor(tester);
    // The tile and the dialog title.
    expect(find.text('1. Bad Lender'), findsNWidgets(2));
    expect(find.textContaining('Travel Case'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await pumpFor(tester);

    // Changing the player count keeps the shared hand as dealt: a re-deal
    // would remount the cards.
    final card = find.byKey(const ValueKey('shelfie-char-1'));
    final before = tester.element(card);
    await tester.tap(find.byKey(const ValueKey('shelfie-chars-remove-player')));
    await pumpFor(tester);
    expect(tester.element(card), same(before));
    await tester.tap(find.byKey(const ValueKey('shelfie-chars-add-player')));
    await pumpFor(tester);
    await tester.tap(find.text('Green').last);
    await pumpFor(tester);
    expect(tester.element(card), same(before));

    await tester.tap(find.byKey(const ValueKey('shelfie-chars-first-game')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('shelfie-chars-hand-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('shelfie-chars-hand-1')), findsOneWidget);
    // Players are named by color, not number; the selector shows no names.
    expect(find.text('Blue'), findsNothing);
    expect(find.text('Blue Player'), findsOneWidget);
    expect(find.text('Green Player'), findsOneWidget);
    expect(find.text('Player 1'), findsNothing);
  });
}
