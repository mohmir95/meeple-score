import '../../domain/json_values.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import 'gwt_config.dart';
import 'gwt_player_line.dart';

class GwtState extends GameState {
  const GwtState({
    required this.players,
    required this.config,
    required this.status,
    required this.lines,
  });

  @override
  final List<Player> players;

  @override
  final GwtConfig config;

  @override
  final GameStatus status;

  final Map<String, GwtPlayerLine> lines;

  GwtPlayerLine lineFor(String playerId) {
    return lines[playerId] ?? const GwtPlayerLine();
  }

  GwtState copyWith({
    List<Player>? players,
    GwtConfig? config,
    GameStatus? status,
    Map<String, GwtPlayerLine>? lines,
  }) {
    return GwtState(
      players: players ?? this.players,
      config: config ?? this.config,
      status: status ?? this.status,
      lines: lines ?? this.lines,
    );
  }

  GwtState updateLine(String playerId, GwtPlayerLine line) {
    var next = Map<String, GwtPlayerLine>.from(lines);
    if (line.hasJobMarketToken) {
      next = {
        for (final entry in next.entries)
          entry.key: entry.value.copyWith(hasJobMarketToken: false),
      };
    }
    next[playerId] = line;
    return copyWith(lines: next);
  }

  @override
  GameState copyWithPlayers(List<Player> players) {
    return copyWith(
      players: players,
      lines: {
        for (final player in players)
          player.id: lines[player.id] ?? const GwtPlayerLine(),
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

  factory GwtState.fromJson(Map<String, dynamic> json) {
    final rawLines = readMap(json['lines']);
    return GwtState(
      players: readMapList(json['players']).map(Player.fromJson).toList(),
      config: GwtConfig.fromJson(readMap(json['config'])),
      status: GameStatus.fromName(json['status'] as String?),
      lines: {
        for (final entry in rawLines.entries)
          entry.key: GwtPlayerLine.fromJson(readMap(entry.value)),
      },
    );
  }
}
