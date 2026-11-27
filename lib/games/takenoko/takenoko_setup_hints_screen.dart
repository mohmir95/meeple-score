import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../century/century_widgets.dart';
import 'takenoko_game.dart';
import 'takenoko_rules.dart';

const _pond = Color(0xFF3E8FB0);
const _irrigation = Color(0xFF2F7FD0);

/// Plot colours, as printed.
const _plotColors = [Color(0xFF6BA34A), Color(0xFFE2B93B), Color(0xFFE58BA6)];

/// The rulebook's Preparation steps. Setup is the same for every player
/// count and in both editions.
class TakenokoSetupHintsScreen extends StatelessWidget {
  const TakenokoSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final hex = compact ? 26.0 : 30.0;
    final card = compact ? 22.0 : 26.0;
    final wide = compact ? 64.0 : 76.0;

    String times(int n) => '× $n';

    Widget icon(IconData data) =>
        Icon(data, color: TakenokoGame.bamboo, size: compact ? 26 : 30);

    Widget objectiveCards() => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, objective) in TakenokoObjective.values.indexed) ...[
            if (i > 0) const SizedBox(width: 3),
            CenturyCard(color: objective.color, width: card * 0.8),
          ],
        ],
      ),
    );

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: TakenokoGame.style,
      children: [
        CenturyPanel(
          key: const ValueKey('takenoko-setup-garden'),
          title: l10n.t('takenoko.setup.gardenTitle'),
          body: l10n.t('takenoko.setup.gardenBody'),
          children: [
            CenturyRow(
              key: const ValueKey('takenoko-setup-pond'),
              lead: HexTile(color: _pond, size: hex),
              label: l10n.t('takenoko.setup.pond'),
              hint: l10n.t('takenoko.setup.pondHint'),
              value: times(1),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-gardener'),
              lead: icon(Icons.agriculture_rounded),
              label: l10n.t('takenoko.setup.gardener'),
              value: times(1),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-panda'),
              lead: icon(Icons.pets_rounded),
              label: l10n.t('takenoko.setup.panda'),
              value: times(1),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-setup-reserve'),
          title: l10n.t('takenoko.setup.reserveTitle'),
          body: l10n.t('takenoko.setup.reserveBody'),
          children: [
            CenturyRow(
              key: const ValueKey('takenoko-setup-plots'),
              lead: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final color in _plotColors)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: HexTile(color: color, size: hex * 0.62),
                      ),
                  ],
                ),
              ),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.plots'),
              hint: l10n.t('takenoko.setup.plotsHint'),
              value: times(TakenokoRules.plots),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-irrigation'),
              lead: Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: hex * 1.1,
                  height: hex * 0.18,
                  decoration: BoxDecoration(
                    color: _irrigation,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.irrigation'),
              value: times(TakenokoRules.irrigationChannels),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-improvements'),
              lead: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final data in const [
                      Icons.fence_rounded,
                      Icons.spa_rounded,
                      Icons.water_drop_rounded,
                    ])
                      Icon(
                        data,
                        size: compact ? 18 : 20,
                        color: TakenokoGame.bamboo,
                      ),
                  ],
                ),
              ),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.improvements'),
              hint: l10n.t('takenoko.setup.improvementsHint'),
              value: times(TakenokoRules.improvements),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-setup-objectives'),
          title: l10n.t('takenoko.setup.objectivesTitle'),
          body: l10n.t('takenoko.setup.objectivesBody'),
          children: [
            for (final objective in TakenokoObjective.values)
              CenturyRow(
                key: ValueKey('takenoko-setup-deck-${objective.name}'),
                lead: CenturyCard(
                  color: objective.color,
                  width: card,
                  deck: true,
                ),
                label: l10n.t('takenoko.score.${objective.name}'),
                value: l10n.t('takenoko.setup.faceDown'),
              ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-emperor'),
              lead: CenturyCard(
                color: TakenokoRules.emperorColor,
                width: card,
                faceUp: true,
              ),
              label: l10n.t('takenoko.score.emperor'),
              hint: l10n.t('takenoko.setup.emperorHint'),
              value: l10n.t('takenoko.setup.setAside'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-setup-player'),
          title: l10n.t('takenoko.setup.playerTitle'),
          body: l10n.t('takenoko.setup.playerBody'),
          children: [
            CenturyRow(
              key: const ValueKey('takenoko-setup-board'),
              lead: icon(Icons.dashboard_outlined),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.board'),
              value: times(1),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-tokens'),
              lead: icon(Icons.radio_button_checked_rounded),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.tokens'),
              value: times(TakenokoRules.actionTokensPerPlayer),
            ),
            CenturyRow(
              key: const ValueKey('takenoko-setup-hand'),
              lead: objectiveCards(),
              leadWidth: wide,
              label: l10n.t('takenoko.setup.hand'),
              hint: l10n.t('takenoko.setup.handHint'),
              value: times(TakenokoObjective.values.length),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('takenoko-setup-first'),
          title: l10n.t('takenoko.setup.firstTitle'),
          body: l10n.t('takenoko.setup.firstBody'),
          children: [
            CenturyNote(
              key: const ValueKey('takenoko-setup-weather'),
              icon: Icons.wb_sunny_outlined,
              text: l10n.t('takenoko.setup.weather'),
            ),
            SizedBox(height: compact ? 8 : 10),
            CenturyNote(
              key: const ValueKey('takenoko-setup-tip'),
              icon: Icons.tips_and_updates_outlined,
              text: l10n.t('takenoko.setup.tip'),
            ),
          ],
        ),
      ],
    );
  }
}
