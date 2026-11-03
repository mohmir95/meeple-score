import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';

/// A tile placement rule, shown as a card under the board tiles.
class GwtSetupRule {
  const GwtSetupRule({
    required this.titleKey,
    required this.bodyKey,
    this.asset,
  });

  final String titleKey;
  final String bodyKey;

  /// Tile art. Null draws a green and a blue teepee.
  final String? asset;
}

/// What differs between editions in the setup steps.
class GwtSetupHintsArt {
  const GwtSetupHintsArt({
    required this.tileBack1,
    required this.tileBack2,
    required this.tileBackAspect,
    required this.jobMarketToken,
    required this.rules,
    this.boardTiles = GwtSetupHints.kansasCityTiles,
    this.boardTitleKey = 'gwt.setup.tilesTitle',
    this.boardBodyKey = 'gwt.setup.tilesBody',
    this.jobMarketBodyKey = 'gwt.setup.jobMarketBody',
    this.jobMarketRows = 2,
    this.shipsAndCities = false,
    this.boardTilesPerPlayer = 0,
    this.marketTitleKey = 'gwt.setup.jobMarketTitle',
    this.marketTokenKey = 'gwt.setup.jobMarketToken',
  });

  final String tileBack1;
  final String tileBack2;
  final double tileBackAspect;
  final String jobMarketToken;
  final List<GwtSetupRule> rules;
  final int boardTiles;
  final String boardTitleKey;
  final String boardBodyKey;
  final String jobMarketBodyKey;

  /// Rows the workers fill; the last one stops left of the token.
  final int jobMarketRows;

  /// Argentina also lays out ships and city maps.
  final bool shipsAndCities;

  /// New Zealand draws 1 more board tile per player above 2.
  final int boardTilesPerPlayer;

  /// New Zealand fills a bonus tiles market instead of the job market.
  final String marketTitleKey;
  final String marketTokenKey;

  int boardTilesFor(int players) =>
      boardTiles +
      boardTilesPerPlayer * (players - GwtSetupHintsScreen.minPlayers);

  /// The player count changes the first section, so it is picked first.
  bool get playersFirst => boardTilesPerPlayer != 0;

  static const firstEdition = GwtSetupHintsArt(
    tileBack1: 'assets/games/great_western_trail/icons/tile-back-1.png',
    tileBack2: 'assets/games/great_western_trail/icons/tile-back-2.png',
    tileBackAspect: 1,
    jobMarketToken: 'assets/games/great_western_trail/icons/job-market.png',
    rules: [
      GwtSetupRule(
        titleKey: 'gwt.setup.teepeeTitle',
        bodyKey: 'gwt.setup.teepeeBody',
      ),
      GwtSetupRule(
        titleKey: 'gwt.setup.hazardTitle',
        bodyKey: 'gwt.setup.hazardBody',
        asset: 'assets/games/great_western_trail/icons/hazards.png',
      ),
    ],
  );

  static const secondEdition = GwtSetupHintsArt(
    tileBack1: 'assets/games/great_western_trail_2e/icons/tile-back-1.png',
    tileBack2: 'assets/games/great_western_trail_2e/icons/tile-back-2.png',
    tileBackAspect: 87 / 102,
    jobMarketToken: 'assets/games/great_western_trail_2e/icons/job-market.png',
    rules: [
      GwtSetupRule(
        titleKey: 'gwt.setup.outlawTitle',
        bodyKey: 'gwt.setup.outlawBody',
        asset: 'assets/games/great_western_trail_2e/icons/outlaw.png',
      ),
      GwtSetupRule(
        titleKey: 'gwt.setup.hazardTitle',
        bodyKey: 'gwt.setup.hazardBodyBag',
        asset: 'assets/games/great_western_trail_2e/icons/hazard.png',
      ),
    ],
  );

  static const argentina = GwtSetupHintsArt(
    tileBack1: '$_argentinaIcons/tile-back-a.png',
    tileBack2: '$_argentinaIcons/tile-back-b.png',
    tileBackAspect: 251 / 303,
    jobMarketToken: '$_argentinaIcons/job-market.png',
    rules: [
      GwtSetupRule(
        titleKey: 'gwt.setup.farmerTitle',
        bodyKey: 'gwt.setup.farmerBody',
        asset: '$_argentinaIcons/farmer-green.png',
      ),
      GwtSetupRule(
        titleKey: 'gwt.setup.farmerFullTitle',
        bodyKey: 'gwt.setup.farmerFullBody',
        asset: '$_argentinaIcons/farmer-blue.png',
      ),
    ],
    boardTiles: GwtSetupHints.farmerTiles,
    boardTitleKey: 'gwt.setup.farmersTitle',
    boardBodyKey: 'gwt.setup.farmersBody',
    jobMarketBodyKey: 'gwt.setup.jobMarketBodyArgentina',
    jobMarketRows: 3,
    shipsAndCities: true,
  );

  static const newZealand = GwtSetupHintsArt(
    tileBack1: '$_newZealandIcons/tile-back-a.png',
    tileBack2: '$_newZealandIcons/tile-back-b.png',
    tileBackAspect: 132 / 153,
    jobMarketToken: '$_newZealandIcons/bonus-token.png',
    rules: [
      GwtSetupRule(
        titleKey: 'gwt.setup.nzWorkerTitle',
        bodyKey: 'gwt.setup.nzWorkerBody',
        asset: '$_newZealandIcons/worker.png',
      ),
      GwtSetupRule(
        titleKey: 'gwt.setup.nzHazardTitle',
        bodyKey: 'gwt.setup.nzHazardBody',
        asset: '$_newZealandIcons/hazard.png',
      ),
    ],
    boardTiles: GwtSetupHints.newZealandTiles,
    boardTilesPerPlayer: 1,
    boardTitleKey: 'gwt.setup.nzTilesTitle',
    boardBodyKey: 'gwt.setup.nzTilesBody',
    jobMarketBodyKey: 'gwt.setup.bonusMarketBody',
    marketTitleKey: 'gwt.setup.bonusMarketTitle',
    marketTokenKey: 'gwt.setup.bonusMarketToken',
  );
}

const _argentinaIcons = 'assets/games/great_western_trail_argentina/icons';
const _newZealandIcons = 'assets/games/great_western_trail_new_zealand/icons';

/// Setup numbers from the rulebooks, shared by the editions.
class GwtSetupHints {
  const GwtSetupHints._();

  /// Tiles with a "1" back placed on the board, at any player count.
  static const kansasCityTiles = 7;

  /// Argentina: tiles with an "A" back placed on the board.
  static const farmerTiles = 5;

  /// New Zealand: "A" tiles drawn with 2 players, after 1 of each worker.
  static const newZealandTiles = 12;

  /// The job market rows are this many spaces wide.
  static const jobMarketColumns = 4;

  /// Argentina's ships: those with a sun form the loading zone.
  static const ships = 18;
  static const sunShips = 11;
  static const pileShips = ships - sunShips;

  /// Player count signs sit above columns 1–3 for 4, 3 and 2 players.
  static int startColumn(int players) => 4 - players;

  static int signPlayers(int column) => 4 - column;

  /// Each row fills from the sign to the right edge.
  static int rowWorkers(int players) => jobMarketColumns - startColumn(players);

  /// The last row stops left of the job market token in the last column.
  static int workerTiles(int players, {int rows = 2}) =>
      rowWorkers(players) * rows - 1;

  /// Left to right above the board.
  static const cities = ['leHavre', 'rotterdam', 'liverpool'];

  /// Cover tiles: all 3 cities with 2 players, only Rotterdam with 3.
  static bool cityCovered(String city, int players) =>
      players == 2 || (players == 3 && city == 'rotterdam');

  static int coveredCities(int players) =>
      cities.where((city) => cityCovered(city, players)).length;
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
    final citiesTitleKey = switch (GwtSetupHints.coveredCities(_players)) {
      0 => 'gwt.setup.citiesTitle',
      1 => 'gwt.setup.citiesTitleOne',
      _ => 'gwt.setup.citiesTitleAll',
    };

    final selector = SegmentedButton<int>(
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
            label: Text(l10n.t('gwt.setup.players', {'n': '$n'})),
          ),
      ],
      selected: {_players},
      onSelectionChanged: (selection) {
        setState(() => _players = selection.first);
      },
    );

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
                if (art.playersFirst) ...[selector, SizedBox(height: gap)],
                _Panel(
                  key: const ValueKey('gwt-setup-kansas-city'),
                  accent: accent,
                  compact: compact,
                  initiallyExpanded: true,
                  title: l10n.t(art.boardTitleKey, {
                    'n': '${art.boardTilesFor(_players)}',
                  }),
                  tileBack: art.tileBack1,
                  tileBackAspect: art.tileBackAspect,
                  body: l10n.t(art.boardBodyKey, {
                    'n': '${art.boardTilesFor(_players)}',
                  }),
                  child: _kansasCityRules(context, compact),
                ),
                if (art.shipsAndCities) ...[
                  SizedBox(height: gap),
                  _Panel(
                    key: const ValueKey('gwt-setup-ships'),
                    accent: accent,
                    compact: compact,
                    title: l10n.t('gwt.setup.shipsTitle', {
                      'n': '${GwtSetupHints.ships}',
                    }),
                    tileBack: '$_argentinaIcons/ship-back.png',
                    tileBackAspect: 400 / 256,
                    body: l10n.t('gwt.setup.shipsBody'),
                    child: const _Ships(),
                  ),
                ],
                if (!art.playersFirst) ...[SizedBox(height: gap), selector],
                SizedBox(height: gap),
                _Panel(
                  key: const ValueKey('gwt-setup-job-market'),
                  accent: accent,
                  compact: compact,
                  // With only two sections, both fit open.
                  initiallyExpanded: !art.shipsAndCities,
                  title: l10n.t(art.marketTitleKey, {
                    'n':
                        '${GwtSetupHints.workerTiles(_players, rows: art.jobMarketRows)}',
                  }),
                  tileBack: art.tileBack2,
                  tileBackAspect: art.tileBackAspect,
                  body: l10n.t(art.jobMarketBodyKey),
                  child: _JobMarket(
                    art: art,
                    players: _players,
                    compact: compact,
                  ),
                ),
                if (art.shipsAndCities) ...[
                  SizedBox(height: gap),
                  _Panel(
                    key: const ValueKey('gwt-setup-cities'),
                    accent: accent,
                    compact: compact,
                    title: l10n.t(citiesTitleKey),
                    tileBack: '$_argentinaIcons/city-center.png',
                    tileBackAspect: 1,
                    body: l10n.t('gwt.setup.citiesBody'),
                    child: _Cities(players: _players, compact: compact),
                  ),
                ],
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
    final cards = [
      for (final rule in art.rules)
        _RuleCard(
          key: ValueKey(rule.titleKey),
          icon: switch (rule.asset) {
            final asset? => tileIcon(asset),
            null => const _Teepees(size: 34),
          },
          title: l10n.t(rule.titleKey),
          body: l10n.t(rule.bodyKey),
        ),
    ];
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            cards[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }
}

/// A section that opens and closes by tapping its header.
class _Panel extends StatefulWidget {
  const _Panel({
    super.key,
    required this.accent,
    required this.compact,
    required this.title,
    required this.tileBack,
    required this.tileBackAspect,
    required this.body,
    required this.child,
    this.initiallyExpanded = false,
  });

  final Color accent;
  final bool compact;
  final String title;
  final String tileBack;
  final double tileBackAspect;
  final String body;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  static const _duration = Duration(milliseconds: 200);

  late var _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = widget.compact;
    final accent = widget.accent;
    final tileSize = compact ? 44.0 : 56.0;
    final horizontal = compact ? 20.0 : 28.0;
    final vertical = compact ? 16.0 : 20.0;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: vertical,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        widget.tileBack,
                        width: tileSize * widget.tileBackAspect,
                        height: tileSize,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: l10n.t('gwt.setup.tileBack'),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: _GwtSetupHintsScreenState._title,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                height: 1.15,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: _duration,
                        child: const Icon(
                          Icons.expand_more,
                          color: _GwtSetupHintsScreenState._title,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      0,
                      horizontal,
                      vertical,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _GwtSetupHintsScreenState._ink,
                                height: 1.35,
                              ),
                        ),
                        SizedBox(height: compact ? 16 : 20),
                        widget.child,
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.35),
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

/// The top rows of the job market, filled in the order tiles are placed.
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
    final rows = art.jobMarketRows;
    final rowWorkers = GwtSetupHints.rowWorkers(players);
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
      label: l10n.t(art.marketTitleKey, {
        'n': '${GwtSetupHints.workerTiles(players, rows: rows)}',
      }),
      // The board reads left to right in every language.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              signs,
              SizedBox(height: gap / 2),
              for (var r = 0; r < rows; r++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var c = 0; c < columns; c++)
                      if (r == rows - 1 && c == columns - 1)
                        space(
                          ClipOval(
                            child: Image.asset(
                              art.jobMarketToken,
                              width: cell * 0.7,
                              height: cell * 0.7,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              semanticLabel: l10n.t(art.marketTokenKey),
                            ),
                          ),
                        )
                      else if (c < start)
                        space(null)
                      else
                        space(
                          worker(r * rowWorkers + c - start + 1),
                          key: ValueKey(
                            'gwt-setup-worker-${r * rowWorkers + c - start + 1}',
                          ),
                          highlight: r == 0 && c == start,
                        ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Argentina: the sun ships of the loading zone and the face-down pile.
class _Ships extends StatelessWidget {
  const _Ships();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget ship(String name) => Image.asset(
      '$_argentinaIcons/$name.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ShipGroup(
            key: const ValueKey('gwt-setup-loading-zone'),
            art: Center(child: ship('ship-sun')),
            label: l10n.t('gwt.setup.shipsSun', {
              'n': '${GwtSetupHints.sunShips}',
            }),
            caption: l10n.t('gwt.setup.shipsSunCaption'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShipGroup(
            key: const ValueKey('gwt-setup-ship-pile'),
            art: Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.78,
                    child: ship('ship-plain'),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.78,
                    child: ship('ship-back'),
                  ),
                ),
              ],
            ),
            label: l10n.t('gwt.setup.shipsPlain', {
              'n': '${GwtSetupHints.pileShips}',
            }),
            caption: l10n.t('gwt.setup.shipsPlainCaption'),
          ),
        ),
      ],
    );
  }
}

class _ShipGroup extends StatelessWidget {
  const _ShipGroup({
    super.key,
    required this.art,
    required this.label,
    required this.caption,
  });

  final Widget art;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(aspectRatio: 1.45, child: art),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _GwtSetupHintsScreenState._title,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _GwtSetupHintsScreenState._ink,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Argentina: the three city maps in board order, with their cover tiles.
class _Cities extends StatelessWidget {
  const _Cities({required this.players, required this.compact});

  final int players;
  final bool compact;

  static const _covers = {
    'leHavre': 'cover-le-havre',
    'rotterdam': 'cover-rotterdam',
    'liverpool': 'cover-liverpool',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Le Havre stays on the left in every language, as on the table.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final city in GwtSetupHints.cities)
                Expanded(
                  child: Column(
                    key: ValueKey('gwt-setup-city-$city'),
                    children: [
                      ClipOval(
                        child: Image.asset(
                          // A placed cover tile shows its compass side.
                          '$_argentinaIcons/${GwtSetupHints.cityCovered(city, players) ? 'city-center' : _covers[city]}.png',
                          width: compact ? 76 : 104,
                          height: compact ? 76 : 104,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.t('gwt.setup.city.$city'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: _GwtSetupHintsScreenState._title,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          l10n.t('gwt.setup.covers$players'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _GwtSetupHintsScreenState._ink,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
