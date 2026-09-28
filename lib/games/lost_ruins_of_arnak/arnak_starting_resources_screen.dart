import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'arnak_game.dart';

class ArnakStartingResourcesScreen extends StatelessWidget {
  const ArnakStartingResourcesScreen({super.key});

  static const coinAsset = 'assets/games/lost_ruins_of_arnak/icons/coin.png';
  static const compassAsset =
      'assets/games/lost_ruins_of_arnak/icons/compass.png';
  static const fundingCardAsset =
      'assets/games/lost_ruins_of_arnak/icons/card_funding.png';
  static const explorationCardAsset =
      'assets/games/lost_ruins_of_arnak/icons/card_exploration.png';
  static const fearCardAsset =
      'assets/games/lost_ruins_of_arnak/icons/card_fear.png';

  static const _rows = <({int coins, int compasses})>[
    (coins: 2, compasses: 0),
    (coins: 1, compasses: 1),
    (coins: 2, compasses: 1),
    (coins: 1, compasses: 2),
  ];

  static const _deckGroups = <({String asset, String captionKey})>[
    (asset: fundingCardAsset, captionKey: 'arnak.startingDeck.funding'),
    (asset: explorationCardAsset, captionKey: 'arnak.startingDeck.exploration'),
    (asset: fearCardAsset, captionKey: 'arnak.startingDeck.fear'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final accent = const LostRuinsOfArnakGame().accentColor;
    final gap = compact ? 16.0 : 20.0;

    return AppPage(
      title: l10n.t('hub.startingResources'),
      coverImageAsset: LostRuinsOfArnakGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SetupPanel(
                  key: const ValueKey('arnak-starting-resources-panel'),
                  accent: accent,
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelTitle(
                        text: l10n.isRtl
                            ? l10n.t('hub.startingResources')
                            : l10n.t('hub.startingResources').toUpperCase(),
                        letterSpacing: l10n.isRtl ? 0 : 1.1,
                      ),
                      SizedBox(height: compact ? 18 : 24),
                      for (var i = 0; i < _rows.length; i++) ...[
                        if (i > 0) SizedBox(height: compact ? 12 : 16),
                        _PlayerResourceRow(
                          label: l10n.t('players.numbered', {
                            'n': '${i + 1}',
                          }),
                          coins: _rows[i].coins,
                          compasses: _rows[i].compasses,
                          compact: compact,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: gap),
                _SetupPanel(
                  key: const ValueKey('arnak-starting-deck-panel'),
                  accent: accent,
                  compact: compact,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PanelTitle(
                        text: l10n.t('arnak.startingDeck.title'),
                        color: const Color(0xFF6B2030),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      Text(
                        l10n.t('arnak.startingDeck.body'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2A2620),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      _DeckGroups(
                        groups: _deckGroups,
                        compact: compact,
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      Text(
                        l10n.t('arnak.startingDeck.leadersNote'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5A5248),
                          fontStyle: FontStyle.italic,
                          height: 1.35,
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

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({
    super.key,
    required this.accent,
    required this.compact,
    required this.child,
  });

  final Color accent;
  final bool compact;
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
        child: child,
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.text,
    this.color = const Color(0xFF1C1A17),
    this.letterSpacing = 0,
  });

  final String text;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        fontStyle: FontStyle.italic,
        letterSpacing: letterSpacing,
        height: 1.15,
      ),
    );
  }
}

class _PlayerResourceRow extends StatelessWidget {
  const _PlayerResourceRow({
    required this.label,
    required this.coins,
    required this.compasses,
    required this.compact,
  });

  final String label;
  final int coins;
  final int compasses;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconSize = compact ? 22.0 : 26.0;

    return Row(
      children: [
        SizedBox(
          width: compact ? 100 : 120,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1C1A17),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < coins; i++)
                _ResourceIcon(
                  asset: ArnakStartingResourcesScreen.coinAsset,
                  size: iconSize,
                  label: l10n.t('arnak.coin'),
                ),
              for (var i = 0; i < compasses; i++)
                _ResourceIcon(
                  asset: ArnakStartingResourcesScreen.compassAsset,
                  size: iconSize,
                  label: l10n.t('arnak.compass'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeckGroups extends StatelessWidget {
  const _DeckGroups({required this.groups, required this.compact});

  final List<({String asset, String captionKey})> groups;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final children = [
      for (final group in groups)
        _DeckGroup(
          asset: group.asset,
          caption: l10n.t(group.captionKey),
        ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _DeckGroup extends StatelessWidget {
  const _DeckGroup({
    required this.asset,
    required this.caption,
  });

  final String asset;
  final String caption;

  static const _cardAspect = 648 / 917;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 170,
          child: AspectRatio(
            aspectRatio: 1.45,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardHeight = constraints.maxHeight * 0.92;
                final cardWidth = cardHeight * _cardAspect;
                final spread = constraints.maxWidth - cardWidth;
                return Stack(
                  children: [
                    for (final (index, angle) in const [(0, -0.07), (1, 0.07)])
                      Positioned(
                        left: index * spread,
                        top: (constraints.maxHeight - cardHeight) / 2,
                        width: cardWidth,
                        height: cardHeight,
                        child: Transform.rotate(
                          angle: angle,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              asset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              semanticLabel: index == 0 ? caption : null,
                              excludeFromSemantics: index != 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF2A2620),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ResourceIcon extends StatelessWidget {
  const _ResourceIcon({
    required this.asset,
    required this.size,
    required this.label,
  });

  final String asset;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: label,
    );
  }
}
