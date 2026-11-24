import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_widgets.dart';

/// The Eastern Wonders rulebook's Taking a Turn section: move, then a
/// Market, Port or Harvest action.
class EasternWondersHowToPlayScreen extends StatelessWidget {
  const EasternWondersHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEw.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.easternWonders,
      children: [
        CenturyPanel(
          key: const ValueKey('ew-play-turn'),
          title: l10n.t('centuryEtw.play.turnTitle'),
          body: t('turnBody'),
          children: [
            CenturyTurnFlow(
              optionalStep: t('move.title'),
              actions: [
                for (final action in const ['market', 'port', 'harvest'])
                  t('$action.title'),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-move'),
          title: t('move.title'),
          optional: true,
          children: [
            CenturyPoint(icon: Icons.looks_one_outlined, text: t('move.free')),
            CenturyPoint(icon: Icons.add_rounded, text: t('move.more')),
            CenturyPoint(icon: Icons.payments_outlined, text: t('move.visit')),
            CenturyPoint(
              icon: Icons.inventory_2_outlined,
              text: t('move.pickUp'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-market'),
          title: t('market.title'),
          body: t('market.body'),
          children: [
            CenturyPoint(
              icon: Icons.house_outlined,
              title: t('market.buildTitle'),
              text: t('market.build'),
            ),
            CenturyPoint(
              icon: Icons.view_column_outlined,
              title: t('market.columnTitle'),
              text: t('market.column'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: t('market.tradeTitle'),
              text: t('market.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-port'),
          title: t('port.title'),
          body: l10n.t('centuryFs.play.port.body'),
          children: [CenturyNote(text: l10n.t('centuryFs.play.port.closed'))],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-harvest'),
          title: t('harvest.title'),
          body: t('harvest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-bonus'),
          title: l10n.t('centuryEw.setup.bonusTitle'),
          children: [
            CenturyPoint(icon: Icons.sailing_outlined, text: t('bonus.move')),
            CenturyPoint(
              icon: Icons.upgrade_rounded,
              text: t('bonus.upgrade', {
                'n': '${EasternWondersRules.upgradeBonusVp}',
              }),
            ),
            CenturyPoint(
              icon: Icons.agriculture_outlined,
              text: t('bonus.harvest', {
                'n': '${EasternWondersRules.harvestBonusVp}',
              }),
            ),
            CenturyPoint(
              icon: Icons.inventory_2_outlined,
              text: t('bonus.cargo'),
            ),
            CenturyPoint(
              icon: Icons.emoji_events_outlined,
              text: t('bonus.vp', {
                'list': EasternWondersRules.bonusVp.join('/'),
              }),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-play-cargo'),
          title: l10n.t('centuryFs.play.cargo.title'),
          body: l10n.t('centuryFs.play.cargo.body', {
            'n': '${EasternWondersRules.cargoLimit}',
          }),
          children: const [],
        ),
      ],
    );
  }
}
