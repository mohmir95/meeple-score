import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../century/century_widgets.dart';
import 'takenoko_game.dart';
import 'takenoko_rules.dart';

/// The rulebook's End of the Game rules and objective scoring, gathered as
/// scoring hints.
class TakenokoScoringHintsScreen extends StatelessWidget {
  const TakenokoScoringHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final card = compact ? 24.0 : 28.0;

    Widget objectiveCard(Color color) =>
        CenturyCard(color: color, width: card, faceUp: true);

    return CenturyPage(
      titleKey: 'hub.scoringHints',
      style: TakenokoGame.style,
      children: [
        CenturyPanel(
          key: const ValueKey('takenoko-score-end'),
          title: l10n.t('takenoko.score.endTitle'),
          body: l10n.t('takenoko.score.endBody'),
          children: [
            for (final players in TakenokoRules.playerCounts)
              CenturyRow(
                key: ValueKey('takenoko-score-end-$players'),
                lead: const Icon(
                  Icons.groups_rounded,
                  color: TakenokoGame.bamboo,
                ),
                label: l10n.t('takenoko.score.endPlayers', {'n': '$players'}),
                value: l10n.t('takenoko.score.endObjective', {
                  'n': '${TakenokoRules.objectivesToEnd(players)}',
                }),
              ),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(text: l10n.t('takenoko.score.lastTurn')),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-score-final'),
          title: l10n.t('takenoko.score.finalTitle'),
          body: l10n.t('takenoko.score.finalBody'),
          children: [
            for (final objective in TakenokoObjective.values)
              CenturyRow(
                key: ValueKey('takenoko-score-${objective.name}'),
                lead: objectiveCard(objective.color),
                label: l10n.t('takenoko.score.${objective.name}'),
                hint: l10n.t('takenoko.score.${objective.name}Hint'),
                value: l10n.t('takenoko.score.printed'),
              ),
            CenturyRow(
              key: const ValueKey('takenoko-score-emperor'),
              lead: objectiveCard(TakenokoRules.emperorColor),
              label: l10n.t('takenoko.score.emperor'),
              hint: l10n.t('takenoko.score.emperorHint'),
              value: '${TakenokoRules.emperorPoints}',
            ),
            CenturyRow(
              key: const ValueKey('takenoko-score-hand'),
              lead: Opacity(
                opacity: 0.45,
                child: CenturyCard(
                  color: TakenokoObjective.plot.color,
                  width: card,
                  deck: true,
                ),
              ),
              label: l10n.t('takenoko.score.hand'),
              value: '0',
            ),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(
              key: const ValueKey('takenoko-score-tie'),
              icon: Icons.emoji_events_outlined,
              text: l10n.t('takenoko.score.tie'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-score-complete'),
          title: l10n.t('takenoko.score.completeTitle'),
          children: [
            for (final tip in const [
              'free',
              'kept',
              'plotRule',
              'gardenerRule',
              'pandaRule',
              'hand',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CenturyNote(
                  key: ValueKey('takenoko-score-tip-$tip'),
                  icon: Icons.check_circle_outline_rounded,
                  text: l10n.t('takenoko.score.tip.$tip', {
                    'n': '${TakenokoRules.handLimit}',
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
