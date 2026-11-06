import 'dart:convert';
import 'dart:ui' as ui;

import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/features/hub/game_hub_screen.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_game.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_note_sheet_screen.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_notes.dart';
import 'package:board_game_score_sheet/games/turing_machine/turing_sheet_image.dart';
import 'package:board_game_score_sheet/shared/export/png_save.dart';
import 'package:board_game_score_sheet/shared/links/open_url.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  test('Turing Machine is registered without a scoresheet', () {
    final game = GameRegistry().lookup(TuringMachineGame.idValue);
    expect(game.showNoteSheet, isTrue);
    expect(game.hasScoresheet, isFalse);
  });

  test('notes survive a JSON round trip', () {
    final notes =
        TuringNotes(player: 'Sam', problem: 'B63 YRW', verifierCount: 5)
          ..codes[0][1] = 4
          ..results[0][0] = VerifierMark.handicap
          ..results[2][4] = VerifierMark.fail
          ..digits[2][0] = DigitMark.circled
          ..notes[3] = 'not even'
          ..criteria[3] = 'square < 3'
          ..finalCode[1] = 2;
    final copy = TuringNotes.fromJson(
      jsonDecode(jsonEncode(notes.toJson())) as Map<String, dynamic>,
    );
    expect(copy.toJson(), notes.toJson());
    expect(copy.questions, 2);
    expect(copy.roundsPlayed, 3);
    expect(TuringNotes.fromJson({'codes': 'junk'}).isEmpty, isTrue);
    // Sheets saved before verifierCount existed start with A–D.
    expect(TuringNotes.fromJson({}).verifierCount, 4);
    expect(TuringNotes().verifierCount, 4);
  });

  testWidgets('sheet follows the rules: 3 questions, E/F, handicap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final locale = await createTestLocale();
    SharedPreferences.setMockInitialValues({});
    await pumpWithL10n(
      tester,
      const TuringNoteSheetScreen(),
      localeController: locale,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('turing-final-toggle')),
    );

    // A new sheet uses A–D: E and F are struck out.
    expect(find.byKey(const ValueKey('turing-struck-0-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('turing-result-0-4')), findsNothing);
    expect(find.byKey(const ValueKey('turing-notes-4')), findsNothing);

    Future<void> say(String text) async {
      await pumpFor(tester);
      expect(find.text(text), findsOneWidget);
    }

    Future<void> writeProposal(int round, List<int> digits) async {
      for (var s = 0; s < 3; s++) {
        await tester.tap(find.byKey(ValueKey('turing-code-$round-$s')));
        await pumpFor(tester);
        await tester.tap(find.text('${digits[s]}').last);
        await pumpFor(tester);
      }
    }

    Finder box(int round, int v) =>
        find.byKey(ValueKey('turing-result-$round-$v'));
    Finder icon(Finder of, IconData data) =>
        find.descendant(of: of, matching: find.byIcon(data));

    // Nothing can be marked before the round's proposal is written.
    await tester.tap(box(1, 0));
    await say(
      "Write this round's proposal (all 3 digits) before marking answers.",
    );
    await tester.tap(find.byKey(const ValueKey('turing-digit-0-5')));
    await say('Write your first proposal before marking digits.');
    expect((await TuringNotesStore.load()).isEmpty, isTrue);

    // Handicap boxes also wait for round 1's proposal.
    await tester.tap(find.byKey(const ValueKey('turing-handicap-mode')));
    await pumpFor(tester);
    await tester.tap(box(0, 0));
    await say(
      "Write this round's proposal (all 3 digits) before marking answers.",
    );
    await tester.tap(find.byKey(const ValueKey('turing-handicap-mode')));
    await pumpFor(tester);
    expect((await TuringNotesStore.load()).isEmpty, isTrue);

    await writeProposal(0, [3, 3, 2]);
    await writeProposal(1, [4, 2, 1]);

    // Tap gives ✗, tap again ✓; hold gives ✓ straight away.
    await tester.tap(box(1, 0));
    await tester.pump();
    expect(icon(box(1, 0), Icons.close_rounded), findsOneWidget);
    await tester.tap(box(1, 0));
    await tester.pump();
    expect(icon(box(1, 0), Icons.check_rounded), findsOneWidget);
    await tester.longPress(box(1, 1));
    await tester.pump();
    expect(icon(box(1, 1), Icons.check_rounded), findsOneWidget);

    // A fourth question in one round is refused.
    await tester.tap(box(1, 2));
    await tester.tap(box(1, 3));
    await say('You can question at most 3 verifiers per round.');
    expect(find.text('Questions: 3'), findsOneWidget);
    expect(find.text('Rounds: 2'), findsOneWidget);

    // Digits: tap crosses out (✗), hold circles (✓).
    await tester.tap(find.byKey(const ValueKey('turing-digit-0-5')));
    await tester.longPress(find.byKey(const ValueKey('turing-digit-1-4')));
    await pumpFor(tester);
    final digits = (await TuringNotesStore.load()).digits;
    expect(digits[0][4], DigitMark.crossed);
    expect(digits[1][3], DigitMark.circled);

    // Handicap mode: taps fill round 1 boxes grey, at most 2.
    await tester.tap(find.byKey(const ValueKey('turing-handicap-mode')));
    await pumpFor(tester);
    await tester.tap(box(1, 3));
    await say('Handicap boxes can only be filled in round 1.');
    await tester.tap(box(0, 0));
    await tester.tap(box(0, 1));
    await tester.tap(box(0, 2));
    await say('The handicap fills at most 2 boxes in round 1.');
    expect(find.text('Questions: 5'), findsOneWidget);
    expect(
      (await TuringNotesStore.load()).results[0].take(2),
      everyElement(VerifierMark.handicap),
    );

    // Off again, taps answer normally.
    await tester.tap(find.byKey(const ValueKey('turing-handicap-mode')));
    await pumpFor(tester);
    await tester.tap(box(0, 2));
    await tester.pump();
    expect(icon(box(0, 2), Icons.close_rounded), findsOneWidget);
    expect(find.text('Questions: 6'), findsOneWidget);

    // Picking A–F brings the columns back.
    await tester.tap(find.byKey(const ValueKey('turing-verifiers-6')));
    await tester.pump();
    expect(find.byKey(const ValueKey('turing-result-0-5')), findsOneWidget);

    // "Your code" starts folded, and opens to write the code.
    expect(find.byKey(const ValueKey('turing-final-0')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('turing-final-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('turing-final-toggle')));
    await pumpFor(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('turing-final-1')));
    await tester.tap(find.byKey(const ValueKey('turing-final-1')));
    await pumpFor(tester);
    await tester.tap(find.text('5').last);
    await pumpFor(tester);
    expect((await TuringNotesStore.load()).finalCode, [null, 5, null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notes are written onto the printed sheet image', (tester) async {
    final notes = TuringNotes(player: 'Ada', problem: 'B63 YRW')
      ..codes[0] = [4, 2, 1]
      ..results[0][0] = VerifierMark.pass
      ..results[0][1] = VerifierMark.fail
      ..digits[1][3] = DigitMark.crossed
      ..digits[2][0] = DigitMark.circled
      ..notes[0] = 'یادداشت فارسی and English'
      ..criteria[3] = 'square < 3'
      ..finalCode.setAll(0, [2, 4, 1]);
    final png = await tester.runAsync(() async {
      final bytes = await TuringSheetImage.render(notes);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      return size;
    });
    expect(png, (2204, 2604));
  });

  testWidgets('Save image writes a PNG named after the game', (tester) async {
    final locale = await createTestLocale();
    SharedPreferences.setMockInitialValues({});
    String? savedName;
    pngSaveOverride = (bytes, name) async => savedName = name;
    addTearDown(() => pngSaveOverride = null);
    await pumpWithL10n(
      tester,
      const TuringNoteSheetScreen(),
      localeController: locale,
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('turing-save-image')),
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('turing-save-image')));
      for (var i = 0; i < 50 && savedName == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await pumpFor(tester);
    expect(savedName, startsWith('meeple-score-turing_machine-'));
    expect(
      find.text('Note sheet saved. Check Downloads or your photo gallery.'),
      findsOneWidget,
    );
  });

  for (final width in [360.0, 1200.0]) {
    testWidgets('note sheet fits and saves marks at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      final locale = await createTestLocale();
      SharedPreferences.setMockInitialValues({});

      await pumpWithL10n(
        tester,
        GameHubScreen(
          game: const TuringMachineGame(),
          repository: MemorySessionRepository(),
        ),
        localeController: locale,
      );
      expect(find.text('Scoresheet'), findsNothing);
      expect(find.byKey(const ValueKey('hub-online')), findsOneWidget);
      String? opened;
      openUrlOverride = (url) => opened = url;
      addTearDown(() => openUrlOverride = null);
      await tester.tap(find.byKey(const ValueKey('hub-online')));
      expect(opened, 'https://turingmachine.info/');

      await tester.tap(find.byKey(const ValueKey('hub-note-sheet')));
      await pumpFor(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('turing-result-0-0')),
      );
      expect(tester.takeException(), isNull);

      for (var s = 0; s < 3; s++) {
        await tester.tap(find.byKey(ValueKey('turing-code-0-$s')));
        await pumpFor(tester);
        await tester.tap(find.text('3').last);
        await pumpFor(tester);
      }

      final box = find.byKey(const ValueKey('turing-result-0-0'));
      await tester.tap(box);
      await tester.pump();
      expect(
        find.descendant(of: box, matching: find.byIcon(Icons.close_rounded)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('turing-digit-1-5')));

      await tester.enterText(
        find.byKey(const ValueKey('turing-criterion-0')),
        'triangle > 2',
      );
      await pumpFor(tester);

      final saved = await TuringNotesStore.load();
      expect(saved.results[0][0], VerifierMark.fail);
      expect(saved.digits[1][4], DigitMark.crossed);
      expect(saved.codes[0], [3, 3, 3]);
      expect(saved.criteria[0], 'triangle > 2');

      // Leaving and coming back keeps the sheet.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWithL10n(
        tester,
        const TuringNoteSheetScreen(),
        localeController: locale,
      );
      await pumpUntilFound(tester, find.text('triangle > 2'));

      await tester.tap(find.byKey(const ValueKey('turing-clear')));
      await pumpFor(tester);
      await tester.tap(find.byKey(const ValueKey('turing-clear-confirm')));
      await pumpFor(tester);
      expect(find.text('triangle > 2'), findsNothing);
      expect((await TuringNotesStore.load()).isEmpty, isTrue);
    });
  }
}
