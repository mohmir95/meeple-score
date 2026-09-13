import 'package:board_game_score_sheet/data/game_session_repository.dart';
import 'package:board_game_score_sheet/domain/models/game_session.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';

class MemorySessionRepository implements GameSessionRepository {
  MemorySessionRepository([Map<String, GameSession>? seed])
    : _sessions = {...?seed};

  final Map<String, GameSession> _sessions;
  final Map<String, List<Player>> _rosters = {};
  String? _activeGameId;

  @override
  Future<GameSession?> load(String gameId) async => _sessions[gameId];

  @override
  Future<Map<String, GameSession>> loadAll() async => {..._sessions};

  @override
  Future<void> save(GameSession session) async {
    _sessions[session.gameId] = session;
  }

  @override
  Future<void> delete(String gameId) async {
    _sessions.remove(gameId);
    if (_activeGameId == gameId) {
      _activeGameId = null;
    }
  }

  @override
  Future<String?> loadActiveGameId() async => _activeGameId;

  @override
  Future<void> saveActiveGameId(String? gameId) async {
    _activeGameId = gameId;
  }

  @override
  Future<List<Player>> loadRoster(String gameId) async {
    return [...?_rosters[gameId]];
  }

  @override
  Future<void> saveRoster(String gameId, List<Player> players) async {
    _rosters[gameId] = [...players];
  }
}
