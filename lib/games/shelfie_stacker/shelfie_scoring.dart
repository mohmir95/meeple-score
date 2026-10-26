import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'shelfie_player_line.dart';
import 'shelfie_state.dart';

class ShelfieScoring {
  const ShelfieScoring._();

  static const fiveTallPoints = 6;
  static const fourTallPoints = 3;
  static const threeTallPoints = 1;
  static const shamePoints = -2;

  static int fiveTall(ShelfiePlayerLine line) => line.fiveTall * fiveTallPoints;

  static int fourTall(ShelfiePlayerLine line) => line.fourTall * fourTallPoints;

  static int threeTall(ShelfiePlayerLine line) =>
      line.threeTall * threeTallPoints;

  static int shame(ShelfiePlayerLine line) => shameFor(line.shameDice);

  /// No dice is a plain 0: on the web `0 * -2` is JavaScript's -0, which
  /// prints as "-0.0".
  static int shameFor(int dice) => dice == 0 ? 0 : dice * shamePoints;

  static int totalFor(ShelfiePlayerLine line) {
    return fiveTall(line) +
        fourTall(line) +
        threeTall(line) +
        line.pips +
        line.rewards +
        shame(line);
  }

  static bool hasAnyEntry(ShelfieState state) {
    return state.players.any((player) => !state.lineFor(player.id).isEmpty);
  }

  static List<Player> tiedByTotal(ShelfieState state) {
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

  static List<PlayerScore> scores(ShelfieState state) {
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

  /// Highest total; a tie goes to the lowest-valued Character Card still in
  /// hand, and if that ties too everyone tied shares the win.
  static List<Player> winners(ShelfieState state) {
    final tied = tiedByTotal(state);
    final lowestId = state.lowestCardPlayerId;
    if (tied.length <= 1 ||
        lowestId == null ||
        lowestId == ShelfieState.sharedVictory) {
      return tied;
    }
    final chosen = [
      for (final player in tied)
        if (player.id == lowestId) player,
    ];
    return chosen.isEmpty ? tied : chosen;
  }
}
