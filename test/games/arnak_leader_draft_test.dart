import 'dart:math' as math;

import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_leaders.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_leaders_randomizer_screen.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_leaders_setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  test('up to 3 choices each, fewer when 8 leaders cannot cover it', () {
    expect(ArnakLeaderDraft.choicesFor(1), 3);
    expect(ArnakLeaderDraft.choicesFor(2), 3);
    expect(ArnakLeaderDraft.choicesFor(3), 2);
    expect(ArnakLeaderDraft.choicesFor(4), 2);
  });

  test('every deal is unique across players', () {
    final random = math.Random(7);
    for (var players = 1; players <= 4; players++) {
      for (var round = 0; round < 50; round++) {
        final hands = ArnakLeaderDraft.deal(players, random);
        expect(hands, hasLength(players));
        final dealt = [for (final hand in hands) ...hand];
        expect(
          hands.every((h) => h.length == ArnakLeaderDraft.choicesFor(players)),
          isTrue,
        );
        expect(dealt.toSet(), hasLength(dealt.length));
      }
    }
  });

  testWidgets('randomizer page deals a hand per player and re-deals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      ArnakLeadersRandomizerScreen(random: math.Random(1)),
    );

    // Two players by default, three choices each.
    expect(find.byKey(const ValueKey('arnak-draft-hand-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('arnak-draft-hand-2')), findsNothing);
    expect(find.byType(ArnakLeaderPortrait), findsNWidgets(6));

    // Add two players through the color roster (yellow, then the last color).
    await tester.tap(find.byKey(const ValueKey('arnak-draft-add-player')));
    await pumpFor(tester);
    await tester.tap(find.text('Yellow').last);
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('arnak-draft-hand-2')), findsOneWidget);
    expect(find.byType(ArnakLeaderPortrait), findsNWidgets(6)); // 3 x 2

    await tester.tap(find.byKey(const ValueKey('arnak-draft-add-player')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('arnak-draft-hand-3')), findsOneWidget);
    expect(find.byType(ArnakLeaderPortrait), findsNWidgets(8));
    // All four colors are used, so no more players can be added.
    expect(find.byKey(const ValueKey('arnak-draft-add-player')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('arnak-draft-remove-player')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('arnak-draft-hand-3')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('arnak-draft-add-player')));
    await pumpFor(tester);

    List<String?> shown() => [
      for (final element in find.byType(ArnakLeaderPortrait).evaluate())
        (element.widget as ArnakLeaderPortrait).leader.id,
    ];
    final before = shown();
    await tester.tap(find.byKey(const ValueKey('arnak-draft-randomize')));
    await pumpFor(tester);
    expect(shown().toSet(), before.toSet()); // All 8 leaders, still unique.
    expect(tester.takeException(), isNull);
  });

  testWidgets('randomizer fits a phone with four players', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      ArnakLeadersRandomizerScreen(random: math.Random(3)),
    );
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('arnak-draft-add-player')));
      await pumpFor(tester);
      if (find.text('Yellow').evaluate().isNotEmpty) {
        await tester.tap(find.text('Yellow').last);
        await pumpFor(tester);
      }
    }
    await pumpFor(tester, duration: const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('arnak-draft-hand-3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arnak hub links to Randomize Leaders', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final locale = await createTestLocale();
    await pumpScoreSheetApp(tester, localeController: locale);
    await pumpUntilFound(tester, find.text('Lost Ruins of Arnak'));
    await tester.tap(find.text('Lost Ruins of Arnak'));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('hub-leaders-randomizer')),
    );
    await tester.tap(find.byKey(const ValueKey('hub-leaders-randomizer')));
    await pumpFor(tester);
    expect(find.byType(ArnakLeadersRandomizerScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
