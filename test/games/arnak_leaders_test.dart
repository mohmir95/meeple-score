import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/features/setup/setup_screen.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_config.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_game.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_leaders.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_sheet.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/memory_session_repository.dart';

void main() {
  const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
  const sam = Player(id: 'sam', name: 'Sam', colorValue: 0xFF1565C0);

  group('leader picks', () {
    test('there are eight leaders, each with a portrait', () {
      expect(ArnakLeader.all.map((l) => l.id), [
        'captain',
        'falconer',
        'baroness',
        'professor',
        'explorer',
        'mystic',
        'journalist',
        'engineer',
      ]);
      expect(
        ArnakLeader.byId('mystic')!.asset,
        'assets/games/lost_ruins_of_arnak/leaders/mystic.png',
      );
    });

    test('leaders only count while the toggle is on', () {
      const config = ArnakConfig(leaders: {'ada': 'captain'});
      expect(config.leaderFor('ada'), isNull);
      expect(
        config.copyWith(leadersEnabled: true).leaderFor('ada')!.id,
        'captain',
      );
    });

    test('picking a taken leader swaps with its owner', () {
      const config = ArnakConfig(
        leadersEnabled: true,
        leaders: {'ada': 'captain', 'sam': 'mystic'},
      );
      final next = config.withLeader('ada', 'mystic');
      expect(next.leaders, {'ada': 'mystic', 'sam': 'captain'});
    });

    test('taking a leader from someone with nothing to swap clears theirs', () {
      const config = ArnakConfig(
        leadersEnabled: true,
        leaders: {'sam': 'mystic'},
      );
      expect(config.withLeader('ada', 'mystic').leaders, {'ada': 'mystic'});
    });

    test('a pick can be cleared', () {
      const config = ArnakConfig(leadersEnabled: true, leaders: {'ada': 'x'});
      expect(config.withLeader('ada', null).leaders, isEmpty);
    });

    test('removed players lose their pick when the game starts', () {
      const config = ArnakConfig(
        leadersEnabled: true,
        leaders: {'ada': 'captain', 'gone': 'mystic'},
      );
      final state =
          const LostRuinsOfArnakGame().createInitialState(
                players: const [ada, sam],
                config: config,
              )
              as ArnakState;
      expect(state.config.leaders, {'ada': 'captain'});
    });

    test('leaders survive a save and reload', () {
      const config = ArnakConfig(
        leadersEnabled: true,
        leaders: {'ada': 'captain', 'sam': 'engineer'},
      );
      final restored = ArnakConfig.fromJson(config.toJson());
      expect(restored.leadersEnabled, isTrue);
      expect(restored.leaders, config.leaders);
    });
  });

  testWidgets('setup: Leaders are on by default with a picker per player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpWithL10n(
      tester,
      SetupScreen(
        game: const LostRuinsOfArnakGame(),
        repository: MemorySessionRepository(),
      ),
    );
    await pumpUntilFound(tester, find.text('Leaders'));
    // Leaders are on by default for a new game.
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('arnak-leaders-toggle')));
    await pumpFor(tester);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.tap(find.byKey(const ValueKey('arnak-leaders-toggle')));
    await pumpFor(tester);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await pumpFor(tester);
    expect(find.text('Engineer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('arnak-leader-option-mystic')));
    await pumpFor(tester);

    expect(
      find.image(
        const AssetImage('assets/games/lost_ruins_of_arnak/leaders/mystic.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('score sheet shows each player\'s leader in the header', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final state = ArnakState(
      players: const [ada, sam],
      config: const ArnakConfig(
        leadersEnabled: true,
        leaders: {'ada': 'captain'},
      ),
      status: GameStatus.inProgress,
      lines: const {},
    );
    await pumpWithL10n(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: ArnakSheet(state: state, readOnly: false, onChanged: (_) {}),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('arnak-sheet-leader-ada')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('arnak-sheet-leader-sam')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
