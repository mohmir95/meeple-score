import '../../domain/json_values.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import 'shelfie_config.dart';
import 'shelfie_player_line.dart';

class ShelfieState extends GameState {
  const ShelfieState({
    required this.players,
    required this.config,
    required this.status,
    required this.lines,
    this.lowestCardPlayerId,
  });

  /// Empty string means the tied players also tied on Character Cards.
  static const sharedVictory = '';

  static const _unset = Object();

  @override
  final List<Player> players;

  @override
  final ShelfieConfig config;

  @override
  final GameStatus status;

  final Map<String, ShelfiePlayerLine> lines;

  /// Tied player holding the lowest-valued Character Card. `null` if not
  /// chosen yet, [sharedVictory] if the cards tie too.
  final String? lowestCardPlayerId;

  ShelfiePlayerLine lineFor(String playerId) {
    return lines[playerId] ?? const ShelfiePlayerLine();
  }

  ShelfieState copyWith({
    List<Player>? players,
    ShelfieConfig? config,
    GameStatus? status,
    Map<String, ShelfiePlayerLine>? lines,
    Object? lowestCardPlayerId = _unset,
  }) {
    return ShelfieState(
      players: players ?? this.players,
      config: config ?? this.config,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      lowestCardPlayerId: identical(lowestCardPlayerId, _unset)
          ? this.lowestCardPlayerId
          : lowestCardPlayerId as String?,
    );
  }

  ShelfieState updateLine(String playerId, ShelfiePlayerLine line) {
    final next = Map<String, ShelfiePlayerLine>.from(lines);
    next[playerId] = line;
    return copyWith(lines: next);
  }

  @override
  GameState copyWithPlayers(List<Player> players) {
    final ids = {for (final player in players) player.id};
    final lowest = lowestCardPlayerId;
    return ShelfieState(
      players: players,
      config: config,
      status: status,
      lines: {
        for (final player in players)
          player.id: lines[player.id] ?? const ShelfiePlayerLine(),
      },
      lowestCardPlayerId:
          lowest == null || lowest == sharedVictory || ids.contains(lowest)
          ? lowest
          : null,
    );
  }

  @override
  GameState copyWithStatus(GameStatus status) => copyWith(status: status);

  @override
  Map<String, dynamic> toJson() {
    return {
      'players': players.map((player) => player.toJson()).toList(),
      'status': status.name,
      'config': config.toJson(),
      'lines': {
        for (final entry in lines.entries) entry.key: entry.value.toJson(),
      },
      'lowestCardPlayerId': lowestCardPlayerId,
    };
  }

  factory ShelfieState.fromJson(Map<String, dynamic> json) {
    final rawLines = readMap(json['lines']);
    final rawLowest = json['lowestCardPlayerId'];
    return ShelfieState(
      players: readMapList(json['players']).map(Player.fromJson).toList(),
      config: ShelfieConfig.fromJson(readMap(json['config'])),
      status: GameStatus.fromName(json['status'] as String?),
      lines: {
        for (final entry in rawLines.entries)
          entry.key: ShelfiePlayerLine.fromJson(readMap(entry.value)),
      },
      lowestCardPlayerId: rawLowest is String ? rawLowest : null,
    );
  }
}
