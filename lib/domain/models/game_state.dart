import 'game_config.dart';
import 'game_status.dart';
import 'player.dart';

abstract class GameState {
  const GameState();

  List<Player> get players;
  GameStatus get status;
  GameConfig get config;

  GameState copyWithPlayers(List<Player> players);
  GameState copyWithStatus(GameStatus status);
  Map<String, dynamic> toJson();
}
