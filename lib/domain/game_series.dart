import 'package:flutter/material.dart';

import 'board_game.dart';

/// Several editions of one game, shown on the home page as a single banner.
class GameSeries {
  const GameSeries({
    required this.id,
    required this.titleKey,
    required this.accentColor,
    this.bannerGameIds,
  });

  final String id;

  /// Translation key for the banner and page title.
  final String titleKey;
  final Color accentColor;

  /// The editions whose covers make up the home banner, followed by a strip
  /// that hints at the rest. Null shows every edition.
  final List<String>? bannerGameIds;

  static const greatWesternTrail = GameSeries(
    id: 'great_western_trail',
    titleKey: 'home.series.gwt',
    accentColor: Color(0xFF6B4F2A),
  );

  static const century = GameSeries(
    id: 'century',
    titleKey: 'home.series.century',
    accentColor: Color(0xFF6A2C4E),
    // The three standalone games; the "…" strip stands for the combinations.
    bannerGameIds: [
      'century_spice_road',
      'century_eastern_wonders',
      'century_a_new_world',
    ],
  );

  static const all = [greatWesternTrail, century];

  static GameSeries? byId(String? id) {
    for (final series in all) {
      if (series.id == id) {
        return series;
      }
    }
    return null;
  }
}

/// One home page banner: a single game, or a series of its editions.
sealed class HomeEntry {
  const HomeEntry();

  /// Groups each series into one entry. Series stacks always come first,
  /// in the order of their first edition, then the single games in order.
  static List<HomeEntry> group(List<BoardGame> games) {
    final stacks = <HomeEntry>[];
    final singles = <HomeEntry>[];
    final seen = <String>{};
    for (final game in games) {
      final series = GameSeries.byId(game.seriesId);
      if (series == null) {
        singles.add(SingleGameEntry(game));
      } else if (seen.add(series.id)) {
        stacks.add(
          SeriesEntry(series, [
            for (final edition in games)
              if (edition.seriesId == series.id) edition,
          ]),
        );
      }
    }
    return [...stacks, ...singles];
  }
}

class SingleGameEntry extends HomeEntry {
  const SingleGameEntry(this.game);

  final BoardGame game;
}

class SeriesEntry extends HomeEntry {
  const SeriesEntry(this.series, this.games);

  final GameSeries series;
  final List<BoardGame> games;
}
