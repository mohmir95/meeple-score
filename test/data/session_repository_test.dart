import 'package:board_game_score_sheet/data/shared_preferences_session_repository.dart';
import 'package:board_game_score_sheet/domain/game_registry.dart';
import 'package:board_game_score_sheet/domain/models/game_session.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('registry exposes Great Western Trail', () {
    final registry = GameRegistry();
    expect(registry.games, hasLength(1));
    expect(registry.lookup(GreatWesternTrailGame.idValue), isA<GreatWesternTrailGame>());
    expect(registry.tryLookup('simple_tally'), isNull);
  });

  test('shared preferences repository stores sessions, roster, and active game', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SharedPreferencesSessionRepository(prefs);
    const player = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);

    final session = GameSession(
      gameId: GreatWesternTrailGame.idValue,
      createdAt: DateTime.utc(2026, 1, 2),
      updatedAt: DateTime.utc(2026, 1, 3),
      stateJson: {
        'status': 'inProgress',
        'players': [player.toJson()],
        'config': const <String, dynamic>{},
        'lines': {
          'ada': {'dollars': 23, 'buildings': 10},
        },
      },
    );

    await repository.save(session);
    await repository.saveActiveGameId(GreatWesternTrailGame.idValue);
    await repository.saveRoster(GreatWesternTrailGame.idValue, const [player]);

    final loaded = await repository.load(GreatWesternTrailGame.idValue);
    expect(loaded, isNotNull);
    expect(loaded!.stateJson['lines'], session.stateJson['lines']);
    expect(await repository.loadActiveGameId(), GreatWesternTrailGame.idValue);
    expect(await repository.loadRoster(GreatWesternTrailGame.idValue), [player]);

    await repository.delete(GreatWesternTrailGame.idValue);
    expect(await repository.load(GreatWesternTrailGame.idValue), isNull);
    expect(await repository.loadActiveGameId(), isNull);
  });
}
