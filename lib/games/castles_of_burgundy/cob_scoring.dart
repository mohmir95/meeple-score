import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'cob_player_line.dart';
import 'cob_state.dart';

class CobScoring {
  const CobScoring._();

  static int totalFor(CobPlayerLine line) => line.victoryPoints;

  static bool hasAnyEntry(CobState state) {
    return state.players.any(
      (player) => state.lineFor(player.id).victoryPoints != 0,
    );
  }

  static List<PlayerScore> scores(CobState state) {
    final winningIds = {for (final player in winners(state)) player.id};
    return [
      for (final player in state.players)
        PlayerScore(
          player: player,
          total: totalFor(state.lineFor(player.id)),
          isLeader: winningIds.contains(player.id),
        ),
    ];
  }

  static List<Player> winners(CobState state) {
    if (state.players.isEmpty || !hasAnyEntry(state)) {
      return const [];
    }
    final totals = {
      for (final player in state.players)
        player.id: totalFor(state.lineFor(player.id)),
    };
    final best = totals.values.reduce((a, b) => a > b ? a : b);
    return [
      for (final player in state.players)
        if (totals[player.id] == best) player,
    ];
  }
}
