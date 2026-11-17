import 'package:flutter/material.dart';

import '../../domain/board_game.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/loading_image.dart';

const _icons = 'assets/games/great_western_trail_el_paso/icons';

/// Setup steps 5 and 12 from pages 4 and 5 of the El Paso rulebook.
class GwtElPasoSetup {
  const GwtElPasoSetup._();

  static const objectiveAsset = '$_icons/objectives.png';
  static const bonusAsset = '$_icons/bonus-tiles.png';

  /// Objective and bonus tiles; each pile starts with 20.
  static const tilesPerPile = 20;

  /// Tiles revealed face up next to each pile.
  static const faceUpPerPile = 3;

  /// The 10 player cattle cards in every herd deck.
  static const cardAspect = 400 / 620;
  static const herd = [
    (key: 'criollo', asset: '$_icons/cattle-criollo.png', count: 4),
    (key: 'pineywoods', asset: '$_icons/cattle-pineywoods.png', count: 2),
    (key: 'galloway', asset: '$_icons/cattle-galloway.png', count: 2),
    (
      key: 'santaGertrudis',
      asset: '$_icons/cattle-santa-gertrudis.png',
      count: 2,
    ),
  ];

  static int get herdSize => herd.fold(0, (sum, c) => sum + c.count);

  /// Cards each player draws from their herd deck.
  static const startingHand = 4;
}

const _ink = Color(0xFF2A2620);
const _muted = Color(0xFF6E6656);
const _wine = Color(0xFF6B2030);

class GwtElPasoSetupHintsScreen extends StatelessWidget {
  const GwtElPasoSetupHintsScreen({super.key, required this.game});

  final BoardGame game;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final gap = SizedBox(height: compact ? 16 : 20);

    return AppPage(
      title: l10n.t('hub.setupHints'),
      coverImageAsset: game.coverImageAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  key: const ValueKey('gwt-el-paso-train-supply'),
                  accent: game.accentColor,
                  compact: compact,
                  title: l10n.t('gwt.elPaso.setup.trainTitle'),
                  body: l10n.t('gwt.elPaso.setup.trainBody', {
                    'n': '${GwtElPasoSetup.faceUpPerPile}',
                  }),
                  child: Column(
                    children: [
                      _TilePileRow(
                        key: const ValueKey('gwt-el-paso-objectives'),
                        asset: GwtElPasoSetup.objectiveAsset,
                        label: l10n.t('gwt.elPaso.setup.objectives'),
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      _TilePileRow(
                        key: const ValueKey('gwt-el-paso-bonus'),
                        asset: GwtElPasoSetup.bonusAsset,
                        label: l10n.t('gwt.elPaso.setup.bonusTiles'),
                        compact: compact,
                      ),
                    ],
                  ),
                ),
                gap,
                _Panel(
                  key: const ValueKey('gwt-el-paso-herd'),
                  accent: game.accentColor,
                  compact: compact,
                  title: l10n.t('gwt.elPaso.setup.herdTitle', {
                    'n': '${GwtElPasoSetup.herdSize}',
                  }),
                  body: l10n.t('gwt.elPaso.setup.herdBody', {
                    'n': '${GwtElPasoSetup.startingHand}',
                  }),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final breed in GwtElPasoSetup.herd)
                        Expanded(
                          child: Column(
                            key: ValueKey('gwt-el-paso-herd-${breed.key}'),
                            children: [
                              _CattleCard(
                                asset: breed.asset,
                                label: l10n.t(
                                  'gwt.elPaso.setup.breed.${breed.key}',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '× ${breed.count}',
                                style: TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 18 : 22,
                                ),
                              ),
                              Text(
                                l10n.t('gwt.elPaso.setup.breed.${breed.key}'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _muted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 11 : 13,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
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
}

/// A face-down pile of 20 tiles, then the 3 tiles revealed beside it.
class _TilePileRow extends StatelessWidget {
  const _TilePileRow({
    super.key,
    required this.asset,
    required this.label,
    required this.compact,
  });

  final String asset;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pileTile = compact ? 26.0 : 32.0;
    final faceUpTile = compact ? 36.0 : 44.0;
    Widget tileImage(double size) => loadingImage(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The face-down pile, kept small: the revealed tiles matter.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: pileTile + 6,
                    height: pileTile + 6,
                    child: Stack(
                      children: [
                        for (final offset in [6.0, 3.0])
                          Positioned(
                            left: offset,
                            top: offset,
                            child: Opacity(
                              opacity: 0.5,
                              child: tileImage(pileTile),
                            ),
                          ),
                        tileImage(pileTile),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '× ${GwtElPasoSetup.tilesPerPile}',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 12 : 13,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _wine,
                  size: compact ? 22 : 26,
                ),
              ),
              // The revealed tiles, highlighted.
              Container(
                key: const ValueKey('gwt-el-paso-face-up'),
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 14,
                  compact ? 8 : 10,
                  compact ? 10 : 14,
                  compact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: _wine.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _wine, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < GwtElPasoSetup.faceUpPerPile; i++)
                          Padding(
                            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                            child: tileImage(faceUpTile),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('gwt.elPaso.setup.faceUp', {
                        'n': '${GwtElPasoSetup.faceUpPerPile}',
                      }),
                      style: TextStyle(
                        color: _wine,
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 15 : 17,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A player cattle card's art, as wide as its column allows.
class _CattleCard extends StatelessWidget {
  const _CattleCard({required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AspectRatio(
        aspectRatio: GwtElPasoSetup.cardAspect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: loadingImage(
            asset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            semanticLabel: label,
          ),
        ),
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
    required this.body,
    required this.child,
  });

  final Color accent;
  final bool compact;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _wine,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                height: 1.15,
              ),
            ),
            SizedBox(height: compact ? 10 : 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.35),
            ),
            SizedBox(height: compact ? 16 : 20),
            child,
          ],
        ),
      ),
    );
  }
}
