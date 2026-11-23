import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// The rulebook's Game End rules, gathered as scoring hints.
class CenturyScoringHintsScreen extends StatelessWidget {
  const CenturyScoringHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final coin = compact ? 26.0 : 30.0;
    final card = compact ? 24.0 : 28.0;
    final cube = compact ? 18.0 : 22.0;

    return CenturyPage(
      titleKey: 'hub.scoringHints',
      children: [
        CenturyPanel(
          key: const ValueKey('century-score-end'),
          title: l10n.t('century.score.endTitle'),
          body: l10n.t('century.score.endBody'),
          children: [
            for (final players in const [(2, 3), (4, 5)])
              CenturyRow(
                key: ValueKey('century-score-end-${players.$1}'),
                lead: CenturyCard(
                  color: centuryPointBack,
                  width: card,
                  faceUp: true,
                ),
                label: l10n.t('century.score.endPlayers', {
                  'min': '${players.$1}',
                  'max': '${players.$2}',
                }),
                value: l10n.t('century.score.endCard', {
                  'n': '${CenturyRules.pointCardsToEnd(players.$1)}',
                }),
              ),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(
              icon: Icons.emoji_events_outlined,
              text: l10n.t('century.score.tie'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('century-score-final'),
          title: l10n.t('century.score.finalTitle'),
          body: l10n.t('century.score.finalBody'),
          children: [
            CenturyRow(
              key: const ValueKey('century-score-cards'),
              lead: CenturyCard(
                color: centuryPointBack,
                width: card,
                faceUp: true,
              ),
              label: l10n.t('century.score.cards'),
              hint: l10n.t('century.score.cardsHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('century-score-gold'),
              lead: CenturyCoin(gold: true, size: coin),
              label: l10n.t('century.score.gold'),
              value: '${CenturyRules.goldPoints}',
            ),
            CenturyRow(
              key: const ValueKey('century-score-silver'),
              lead: CenturyCoin(gold: false, size: coin),
              label: l10n.t('century.score.silver'),
              value: '${CenturyRules.silverPoints}',
            ),
            CenturyRow(
              key: const ValueKey('century-score-cubes'),
              lead: Directionality(
                textDirection: TextDirection.ltr,
                child: SpiceCubes(
                  counts: const {
                    CenturySpice.saffron: 1,
                    CenturySpice.cardamom: 1,
                    CenturySpice.cinnamon: 1,
                  },
                  size: cube * 0.8,
                ),
              ),
              leadWidth: compact ? 56 : 64,
              label: l10n.t('century.score.cubes'),
              hint: l10n.t('century.score.cubesHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('century-score-yellow'),
              lead: SpiceCube(spice: CenturySpice.turmeric, size: cube),
              leadWidth: compact ? 56 : 64,
              label: l10n.t('century.score.yellow'),
              value: '0',
            ),
          ],
        ),
      ],
    );
  }
}
