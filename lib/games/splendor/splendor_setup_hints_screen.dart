import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'splendor_game.dart';

/// Setup numbers from the rulebook that change with the player count.
class SplendorSetup {
  const SplendorSetup._();

  static const fullGemsPerColor = 7;
  static const gold = 5;
  static const levels = 3;
  static const faceUpPerLevel = 4;

  /// Cards in the level 1, 2 and 3 decks.
  static const deckSizes = [40, 30, 20];

  /// Gems returned to the box from each colour: none at 4, 2 at 3, 3 at 2.
  static int removedPerColor(int players) {
    if (players >= 4) {
      return 0;
    }
    return players == 3 ? 2 : 3;
  }

  static int gemsPerColor(int players) =>
      fullGemsPerColor - removedPerColor(players);

  /// One more Noble tile than there are players.
  static int nobles(int players) => players + 1;
}

class SplendorSetupHintsScreen extends StatefulWidget {
  const SplendorSetupHintsScreen({super.key});

  @override
  State<SplendorSetupHintsScreen> createState() =>
      _SplendorSetupHintsScreenState();
}

class _SplendorSetupHintsScreenState extends State<SplendorSetupHintsScreen> {
  static const _ink = Color(0xFF1E2A3A);
  static const _muted = Color(0xFF55606C);

  /// Gems in the rulebook's order, then gold.
  static const _gems = [
    (key: 'diamond', color: Color(0xFFF3F4F6)),
    (key: 'sapphire', color: Color(0xFF1F6FC5)),
    (key: 'emerald', color: Color(0xFF1E9A52)),
    (key: 'ruby', color: Color(0xFFD7372A)),
    (key: 'onyx', color: Color(0xFF2A2A2E)),
  ];
  static const _goldColor = Color(0xFFE2B33C);

  /// Deck backs, level 1 (bottom) to level 3 (top).
  static const _deckColors = [
    Color(0xFF2E8B57),
    Color(0xFFC08A26),
    Color(0xFF2F5FA8),
  ];

  var _players = const SplendorGame().maxPlayers;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    const game = SplendorGame();
    final gap = SizedBox(height: compact ? 16 : 20);

    return AppPage(
      title: l10n.t('hub.setupHints'),
      coverImageAsset: SplendorGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  key: const ValueKey('splendor-setup-players'),
                  showSelectedIcon: false,
                  segments: [
                    for (var n = game.minPlayers; n <= game.maxPlayers; n++)
                      ButtonSegment(
                        value: n,
                        label: Text(
                          l10n.t('splendor.setup.players', {'n': '$n'}),
                        ),
                      ),
                  ],
                  selected: {_players},
                  onSelectionChanged: (selection) {
                    setState(() => _players = selection.first);
                  },
                ),
                gap,
                _gemsPanel(context, compact),
                gap,
                _noblesPanel(context, compact),
                gap,
                _cardsPanel(context, compact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gemsPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final removed = SplendorSetup.removedPerColor(_players);
    final perColor = SplendorSetup.gemsPerColor(_players);
    final tokenSize = compact ? 44.0 : 60.0;

    Widget column({
      required String key,
      required Widget token,
      required int count,
      required String label,
      int removed = 0,
    }) {
      return Expanded(
        child: Column(
          key: ValueKey('splendor-setup-gem-$key'),
          children: [
            token,
            const SizedBox(height: 8),
            Text(
              '× $count',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 18 : 24,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 14,
              ),
            ),
            if (removed > 0)
              Text(
                l10n.t('splendor.setup.removed', {'n': '$removed'}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 10 : 12,
                ),
              ),
          ],
        ),
      );
    }

    return _Panel(
      key: const ValueKey('splendor-setup-gems'),
      compact: compact,
      title: l10n.t('splendor.setup.gemsTitle', {'n': '$perColor'}),
      body: removed == 0
          ? l10n.t('splendor.setup.gemsAll')
          : l10n.t('splendor.setup.gemsRemove', {
              'n': '$removed',
              'left': '$perColor',
            }),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final gem in _gems)
            column(
              key: gem.key,
              token: _Token(color: gem.color, size: tokenSize),
              count: perColor,
              label: l10n.t('splendor.setup.gem.${gem.key}'),
              removed: removed,
            ),
          column(
            key: 'gold',
            token: _Token(color: _goldColor, size: tokenSize, gold: true),
            count: SplendorSetup.gold,
            label: l10n.t('splendor.setup.gem.gold'),
          ),
        ],
      ),
    );
  }

  Widget _noblesPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final nobles = SplendorSetup.nobles(_players);
    final tileSize = compact ? 54.0 : 76.0;
    return _Panel(
      key: const ValueKey('splendor-setup-nobles'),
      compact: compact,
      title: l10n.t('splendor.setup.noblesTitle', {'n': '$nobles'}),
      body: l10n.t('splendor.setup.noblesBody', {'n': '$nobles'}),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: compact ? 8 : 14,
        runSpacing: 8,
        children: [
          for (var i = 0; i < nobles; i++)
            _NobleTile(
              key: ValueKey('splendor-setup-noble-$i'),
              size: tileSize,
              semanticLabel: l10n.t('splendor.setup.noble'),
            ),
        ],
      ),
    );
  }

  Widget _cardsPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final cardWidth = compact ? 40.0 : 58.0;
    final cardHeight = cardWidth * 1.4;
    final spacing = compact ? 6.0 : 10.0;
    return _Panel(
      key: const ValueKey('splendor-setup-cards'),
      compact: compact,
      title: l10n.t('splendor.setup.cardsTitle', {
        'n': '${SplendorSetup.levels * SplendorSetup.faceUpPerLevel}',
      }),
      body: l10n.t('splendor.setup.cardsBody'),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            // Level 3 on top, level 1 at the bottom, as on the table.
            for (var level = SplendorSetup.levels; level >= 1; level--) ...[
              if (level < SplendorSetup.levels) SizedBox(height: spacing),
              Row(
                key: ValueKey('splendor-setup-level-$level'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth * 1.6,
                    child: Text(
                      l10n.t('splendor.setup.deckSize', {
                        'n': '${SplendorSetup.deckSizes[level - 1]}',
                      }),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  _DeckCard(
                    width: cardWidth,
                    height: cardHeight,
                    color: _deckColors[level - 1],
                    level: level,
                  ),
                  SizedBox(width: spacing * 1.6),
                  for (var i = 0; i < SplendorSetup.faceUpPerLevel; i++) ...[
                    if (i > 0) SizedBox(width: spacing),
                    _FaceUpCard(
                      width: cardWidth,
                      height: cardHeight,
                      color: _deckColors[level - 1],
                    ),
                  ],
                  SizedBox(width: cardWidth * 1.6 + spacing),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.compact,
    required this.title,
    required this.body,
    required this.child,
  });

  final bool compact;
  final String title;
  final String body;
  final Widget child;

  static const _gold = Color(0xFFF2C230);

  @override
  Widget build(BuildContext context) {
    const accent = SplendorGame.navy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navy band with gold lettering, like the rulebook headers.
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF173F75), accent, Color(0xFF173F75)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18.5)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 10 : 12,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1E2A3A),
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A round poker-chip style piece with a gem (or a coin mark for gold).
class _Token extends StatelessWidget {
  const _Token({required this.color, required this.size, this.gold = false});

  final Color color;
  final double size;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final light = color.computeLuminance() > 0.6;
    final rim = Color.lerp(color, Colors.black, light ? 0.22 : 0.3)!;
    final mark = light
        ? const Color(0xFF8FA3B8)
        : Color.lerp(color, Colors.white, 0.55)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ),
        border: Border.all(color: rim, width: size * 0.07),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: gold
          ? Center(
              child: Text(
                'S',
                style: TextStyle(
                  color: const Color(0xFF8A6512),
                  fontSize: size * 0.48,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1,
                ),
              ),
            )
          : Icon(Icons.diamond, color: mark, size: size * 0.52),
    );
  }
}

/// A Noble tile: square portrait frame worth 3 Prestige points.
class _NobleTile extends StatelessWidget {
  const _NobleTile({
    super.key,
    required this.size,
    required this.semanticLabel,
  });

  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB3563F), Color(0xFF6E2C3F)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(0.35, 0.3),
              child: Icon(
                Icons.person,
                color: Colors.white.withValues(alpha: 0.32),
                size: size * 0.8,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(size * 0.12),
                  ),
                ),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: size * 0.05),
                child: Text(
                  '3',
                  style: TextStyle(
                    color: const Color(0xFF4A4F57),
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.26,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A face-down deck, its level shown by dots like the printed backs.
class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.width,
    required this.height,
    required this.color,
    required this.level,
  });

  final double width;
  final double height;
  final Color color;
  final int level;

  @override
  Widget build(BuildContext context) {
    final dot = width * 0.13;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.2)!, color],
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          // Offset shadows suggest a stack of cards.
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.35)!,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Color.lerp(color, Colors.black, 0.5)!,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: height * 0.1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < level; i++) ...[
            if (i > 0) SizedBox(width: dot * 0.4),
            Container(
              width: dot,
              height: dot,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FaceUpCard extends StatelessWidget {
  const _FaceUpCard({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            height: height * 0.24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(width * 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
