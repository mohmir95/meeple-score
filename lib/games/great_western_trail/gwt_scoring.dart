import '../../domain/models/player.dart';
import '../../domain/models/player_score.dart';
import 'gwt_player_line.dart';
import 'gwt_state.dart';

enum GwtPadKind { classic, argentina, newZealand, elPaso }

class GwtScoring {
  const GwtScoring._();

  static int coinPoints(int dollars) => dollars < 0 ? 0 : dollars ~/ 5;

  static int threeVpPoints(bool cleared) =>
      discPoints(cleared, GwtPadKind.classic);

  static int discPoints(bool cleared, GwtPadKind pad) {
    if (!cleared) {
      return 0;
    }
    return pad == GwtPadKind.argentina ? 2 : 3;
  }

  /// Job market token: 2 VP. New Zealand's bonus tiles market token: 5 VP.
  /// El Paso gives the same 2 VP to the player who triggers the game end.
  static int jobMarketPoints(
    bool hasToken, [
    GwtPadKind pad = GwtPadKind.classic,
  ]) {
    if (!hasToken) {
      return 0;
    }
    return pad == GwtPadKind.newZealand ? 5 : 2;
  }

  static int totalFor(
    GwtPlayerLine line, {
    GwtPadKind pad = GwtPadKind.classic,
  }) {
    if (pad == GwtPadKind.elPaso) {
      return coinPoints(line.dollars) +
          line.buildings +
          line.tradingPosts +
          line.workers +
          line.cattle +
          line.bonusTiles +
          line.objectives +
          jobMarketPoints(line.hasJobMarketToken, pad);
    }
    final shared =
        coinPoints(line.dollars) +
        line.buildings +
        line.stations +
        line.cattle +
        line.objectives +
        line.stationMasters +
        line.playerBoard +
        discPoints(line.clearedThreeVpSpace, pad) +
        jobMarketPoints(line.hasJobMarketToken, pad);
    if (pad == GwtPadKind.argentina) {
      return shared + line.ships + line.cityMaps + line.farmers;
    }
    if (pad == GwtPadKind.newZealand) {
      return shared +
          line.tradingPosts +
          line.harbours +
          line.pathfinder +
          line.hazards;
    }
    return shared + line.deliveries + line.hazards;
  }

  /// El Paso ties go to the most money left after converting it to VP.
  /// Other editions share the win.
  static int tieBreak(GwtPlayerLine line, GwtPadKind pad) {
    return pad == GwtPadKind.elPaso ? line.dollars % 5 : 0;
  }

  static bool hasAnyEntry(GwtState state) {
    return state.players.any((player) {
      final line = state.lineFor(player.id);
      return line.dollars != 0 ||
          line.buildings != 0 ||
          line.deliveries != 0 ||
          line.ships != 0 ||
          line.cityMaps != 0 ||
          line.stations != 0 ||
          line.hazards != 0 ||
          line.farmers != 0 ||
          line.tradingPosts != 0 ||
          line.harbours != 0 ||
          line.pathfinder != 0 ||
          line.workers != 0 ||
          line.bonusTiles != 0 ||
          line.cattle != 0 ||
          line.objectives != 0 ||
          line.stationMasters != 0 ||
          line.playerBoard != 0 ||
          line.clearedThreeVpSpace ||
          line.hasJobMarketToken;
    });
  }

  static List<PlayerScore> scores(
    GwtState state, {
    GwtPadKind pad = GwtPadKind.classic,
  }) {
    final totals = {
      for (final player in state.players)
        player.id: totalFor(state.lineFor(player.id), pad: pad),
    };
    final best = totals.values.reduce((a, b) => a > b ? a : b);
    final started = hasAnyEntry(state);
    int tieOf(Player player) => tieBreak(state.lineFor(player.id), pad);
    final bestTie = state.players
        .where((player) => totals[player.id] == best)
        .map(tieOf)
        .reduce((a, b) => a > b ? a : b);

    return [
      for (final player in state.players)
        PlayerScore(
          player: player,
          total: totals[player.id] ?? 0,
          isLeader:
              started && totals[player.id] == best && tieOf(player) == bestTie,
        ),
    ];
  }

  static List<Player> winners(
    GwtState state, {
    GwtPadKind pad = GwtPadKind.classic,
  }) {
    return [
      for (final score in scores(state, pad: pad))
        if (score.isLeader) score.player,
    ];
  }
}
