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

  void _draw() {
    setState(() {
      _supply = GwtBonusCardsSupply.random(_random);
      _drawId++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final perSet = GwtBonusCardsSupply.cardsPerSet(_players);

    return AppPage(
      title: l10n.t('hub.bonusCardsRandomizer'),
      coverImageAsset: widget.game.coverImageAsset,
      body: SingleChildScrollView(
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    SegmentedButton<int>(
                      key: const ValueKey('gwt-bonus-players'),
                      segments: [
                        for (final count in _playerCounts)
                          ButtonSegment(
                            value: count,
                            label: Text(
                              l10n.t('gwt.bonusCards.players', {'n': '$count'}),
                            ),
                          ),
                      ],
                      selected: {_players},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _players = selection.single),
                    ),
                    FilledButton.icon(
                      key: const ValueKey('gwt-bonus-randomize'),
                      onPressed: _draw,
                      icon: const Icon(Icons.shuffle),
                      label: Text(l10n.t('gwt.randomizer.randomize')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Phones keep all 4 stacks in one row, scaled down, so
                    // the whole supply fits on screen like on the table.
                    final compact = constraints.maxWidth < 560;
                    final columns = constraints.maxWidth < 300 ? 2 : 4;
                    final gap = compact ? 6.0 : 12.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final tile in GwtBonusTile.values)
                          SizedBox(
                            width: width,
                            child: _BonusStack(
                              key: ValueKey('gwt-bonus-${tile.key}'),
                              tile: tile,
                              set: _supply.setFor(tile),
                              cards: perSet,
                              drawId: _drawId,
                              accent: widget.game.accentColor,
                              compact: compact,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.t('gwt.bonusCards.returnNote', {
                    'extra': '${perSet - 1}',
                    'total': '$perSet',
                  }),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              excludeFromSemantics: true,
            ),
            SizedBox(height: compact ? 3 : 6),
            _line(
              l10n.t('gwt.bonusCards.${tile.key}'),
              (compact ? textTheme.labelMedium : textTheme.titleSmall)
                  ?.copyWith(color: _ink, fontWeight: FontWeight.w800),
            ),
            _line(
              compact
                  ? l10n.t('gwt.bonusCards.goldShort', {'n': '${tile.gold}'})
                  : l10n.t('gwt.bonusCards.gold', {'n': '${tile.gold}'}),
              (compact ? textTheme.labelSmall : textTheme.labelMedium)
                  ?.copyWith(
                    color: const Color(0xFF8A6A1E),
                    fontWeight: FontWeight.w700,
                  ),
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
