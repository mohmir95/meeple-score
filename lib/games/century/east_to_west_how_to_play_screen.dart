import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_east_to_west_rules.dart';
import 'century_widgets.dart';
import 'new_world_how_to_play_screen.dart';

/// The From East to West rulebook's Taking a Turn section: Work (with the
/// new locations), Route and Rest, plus the rule changes.
class EastToWestHowToPlayScreen extends StatelessWidget {
  const EastToWestHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryEtw.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.eastToWest,
      children: [
        CenturyPanel(
          key: const ValueKey('etw-play-different'),
          title: t('differentTitle'),
          children: [
            CenturyPoint(
              icon: Icons.style_outlined,
              text: t('different.cards'),
            ),
            CenturyPoint(
              icon: Icons.route_outlined,
              text: t('different.route', {
                'n': '${EastToWestRules.tradeRouteLimit}',
              }),
            ),
            CenturyPoint(
              icon: Icons.storefront_outlined,
              text: t('different.locations'),
            ),
            CenturyPoint(
              icon: Icons.explore_outlined,
              text: t('different.exploration'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-play-turn'),
          title: t('turnTitle'),
          body: t('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in const ['work', 'route', 'rest'])
                  CenturyActionChip(text: t('$action.title')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-play-work'),
          title: t('work.title'),
          body: t('work.body'),
          children: [
            CenturyCollapsible(
              key: const ValueKey('nw-locations-collapsible'),
              title: t('work.note'),
              children: [NewWorldLocationList()],
            ),
            const SizedBox(height: 8),
            CenturyPoint(
              key: const ValueKey('etw-play-market'),
              icon: Icons.storefront_outlined,
              title: '${t('market.title')}:',
              text: t('market.body'),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 28),
              child: Column(
                children: [
                  CenturyPoint(
                    icon: Icons.bolt_outlined,
                    title: t('market.useTitle'),
                    text: t('market.use'),
                  ),
                  CenturyPoint(
                    icon: Icons.add_card_outlined,
                    title: t('market.takeTitle'),
                    text: t('market.take', {
                      'n': '${EastToWestRules.tradeRouteLimit}',
                    }),
                  ),
                  const SizedBox(height: 4),
                  CenturyNote(text: t('market.refill')),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            CenturyPoint(
              key: const ValueKey('etw-play-refresh'),
              icon: Icons.refresh_rounded,
              title: '${t('refresh.title')}:',
              text: t('refresh.body', {
                'n': '${EastToWestRules.marketLocations}',
              }),
            ),
            CenturyPoint(
              key: const ValueKey('etw-play-adjust'),
              icon: Icons.swap_horiz_rounded,
              title: '${t('adjust.title')}:',
              text: t('adjust.body'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-play-route'),
          title: t('route.title'),
          body: t('route.body'),
          children: [
            CenturyNote(icon: Icons.groups_outlined, text: t('route.example')),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                t('route.actions'),
                key: const ValueKey('etw-play-route-actions'),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: centuryInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            CenturyPoint(
              icon: Icons.add_box_outlined,
              title: t('cards.spiceTitle'),
              text: t('cards.spice'),
            ),
            CenturyPoint(
              icon: Icons.upgrade_rounded,
              title: t('cards.upgradeTitle'),
              text: t('cards.upgrade'),
            ),
            CenturyPoint(
              icon: Icons.swap_vert_rounded,
              title: t('cards.tradeTitle'),
              text: t('cards.trade'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-play-rest'),
          title: t('rest.title'),
          body: t('rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etw-play-storage'),
          title: t('storage.title'),
          body: t('storage.body', {'n': '${EastToWestRules.storageLimit}'}),
          children: const [],
        ),
      ],
    );
  }
}
