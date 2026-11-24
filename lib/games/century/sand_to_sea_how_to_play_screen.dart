import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_sand_to_sea_rules.dart';
import 'century_widgets.dart';

/// The From Sand to Sea rulebook's Taking a Turn section, one panel per
/// action, after a summary of what differs from Eastern Wonders.
class SandToSeaHowToPlayScreen extends StatelessWidget {
  const SandToSeaHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryFs.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.sandToSea,
      children: [
        CenturyPanel(
          key: const ValueKey('fs-play-different'),
          title: t('differentTitle'),
          children: [
            CenturyPoint(
              icon: Icons.style_outlined,
              text: t('different.cards'),
            ),
            CenturyPoint(
              icon: Icons.directions_boat_outlined,
              text: t('different.firstMove'),
            ),
            CenturyPoint(
              icon: Icons.payments_outlined,
              text: t('different.visit', {'n': '${SandToSeaRules.visitCost}'}),
            ),
            CenturyPoint(
              icon: Icons.waves_rounded,
              text: t('different.map', {
                'n': '${SandToSeaRules.marketTilesRemovedPerSymbol}',
                'sea': '${SandToSeaRules.seaTiles}',
              }),
            ),
            CenturyPoint(
              icon: Icons.house_outlined,
              text: t('different.outposts', {
                'n': '${SandToSeaRules.outpostsPerPlayer}',
              }),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-turn'),
          title: t('turnTitle'),
          body: t('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in const ['acquire', 'play', 'move', 'rest'])
                  CenturyActionChip(text: t('$action.title')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-acquire'),
          title: t('acquire.title'),
          body: t('acquire.body'),
          children: [CenturyNote(text: t('acquire.note'))],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-play'),
          title: t('play.title'),
          body: t('play.body'),
          children: [
            CenturyPoint(
              icon: Icons.add_box_outlined,
              title: t('play.spiceTitle'),
              text: t('play.spice'),
            ),
            CenturyPoint(
              icon: Icons.upgrade_rounded,
              title: t('play.upgradeTitle'),
              text: t('play.upgrade'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: t('play.tradeTitle'),
              text: t('play.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-move'),
          title: t('move.title'),
          body: t('move.body'),
          children: [
            CenturyNote(
              icon: Icons.warning_amber_rounded,
              text: t('move.firstMove'),
            ),
            const SizedBox(height: 8),
            CenturyNote(
              icon: Icons.payments_outlined,
              text: t('move.visit', {'n': '${SandToSeaRules.visitCost}'}),
            ),
            const SizedBox(height: 8),
            CenturyNote(
              icon: Icons.arrow_forward_rounded,
              text: t('move.then'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-market'),
          title: t('market.title'),
          body: t('market.body'),
          children: [
            CenturyPoint(
              icon: Icons.house_outlined,
              title: t('market.buildTitle'),
              text: t('market.build', {
                'n': '${SandToSeaRules.outpostCostPerOutpost(3)}',
                'two': '${SandToSeaRules.outpostCostPerOutpost(2)}',
              }),
            ),
            CenturyPoint(
              icon: Icons.view_column_outlined,
              title: t('market.columnsTitle'),
              text: t('market.columns'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: t('market.tradeTitle'),
              text: t('market.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-port'),
          title: t('port.title'),
          body: t('port.body'),
          children: [CenturyNote(text: t('port.closed'))],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-rest'),
          title: t('rest.title'),
          body: t('rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('fs-play-cargo'),
          title: t('cargo.title'),
          body: t('cargo.body', {'n': '${SandToSeaRules.cargoLimit}'}),
          children: const [],
        ),
      ],
    );
  }
}
