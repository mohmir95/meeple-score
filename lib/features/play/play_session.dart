import 'package:flutter/foundation.dart';

import '../../data/game_session_repository.dart';
import '../../domain/board_game.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';

class PlaySession extends ChangeNotifier {
  PlaySession({
    required this.game,
    required GameState state,
    required this.repository,
    required this.createdAt,
  }) : _state = state;

  factory PlaySession.fromSaved({
    required BoardGame game,
    required GameSession session,
    required GameSessionRepository repository,
  }) {
    return PlaySession(
      game: game,
      state: game.stateFromJson(session.stateJson),
      repository: repository,
      createdAt: session.createdAt,
    );
  }

  factory PlaySession.start({
    required BoardGame game,
    required List<Player> players,
    required GameConfig config,
    required GameSessionRepository repository,
  }) {
    return PlaySession(
      game: game,
      state: game.createInitialState(players: players, config: config),
      repository: repository,
      createdAt: DateTime.now(),
    );
  }

  final BoardGame game;
  final GameSessionRepository repository;
  final DateTime createdAt;
  GameState _state;

  GameState get state => _state;

  bool get isFinished => _state.status == GameStatus.finished;

  Future<void> update(GameState next) async {
    _state = next;
    notifyListeners();
    await _persist();
  }

  Future<void> reset() {
    return update(
      game.createInitialState(
        players: _state.players,
        config: _state.config,
      ),
    );
  }

  Future<void> finish() {
    return update(_state.copyWithStatus(GameStatus.finished));
  }

  Future<void> resume() {
    return update(_state.copyWithStatus(GameStatus.inProgress));
  }

  Future<void> delete() {
    return repository.delete(game.id);
  }

  Future<void> _persist() async {
    await repository.save(
      GameSession(
        gameId: game.id,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        stateJson: _state.toJson(),
      ),
    );
    await repository.saveActiveGameId(game.id);
  }
}
