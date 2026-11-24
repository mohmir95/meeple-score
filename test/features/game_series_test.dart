import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/domain/game_series.dart';
import 'package:board_game_score_sheet/domain/models/game_session.dart';
import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/features/home/game_card.dart';
import 'package:board_game_score_sheet/features/home/game_series_screen.dart';
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
  _centuryPageTest();

  testWidgets('the Century banner shows the standalone games and a more '
      'strip', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(tester, find.text('Century Games'));
    expect(find.text('Great Western Trail\nGames'), findsOneWidget);
    // Only the Century banner hints at more editions; GWT shows all 5.
    expect(find.byKey(const ValueKey('home-series-more')), findsOneWidget);
    expect(GameSeries.century.bannerGameIds, hasLength(3));
    expect(GameSeries.greatWesternTrail.bannerGameIds, isNull);
  });

  test('home groups every GWT edition into one entry, in place', () {
    final entries = HomeEntry.group(GameRegistry().games);
    expect(entries, hasLength(9));

    final gwt = entries.first as SeriesEntry;
    expect(gwt.series, GameSeries.greatWesternTrail);
    expect(gwt.games.map((game) => game.id), [
      'great_western_trail_1e',
      'great_western_trail_2e',
      'great_western_trail_argentina',
      'great_western_trail_new_zealand',
      'great_western_trail_el_paso',
    ]);
    // Stacks come first: Century right after GWT, then the single games.
    final century = entries[1] as SeriesEntry;
    expect(century.series, GameSeries.century);
    expect(entries.skip(2), everyElement(isA<SingleGameEntry>()));
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

void _centuryPageTest() {
  testWidgets('the Century page lists all seven games', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester);
    final century = find.byKey(const ValueKey('home-series-century'));
    await pumpUntilFound(tester, century);
    await tester.tap(century);
    await pumpFor(tester, duration: const Duration(milliseconds: 800));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('series-game-century_from_sand_to_sea')),
    );
    expect(
      find.descendant(
        of: find.byType(GameSeriesScreen),
        matching: find.byType(GameCard),
      ),
      findsNWidgets(7),
    );
    // Combinations show only the games they combine.
    expect(find.text('Spice Road + Eastern Wonders'), findsOneWidget);
    // Only the three standalone games keep the white "Century" line.
    expect(
      find.descendant(
        of: find.byType(GameSeriesScreen),
        matching: find.text('Century'),
      ),
      findsNWidgets(3),
    );
    expect(tester.takeException(), isNull);
  });
}
