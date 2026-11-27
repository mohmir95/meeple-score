import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_east_to_west_all_rules.dart';
import 'century_widgets.dart';
import 'new_world_how_to_play_screen.dart';

/// The From East to West (Spice Road + Eastern Wonders + A New World) rulebook's Taking a Turn
/// section. Rules shared with the two-game versions reuse their text.
class EastToWestAllHowToPlayScreen extends StatelessWidget {
  const EastToWestAllHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEtwAll.play.$key', args);
    // The Spice Road + A New World and Eastern Wonders + A New World texts.
    String sr(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEtw.play.$key', args);
    String ew(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEtwEw.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.eastToWestAll,
      children: [
        CenturyPanel(
          key: const ValueKey('etwall-play-turn'),
          title: sr('turnTitle'),
          body: ew('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                CenturyActionChip(text: sr('work.title')),
                CenturyActionChip(text: sr('rest.title')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-play-work'),
          title: sr('work.title'),
          body: sr('work.body'),
          children: [
            CenturyCollapsible(
              key: const ValueKey('nw-locations-collapsible'),
              title: t('work.note'),
              children: const [NewWorldLocationList(fortBonus: false)],
            ),
            const SizedBox(height: 8),
            CenturyPoint(
              key: const ValueKey('etwall-play-market'),
              icon: Icons.storefront_outlined,
              title: '${sr('market.title')}:',
              text: t('market.body'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 28),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  CenturyNote(text: sr('market.refill')),
                  const SizedBox(height: 8),
                  CenturyNote(
                    icon: Icons.workspace_premium_outlined,
                    text: t('market.bonus', {
                      'spaces': '${EastToWestAllRules.bonusSpaces}',
                    }),
                  ),
                  CenturySubheading(
                    key: const ValueKey('etwall-play-cards'),
                    text: sr('route.actions'),
                  ),
                  CenturyPoint(
                    icon: Icons.add_box_outlined,
                    title: sr('cards.spiceTitle'),
                    text: sr('cards.spice'),
                  ),
                  CenturyPoint(
                    icon: Icons.upgrade_rounded,
                    title: sr('cards.upgradeTitle'),
                    text: sr('cards.upgrade'),
                  ),
                  CenturyPoint(
                    icon: Icons.swap_vert_rounded,
                    title: sr('cards.tradeTitle'),
                    text: sr('cards.trade'),
                  ),
                ],
              ),
            ),
            CenturyPoint(
              key: const ValueKey('etwall-play-refresh'),
              icon: Icons.refresh_rounded,
              title: '${sr('refresh.title')}:',
              text: sr('refresh.body', {
                'n': '${EastToWestAllRules.marketLocations}',
              }),
            ),
            const SizedBox(height: 8),
            CenturyCollapsible(
              key: const ValueKey('ew-locations-collapsible'),
              title: t('work.ewNote'),
              children: [
                CenturyPoint(
                  key: const ValueKey('etwall-play-move'),
                  icon: Icons.sailing_outlined,
                  title: '${ew('move.title')}:',
                  text: ew('move.body'),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 28),
                  child: Column(
                    children: [
                      CenturyPoint(
                        icon: Icons.looks_one_outlined,
                        text: ew('move.one'),
                      ),
                      CenturyPoint(
                        icon: Icons.looks_two_outlined,
                        text: ew('move.two'),
                      ),
                      CenturyPoint(
                        icon: Icons.disabled_by_default_outlined,
                        text: ew('move.any'),
                      ),
                    ],
                  ),
                ),
                CenturyPoint(
                  key: const ValueKey('etwall-play-boat-trade'),
                  icon: Icons.directions_boat_outlined,
                  title: '${ew('boatTrade.title')}:',
                  text: ew('boatTrade.body'),
                ),
                CenturyPoint(
                  key: const ValueKey('etwall-play-outpost-trade'),
                  icon: Icons.house_outlined,
                  title: '${ew('outpostTrade.title')}:',
                  text: ew('outpostTrade.body'),
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-play-after'),
          title: ew('after.title'),
          body: ew('after.body'),
          children: [
            CenturyPoint(
              icon: Icons.payments_outlined,
              title: ew('after.payTitle'),
              text: ew('after.pay', {'n': '${EastToWestAllRules.visitCost}'}),
            ),
            CenturyPoint(
              icon: Icons.house_outlined,
              title: ew('after.buildTitle'),
              text: ew('after.build', {
                'n': '${EastToWestAllRules.outpostCostPerOutpost(3)}',
                'two': '${EastToWestAllRules.outpostCostPerOutpost(2)}',
              }),
            ),
            CenturyPoint(
              icon: Icons.view_column_outlined,
              title: ew('after.columnTitle'),
              text: ew('after.column'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: ew('after.tradeTitle'),
              text: ew('after.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-play-rest'),
          title: sr('rest.title'),
          body: ew('rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-play-storage'),
          title: sr('storage.title'),
          body: sr('storage.body', {'n': '${EastToWestAllRules.storageLimit}'}),
          children: const [],
        ),
      ],
    );
  }
}
