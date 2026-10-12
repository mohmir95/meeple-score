import '../../domain/json_values.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import 'cob_config.dart';
import 'cob_player_line.dart';

class CobState extends GameState {
  const CobState({
    required this.players,
    required this.config,
    required this.status,
    required this.lines,
  });

  @override
  final List<Player> players;

  @override
  final CobConfig config;

  @override
  final GameStatus status;

  final Map<String, CobPlayerLine> lines;

  CobPlayerLine lineFor(String playerId) {
    return lines[playerId] ?? const CobPlayerLine();
  }

  CobState copyWith({
    List<Player>? players,
    CobConfig? config,
    GameStatus? status,
    Map<String, CobPlayerLine>? lines,
  }) {
    return CobState(
      players: players ?? this.players,
      config: config ?? this.config,
      status: status ?? this.status,
      lines: lines ?? this.lines,
    );
  }

  CobState updateLine(String playerId, CobPlayerLine line) {
    final next = Map<String, CobPlayerLine>.from(lines);
    next[playerId] = line;
    return copyWith(lines: next);
  }

  @override
  GameState copyWithPlayers(List<Player> players) {
    return CobState(
      players: players,
      config: config,
      status: status,
      lines: {
        for (final player in players)
          player.id: lines[player.id] ?? const CobPlayerLine(),
      },
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
    };
  }

  factory CobState.fromJson(Map<String, dynamic> json) {
    final rawLines = readMap(json['lines']);
    return CobState(
      players: readMapList(json['players']).map(Player.fromJson).toList(),
      config: CobConfig.fromJson(readMap(json['config'])),
      status: GameStatus.fromName(json['status'] as String?),
      lines: {
        for (final entry in rawLines.entries)
          entry.key: CobPlayerLine.fromJson(readMap(entry.value)),
      },
    );
  }
}
