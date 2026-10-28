import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';

/// What differs between editions in setup steps 6 and 7.
class GwtSetupHintsArt {
  const GwtSetupHintsArt({
    required this.tileBack1,
    required this.tileBack2,
    required this.tileBackAspect,
    required this.hazardAsset,
    required this.jobMarketToken,
    required this.tribeKey,
    required this.hazardBodyKey,
    this.tribeAsset,
  });

  final String tileBack1;
  final String tileBack2;
  final double tileBackAspect;
  final String hazardAsset;
  final String jobMarketToken;

  /// Prefix of the title/body keys for the non-hazard tiles:
  /// teepees in First Edition, outlaws in Second Edition.
  final String tribeKey;

  /// Tile art for [tribeKey]. Null draws a green and a blue teepee.
  final String? tribeAsset;

  /// Full hazard sections send tiles back to the supply (First Edition)
  /// or into the bag for a redraw (Second Edition).
  final String hazardBodyKey;

  static const firstEdition = GwtSetupHintsArt(
    tileBack1: 'assets/games/great_western_trail/icons/tile-back-1.png',
    tileBack2: 'assets/games/great_western_trail/icons/tile-back-2.png',
    tileBackAspect: 1,
    hazardAsset: 'assets/games/great_western_trail/icons/hazards.png',
    jobMarketToken: 'assets/games/great_western_trail/icons/job-market.png',
    tribeKey: 'gwt.setup.teepee',
    hazardBodyKey: 'gwt.setup.hazardBody',
  );

  static const secondEdition = GwtSetupHintsArt(
    tileBack1: 'assets/games/great_western_trail_2e/icons/tile-back-1.png',
    tileBack2: 'assets/games/great_western_trail_2e/icons/tile-back-2.png',
    tileBackAspect: 87 / 102,
    hazardAsset: 'assets/games/great_western_trail_2e/icons/hazard.png',
    jobMarketToken: 'assets/games/great_western_trail_2e/icons/job-market.png',
    tribeKey: 'gwt.setup.outlaw',
    tribeAsset: 'assets/games/great_western_trail_2e/icons/outlaw.png',
    hazardBodyKey: 'gwt.setup.hazardBodyBag',
  );
}

/// Setup numbers from steps 6 and 7 of the rulebook, shared by both editions.
class GwtSetupHints {
  const GwtSetupHints._();

  /// Tiles with a "1" back placed on the board, at any player count.
  static const kansasCityTiles = 7;

  /// The job market rows are this many spaces wide.
  static const jobMarketColumns = 4;

  /// Player count signs sit above columns 1–3 for 4, 3 and 2 players.
  static int startColumn(int players) => 4 - players;

  static int signPlayers(int column) => 4 - column;

  /// Spaces filled in each row: the top row runs to the right edge, the
  /// second stops left of the job market token in the last column.
  static int topRowWorkers(int players) =>
      jobMarketColumns - startColumn(players);

  static int secondRowWorkers(int players) => topRowWorkers(players) - 1;

  static int workerTiles(int players) =>
      topRowWorkers(players) + secondRowWorkers(players);
}

class GwtSetupHintsScreen extends StatefulWidget {
  const GwtSetupHintsScreen({super.key, required this.game, required this.art});

  final BoardGame game;
  final GwtSetupHintsArt art;

  /// The job market rules only cover 2–4 players; solo has its own setup.
  static const minPlayers = 2;

  @override
  State<GwtSetupHintsScreen> createState() => _GwtSetupHintsScreenState();
}

class _GwtSetupHintsScreenState extends State<GwtSetupHintsScreen> {
  static const _ink = Color(0xFF2A2620);
  static const _title = Color(0xFF6B2030);

  late var _players = widget.game.maxPlayers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final gap = compact ? 16.0 : 20.0;
    final accent = widget.game.accentColor;
    final art = widget.art;

    return AppPage(
      title: l10n.t('hub.setupHints'),
      coverImageAsset: widget.game.coverImageAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  key: const ValueKey('gwt-setup-kansas-city'),
                  accent: accent,
                  compact: compact,
                  title: l10n.t('gwt.setup.tilesTitle', {
                    'n': '${GwtSetupHints.kansasCityTiles}',
                  }),
                  tileBack: art.tileBack1,
                  tileBackAspect: art.tileBackAspect,
                  body: l10n.t('gwt.setup.tilesBody', {
                    'n': '${GwtSetupHints.kansasCityTiles}',
                  }),
                  child: _kansasCityRules(context, compact),
                ),
                SizedBox(height: gap),
                _Panel(
                  key: const ValueKey('gwt-setup-job-market'),
                  accent: accent,
                  compact: compact,
                  title: l10n.t('gwt.setup.jobMarketTitle', {
                    'n': '${GwtSetupHints.workerTiles(_players)}',
                  }),
                  tileBack: art.tileBack2,
                  tileBackAspect: art.tileBackAspect,
                  body: l10n.t('gwt.setup.jobMarketBody'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<int>(
                        key: const ValueKey('gwt-setup-players'),
                        showSelectedIcon: false,
                        segments: [
                          for (
                            var n = GwtSetupHintsScreen.minPlayers;
                            n <= widget.game.maxPlayers;
                            n++
                          )
                            ButtonSegment(
                              value: n,
                              label: Text(
                                l10n.t('gwt.setup.players', {'n': '$n'}),
                              ),
                            ),
                        ],
                        selected: {_players},
                        onSelectionChanged: (selection) {
                          setState(() => _players = selection.first);
                        },
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      _JobMarket(
                        art: art,
                        players: _players,
                        compact: compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _kansasCityRules(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final art = widget.art;
    Widget tileIcon(String asset) => Image.asset(
      asset,
      width: 34,
      height: 40,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    final tribe = _RuleCard(
      key: const ValueKey('gwt-setup-tribe'),
      icon: switch (art.tribeAsset) {
        final asset? => tileIcon(asset),
        null => const _Teepees(size: 34),
      },
      title: l10n.t('${art.tribeKey}Title'),
      body: l10n.t('${art.tribeKey}Body'),
    );
    final hazard = _RuleCard(
      key: const ValueKey('gwt-setup-hazard'),
      icon: tileIcon(art.hazardAsset),
      title: l10n.t('gwt.setup.hazardTitle'),
      body: l10n.t(art.hazardBodyKey),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tribe, const SizedBox(height: 10), hazard],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tribe),
          const SizedBox(width: 12),
          Expanded(child: hazard),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.accent,
    required this.compact,
    required this.title,
    required this.tileBack,
    required this.tileBackAspect,
    required this.body,
    required this.child,
  });

  final Color accent;
  final bool compact;
  final String title;
  final String tileBack;
  final double tileBackAspect;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tileSize = compact ? 44.0 : 56.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 28,
          vertical: compact ? 22 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  tileBack,
                  width: tileSize * tileBackAspect,
                  height: tileSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  semanticLabel: l10n.t('gwt.setup.tileBack'),
                ),
                SizedBox(width: compact ? 10 : 14),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _GwtSetupHintsScreenState._title,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _GwtSetupHintsScreenState._ink,
                height: 1.35,
              ),
            ),
            SizedBox(height: compact ? 16 : 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final Widget icon;
  final String title;
  final String body;

  static const _ink = Color(0xFF4A3F1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9DC8C).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ink.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ink,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A green and a blue teepee, the two teepee tile colours.
class _Teepees extends StatelessWidget {
  const _Teepees({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.change_history,
              size: size * 0.7,
              color: const Color(0xFF3E8E41),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.change_history,
              size: size * 0.7,
              color: const Color(0xFF2F6DB5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The top two rows of the job market, filled in the order tiles are placed.
class _JobMarket extends StatelessWidget {
  const _JobMarket({
    required this.art,
    required this.players,
    required this.compact,
  });

  final GwtSetupHintsArt art;
  final int players;
  final bool compact;

  static const _ink = Color(0xFF6B2030);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const columns = GwtSetupHints.jobMarketColumns;
    final start = GwtSetupHints.startColumn(players);
    final topRow = GwtSetupHints.topRowWorkers(players);
    final cell = compact ? 56.0 : 72.0;
    final gap = compact ? 6.0 : 8.0;

    Widget space(Widget? child, {Key? key, bool highlight = false}) {
      return Container(
        key: key,
        width: cell,
        height: cell,
        margin: EdgeInsets.all(gap / 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? _ink : _ink.withValues(alpha: 0.2),
            width: highlight ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    Widget worker(int order) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Image.asset(
            art.tileBack2,
            width: (cell - 6) * art.tileBackAspect,
            height: cell - 6,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _ink,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$order',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final signs = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < columns; c++)
          SizedBox(
            width: cell + gap,
            child: c < columns - 1
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c == start ? _ink : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _ink.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.t('gwt.setup.sign', {
                          'n': '${GwtSetupHints.signPlayers(c)}',
                        }),
                        style: TextStyle(
                          color: c == start ? Colors.white : _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
      ],
    );

    return Semantics(
      label: l10n.t('gwt.setup.jobMarketTitle', {
        'n': '${GwtSetupHints.workerTiles(players)}',
      }),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            signs,
            SizedBox(height: gap / 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < columns; c++)
                  c < start
                      ? space(null)
                      : space(
                          worker(c - start + 1),
                          key: ValueKey('gwt-setup-worker-${c - start + 1}'),
                          highlight: c == start,
                        ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < columns; c++)
                  if (c == columns - 1)
                    space(
                      Image.asset(
                        art.jobMarketToken,
                        width: cell * 0.7,
                        height: cell * 0.7,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: l10n.t('gwt.setup.jobMarketToken'),
                      ),
                    )
                  else if (c < start)
                    space(null)
                  else
                    space(
                      worker(topRow + c - start + 1),
                      key: ValueKey(
                        'gwt-setup-worker-${topRow + c - start + 1}',
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
