import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'gwt_bonus_cards.dart';

/// Builds the New Zealand bonus cards supply for 2–4 players.
class GwtBonusCardsRandomizerScreen extends StatefulWidget {
  const GwtBonusCardsRandomizerScreen({
    super.key,
    required this.game,
    this.random,
    this.initialSupply,
  });

  final BoardGame game;

  /// Injectable for tests.
  final math.Random? random;
  final GwtBonusCardsSupply? initialSupply;

  @override
  State<GwtBonusCardsRandomizerScreen> createState() =>
      _GwtBonusCardsRandomizerScreenState();
}

class _GwtBonusCardsRandomizerScreenState
    extends State<GwtBonusCardsRandomizerScreen> {
  static const _playerCounts = [2, 3, 4];

  late final math.Random _random = widget.random ?? math.Random();
  late GwtBonusCardsSupply _supply =
      widget.initialSupply ?? GwtBonusCardsSupply.random(_random);
  var _players = 2;

  /// Bumped on every draw so the cards replay their fade-in.
  var _drawId = 0;

  var _precached = false;

  void _draw() {
    setState(() {
      _supply = GwtBonusCardsSupply.random(_random);
      _drawId++;
    });
  }

  /// Loads every card and tile up front, so the stacks never show empty
  /// while an image downloads and each Randomize swaps cards instantly.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) {
      return;
    }
    _precached = true;
    for (var set = 1; set <= GwtBonusCardsSupply.setCount; set++) {
      precacheImage(AssetImage(GwtBonusCardsSupply.cardAsset(set)), context);
    }
    for (final tile in GwtBonusTile.values) {
      precacheImage(AssetImage(tile.asset), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final perSet = GwtBonusCardsSupply.cardsPerSet(_players);

    return AppPage(
      title: l10n.t('hub.bonusCardsRandomizer'),
      coverImageAsset: widget.game.coverImageAsset,
      body: Padding(
        padding: EdgeInsets.all(compact ? 12 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.t('gwt.bonusCards.hint'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                // One row on every screen; phones label the segments with
                // just the number, after a players icon.
                Row(
                  children: [
                    if (compact) ...[
                      Icon(
                        Icons.group_outlined,
                        semanticLabel: l10n.t('players.title'),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Shrinks rather than overflowing on the narrowest phones.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: SegmentedButton<int>(
                          key: const ValueKey('gwt-bonus-players'),
                          segments: [
                            for (final count in _playerCounts)
                              ButtonSegment(
                                value: count,
                                label: Text(
                                  compact
                                      ? '$count'
                                      : l10n.t('gwt.bonusCards.players', {
                                          'n': '$count',
                                        }),
                                ),
                              ),
                          ],
                          selected: {_players},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) =>
                              setState(() => _players = selection.single),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      key: const ValueKey('gwt-bonus-randomize'),
                      onPressed: _draw,
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.t('gwt.randomizer.randomize')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final phone = constraints.maxWidth < 560;
                      final columns = phone ? 2 : 4;
                      final gap = phone ? 10.0 : 12.0;
                      final fill =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      // Phones show two rows of two, sized so both rows fit
                      // the screen; very short screens scroll instead.
                      final width = phone
                          ? _BonusStack.widthForHeight(
                              (constraints.maxHeight - gap) / 2,
                            ).clamp(120.0, math.min(fill, 180.0)).toDouble()
                          : fill;
                      // Explicit rows, so narrow boxes never pack 3 across.
                      const tiles = GwtBonusTile.values;
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            for (
                              var row = 0;
                              row < tiles.length;
                              row += columns
                            )
                              Padding(
                                padding: EdgeInsets.only(
                                  top: row == 0 ? 0 : gap,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final tile
                                        in tiles.skip(row).take(columns)) ...[
                                      if (tile != tiles[row])
                                        SizedBox(width: gap),
                                      SizedBox(
                                        width: width,
                                        child: _BonusStack(
                                          key: ValueKey(
                                            'gwt-bonus-${tile.key}',
                                          ),
                                          tile: tile,
                                          set: _supply.setFor(tile),
                                          cards: perSet,
                                          drawId: _drawId,
                                          accent: widget.game.accentColor,
                                          compact: width < 140,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One bonus cards tile with the stack that goes below it.
class _BonusStack extends StatelessWidget {
  const _BonusStack({
    super.key,
    required this.tile,
    required this.set,
    required this.cards,
    required this.drawId,
    required this.accent,
    required this.compact,
  });

  final GwtBonusTile tile;
  final int set;
  final int cards;
  final int drawId;
  final Color accent;
  final bool compact;

  static const _ink = Color(0xFF2A2620);
  static const _wine = Color(0xFF6B2030);

  /// Tile photo height / width.
  static const _tileAspect = 196 / 400;

  /// Widest (non-compact) stack whose height stays within [height]: padding,
  /// tile, card, and the two text lines below.
  static double widthForHeight(double height) {
    const padding = 10.0, gaps = 16.0, text = 48.0;
    final perWidth = _tileAspect + 1 / GwtBonusCardsSupply.cardAspectRatio;
    return (height - 2 * padding - gaps - text) / perWidth + 2 * padding;
  }

  /// One line that shrinks to fit the narrow phone columns.
  Widget _line(String text, TextStyle? style) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final gap = compact ? 4.0 : 8.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E3),
        borderRadius: BorderRadius.circular(compact ? 10 : 16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 5 : 10),
        child: Column(
          children: [
            // The sorting tile sits above its stack, as on the table.
            Image.asset(
              tile.asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              semanticLabel: l10n.t('gwt.bonusCards.${tile.key}'),
            ),
            SizedBox(height: gap),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: AspectRatio(
                key: ValueKey('$drawId-$set'),
                aspectRatio: GwtBonusCardsSupply.cardAspectRatio,
                child: LayoutBuilder(
                  builder: (context, constraints) => ClipRRect(
                    borderRadius: BorderRadius.circular(
                      constraints.maxWidth * 0.045,
                    ),
                    child: Image.asset(
                      GwtBonusCardsSupply.cardAsset(set),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      semanticLabel: l10n.t('gwt.bonusCards.set', {
                        'n': '$set',
                      }),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: gap),
            _line(
              l10n.t('gwt.bonusCards.set', {'n': '$set'}),
              (compact ? textTheme.labelLarge : textTheme.titleMedium)
                  ?.copyWith(color: _wine, fontWeight: FontWeight.w800),
            ),
            _line(
              l10n.t('gwt.bonusCards.cards', {'n': '$cards'}),
              (compact ? textTheme.labelSmall : textTheme.labelLarge)?.copyWith(
                color: _ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
