import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/domain/game_series.dart';
import 'package:board_game_score_sheet/domain/models/game_session.dart';
import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/features/play/play_screen.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_2e_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_config.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_player_line.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  test('home groups every GWT edition into one entry, in place', () {
    final entries = HomeEntry.group(GameRegistry().games);
    expect(entries, hasLength(5));

    final gwt = entries.first as SeriesEntry;
    expect(gwt.series, GameSeries.greatWesternTrail);
    expect(gwt.games.map((game) => game.id), [
      'great_western_trail_1e',
      'great_western_trail_2e',
      'great_western_trail_argentina',
      'great_western_trail_new_zealand',
      'great_western_trail_el_paso',
    ]);
    expect(entries.skip(1), everyElement(isA<SingleGameEntry>()));
  });

  testWidgets('the GWT banner resumes an edition in progress', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
    final stamped = DateTime.utc(2026, 1, 1);
    final repository = MemorySessionRepository();
    await repository.save(
      GameSession(
        gameId: GreatWesternTrailSecondEditionGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: GwtState(
          players: const [ada],
          config: const GwtConfig(),
          status: GameStatus.inProgress,
          lines: const {'ada': GwtPlayerLine()},
        ).toJson(),
      ),
    );

    await pumpScoreSheetApp(tester, repository: repository);
    final resume = find.byKey(
      const ValueKey('home-saved-series-great_western_trail'),
    );
    await pumpUntilFound(tester, gwtSeriesCard);
    expect(
      find.descendant(of: resume, matching: find.text('Resume')),
      findsOneWidget,
    );

    await tester.tap(resume);
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    expect(
      find.descendant(
        of: find.byType(PlayScreen),
        matching: find.widgetWithText(
          AppBar,
          'Great Western Trail Second Edition',
        ),
      ),
      findsOneWidget,
    );
  });
}
