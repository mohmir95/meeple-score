import 'package:flutter/material.dart';

import 'board_game.dart';

/// Several editions of one game, shown on the home page as a single banner.
class GameSeries {
  const GameSeries({
    required this.id,
    required this.titleKey,
    required this.accentColor,
  });

  final String id;

  /// Translation key for the banner and page title.
  final String titleKey;
  final Color accentColor;

  static const greatWesternTrail = GameSeries(
    id: 'great_western_trail',
    titleKey: 'game.gwt.series',
    accentColor: Color(0xFF6B4F2A),
  );

  static const all = [greatWesternTrail];

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

  /// Groups each series into one entry, at the place of its first edition.
  static List<HomeEntry> group(List<BoardGame> games) {
    final entries = <HomeEntry>[];
    final seen = <String>{};
    for (final game in games) {
      final series = GameSeries.byId(game.seriesId);
      if (series == null) {
        entries.add(SingleGameEntry(game));
      } else if (seen.add(series.id)) {
        entries.add(
          SeriesEntry(series, [
            for (final edition in games)
              if (edition.seriesId == series.id) edition,
          ]),
        );
      }
    }
    return entries;
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
