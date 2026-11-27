import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_east_to_west_ew_rules.dart';
import 'century_widgets.dart';
import 'new_world_how_to_play_screen.dart';

/// The From East to West (Eastern Wonders + A New World) rulebook's Taking a Turn section:
/// Work (with the new boat and trade locations) and Rest.
class EastToWestEwHowToPlayScreen extends StatelessWidget {
  const EastToWestEwHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEtwEw.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.eastToWestEw,
      children: [
        CenturyPanel(
          key: const ValueKey('etwew-play-different'),
          title: t('differentTitle'),
          children: [
            CenturyPoint(
              icon: Icons.sailing_outlined,
              text: t('different.map'),
            ),
            CenturyPoint(
              icon: Icons.house_outlined,
              text: t('different.outposts', {
                'n': '${EastToWestEwRules.outpostsPerPlayer}',
              }),
            ),
            CenturyPoint(
              icon: Icons.workspace_premium_outlined,
              text: t('different.bonus', {
                'n': '${EastToWestEwRules.bonusSpaces}',
              }),
            ),
            CenturyPoint(
              icon: Icons.storefront_outlined,
              text: t('different.locations'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-play-turn'),
          title: l10n.t('centuryEtw.play.turnTitle'),
          body: t('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                CenturyActionChip(text: l10n.t('centuryEtw.play.work.title')),
                CenturyActionChip(text: l10n.t('centuryEtw.play.rest.title')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-play-work'),
          title: l10n.t('centuryEtw.play.work.title'),
          body: l10n.t('centuryEtw.play.work.body'),
          children: [
            CenturyCollapsible(
              key: const ValueKey('nw-locations-collapsible'),
              title: t('work.note'),
              children: [
                const NewWorldLocationList(fortBonus: false),
                const SizedBox(height: 4),
                CenturyNote(
                  icon: Icons.warning_amber_rounded,
                  text: t('outpostTrade.forts'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CenturyPoint(
              key: const ValueKey('etwew-play-move'),
              icon: Icons.sailing_outlined,
              title: '${t('move.title')}:',
              text: t('move.body'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 28),
              child: Column(
                children: [
                  CenturyPoint(
                    icon: Icons.looks_one_outlined,
                    text: t('move.one'),
                  ),
                  CenturyPoint(
                    icon: Icons.looks_two_outlined,
                    text: t('move.two'),
                  ),
                  CenturyPoint(icon: Icons.public_rounded, text: t('move.any')),
                ],
              ),
            ),
            CenturyPoint(
              key: const ValueKey('etwew-play-boat-trade'),
              icon: Icons.directions_boat_outlined,
              title: '${t('boatTrade.title')}:',
              text: t('boatTrade.body'),
            ),
            CenturyPoint(
              key: const ValueKey('etwew-play-outpost-trade'),
              icon: Icons.house_outlined,
              title: '${t('outpostTrade.title')}:',
              text: t('outpostTrade.body'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-play-after'),
          title: t('after.title'),
          body: t('after.body'),
          children: [
            CenturyPoint(
              icon: Icons.payments_outlined,
              title: t('after.payTitle'),
              text: t('after.pay', {'n': '${EastToWestEwRules.visitCost}'}),
            ),
            CenturyPoint(
              icon: Icons.house_outlined,
              title: t('after.buildTitle'),
              text: t('after.build', {
                'n': '${EastToWestEwRules.outpostCostPerOutpost(3)}',
                'two': '${EastToWestEwRules.outpostCostPerOutpost(2)}',
              }),
            ),
            CenturyPoint(
              icon: Icons.view_column_outlined,
              title: t('after.columnTitle'),
              text: t('after.column'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: t('after.tradeTitle'),
              text: t('after.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-play-rest'),
          title: l10n.t('centuryEtw.play.rest.title'),
          body: t('rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-play-storage'),
          title: l10n.t('centuryEtw.play.storage.title'),
          body: l10n.t('centuryEtw.play.storage.body', {
            'n': '${EastToWestEwRules.storageLimit}',
          }),
          children: const [],
        ),
      ],
    );
  }
}
