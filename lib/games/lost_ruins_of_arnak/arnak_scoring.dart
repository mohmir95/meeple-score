import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'arnak_player_line.dart';
import 'arnak_state.dart';

class ArnakScoring {
  const ArnakScoring._();

  static int totalFor(ArnakPlayerLine line) {
    return line.research +
        line.templeTiles +
        line.idols +
        line.guardians +
        line.cards +
        ArnakPlayerLine.normalizeFear(line.fear);
  }

  static bool hasAnyEntry(ArnakState state) {
    return state.players.any((player) {
      final line = state.lineFor(player.id);
      return line.research != 0 ||
          line.templeTiles != 0 ||
          line.idols != 0 ||
          line.guardians != 0 ||
          line.cards != 0 ||
          line.fear != 0;
    });
  }

  static List<Player> tiedByTotal(ArnakState state) {
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

  static List<PlayerScore> scores(ArnakState state) {
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

  static List<Player> winners(ArnakState state) {
    final tied = tiedByTotal(state);
    if (tied.length <= 1) {
      return tied;
    }

    final firstId = state.lostTempleFirstPlayerId;
    if (firstId == null) {
      return tied;
    }

    if (firstId != ArnakState.nobodyReachedLostTemple) {
      final chosen = [
        for (final player in tied)
          if (player.id == firstId) player,
      ];
      if (chosen.isNotEmpty) {
        return chosen;
      }
    }

    final research = {
      for (final player in tied) player.id: state.lineFor(player.id).research,
    };
    final bestResearch = research.values.reduce((a, b) => a > b ? a : b);
    return [
      for (final player in tied)
        if (research[player.id] == bestResearch) player,
    ];
  }
}
