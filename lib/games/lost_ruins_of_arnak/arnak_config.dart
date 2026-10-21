import '../../domain/json_values.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/player.dart';
import 'arnak_leaders.dart';

class ArnakConfig extends GameConfig {
  const ArnakConfig({this.leadersEnabled = false, this.leaders = const {}});

  /// Playing with the Expedition Leaders: each player picks a leader.
  final bool leadersEnabled;

  /// Leader id by player id. Kept while the toggle is off so switching it
  /// back on restores the picks.
  final Map<String, String> leaders;

  /// The leader [playerId] plays, or `null` if leaders are off or unpicked.
  ArnakLeader? leaderFor(String playerId) {
    return leadersEnabled ? ArnakLeader.byId(leaders[playerId]) : null;
  }

  ArnakConfig copyWith({bool? leadersEnabled, Map<String, String>? leaders}) {
    return ArnakConfig(
      leadersEnabled: leadersEnabled ?? this.leadersEnabled,
      leaders: leaders ?? this.leaders,
    );
  }

  /// Gives [playerId] [leaderId] (or clears it when `null`). Leaders are
  /// unique: if another player had it, they swap.
  ArnakConfig withLeader(String playerId, String? leaderId) {
    final next = Map<String, String>.from(leaders);
    final previous = next[playerId];
    if (leaderId == null) {
      next.remove(playerId);
      return copyWith(leaders: next);
    }
    for (final entry in leaders.entries) {
      if (entry.key != playerId && entry.value == leaderId) {
        if (previous == null) {
          next.remove(entry.key);
        } else {
          next[entry.key] = previous;
        }
      }
    }
    next[playerId] = leaderId;
    return copyWith(leaders: next);
  }

  /// Drops picks for players who are no longer in the game.
  ArnakConfig forPlayers(List<Player> players) {
    final ids = {for (final player in players) player.id};
    return copyWith(
      leaders: {
        for (final entry in leaders.entries)
          if (ids.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'leadersEnabled': leadersEnabled,
    'leaders': leaders,
  };

  factory ArnakConfig.fromJson(Map<String, dynamic> json) {
    return ArnakConfig(
      leadersEnabled: readBool(json['leadersEnabled']),
      leaders: {
        for (final entry in readMap(json['leaders']).entries)
          if (entry.value is String) entry.key: entry.value as String,
      },
    );
  }
}
