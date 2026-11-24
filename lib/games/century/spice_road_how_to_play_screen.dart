import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// The Spice Road rulebook's Taking a Turn section: Play, Acquire, Rest and
/// Claim.
class SpiceRoadHowToPlayScreen extends StatelessWidget {
  const SpiceRoadHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('century.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      children: [
        CenturyPanel(
          key: const ValueKey('sr-play-turn'),
          title: l10n.t('centuryEtw.play.turnTitle'),
          body: t('turnBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in const ['play', 'acquire', 'rest', 'claim'])
                  CenturyActionChip(text: t('$action.title')),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('sr-play-play'),
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
          key: const ValueKey('sr-play-acquire'),
          title: t('acquire.title'),
          body: t('acquire.body'),
          children: [
            CenturyNote(text: t('acquire.free')),
            const SizedBox(height: 8),
            CenturyNote(text: t('acquire.cubes')),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('sr-play-rest'),
          title: t('rest.title'),
          body: t('rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('sr-play-claim'),
          title: t('claim.title'),
          body: t('claim.body'),
          children: [
            CenturyNote(
              icon: Icons.paid_outlined,
              text: t('claim.coins', {
                'gold': '${CenturyRules.goldPoints}',
                'silver': '${CenturyRules.silverPoints}',
              }),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('sr-play-limit'),
          title: t('limit.title'),
          body: t('limit.body', {'n': '${CenturyRules.caravanLimit}'}),
          children: const [],
        ),
      ],
    );
  }
}
