import '../../domain/json_values.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/player.dart';
import 'arnak_config.dart';
import 'arnak_player_line.dart';

class ArnakState extends GameState {
  const ArnakState({
    required this.players,
    required this.config,
    required this.status,
    required this.lines,
    this.lostTempleFirstPlayerId,
  });

  /// Empty string means nobody reached the Lost Temple.
  static const nobodyReachedLostTemple = '';

  static const _unset = Object();

  @override
  final List<Player> players;

  @override
  final ArnakConfig config;

  @override
  final GameStatus status;

  final Map<String, ArnakPlayerLine> lines;

  /// `null` if not chosen yet. [nobodyReachedLostTemple] if no one reached it.
  final String? lostTempleFirstPlayerId;

  ArnakPlayerLine lineFor(String playerId) {
    return lines[playerId] ?? const ArnakPlayerLine();
  }

  ArnakState copyWith({
    List<Player>? players,
    ArnakConfig? config,
    GameStatus? status,
    Map<String, ArnakPlayerLine>? lines,
    Object? lostTempleFirstPlayerId = _unset,
  }) {
    return ArnakState(
      players: players ?? this.players,
      config: config ?? this.config,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      lostTempleFirstPlayerId: identical(lostTempleFirstPlayerId, _unset)
          ? this.lostTempleFirstPlayerId
          : lostTempleFirstPlayerId as String?,
    );
  }

  ArnakState updateLine(String playerId, ArnakPlayerLine line) {
    final next = Map<String, ArnakPlayerLine>.from(lines);
    next[playerId] = line;
    return copyWith(lines: next);
  }

  @override
  GameState copyWithPlayers(List<Player> players) {
    final ids = {for (final player in players) player.id};
    final first = lostTempleFirstPlayerId;
    final kept =
        first == null || first == nobodyReachedLostTemple || ids.contains(first)
        ? first
        : null;
    return ArnakState(
      players: players,
      config: config,
      status: status,
      lines: {
        for (final player in players)
          player.id: lines[player.id] ?? const ArnakPlayerLine(),
      },
      lostTempleFirstPlayerId: kept,
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
      'lostTempleFirstPlayerId': lostTempleFirstPlayerId,
    };
  }

  factory ArnakState.fromJson(Map<String, dynamic> json) {
    final rawLines = readMap(json['lines']);
    final rawFirst = json['lostTempleFirstPlayerId'];
    return ArnakState(
      players: readMapList(json['players']).map(Player.fromJson).toList(),
      config: ArnakConfig.fromJson(readMap(json['config'])),
      status: GameStatus.fromName(json['status'] as String?),
      lines: {
        for (final entry in rawLines.entries)
          entry.key: ArnakPlayerLine.fromJson(readMap(entry.value)),
      },
      lostTempleFirstPlayerId: rawFirst is String ? rawFirst : null,
    );
  }
}
