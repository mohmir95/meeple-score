import '../domain/models/game_session.dart';
import '../domain/models/player.dart';

abstract class GameSessionRepository {
  Future<GameSession?> load(String gameId);

  Future<Map<String, GameSession>> loadAll();

  Future<void> save(GameSession session);

  Future<void> delete(String gameId);

  Future<String?> loadActiveGameId();

  Future<void> saveActiveGameId(String? gameId);

  Future<List<Player>> loadRoster(String gameId);

  Future<void> saveRoster(String gameId, List<Player> players);
}
