import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import 'century_new_world_rules.dart';
import 'century_widgets.dart';

/// The A New World rulebook's Taking a Turn section and the overview sheet's
/// locations and Point cards.
class NewWorldHowToPlayScreen extends StatelessWidget {
  const NewWorldHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryNw.play.$key', args);

    return CenturyPage(
      titleKey: 'hub.howToPlay',
      style: CenturyStyleData.newWorld,
      children: [
        CenturyPanel(
          key: const ValueKey('nw-play-turn'),
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
          key: const ValueKey('nw-play-work'),
          title: l10n.t('centuryEtw.play.work.title'),
          body: t('work.body'),
          children: [
            CenturyPoint(
              icon: Icons.person_outline_rounded,
              text: t('work.empty'),
            ),
            CenturyPoint(icon: Icons.groups_outlined, text: t('work.oust')),
            const SizedBox(height: 8),
            CenturyNote(text: t('work.example')),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-play-locations'),
          title: t('locations.title'),
          children: const [NewWorldLocationList()],
        ),
        CenturyPanel(
          key: const ValueKey('nw-play-cards'),
          title: t('cards.title'),
          body: t('cards.body'),
          children: [
            CenturyPoint(
              icon: Icons.handshake_outlined,
              title: t('cards.nativeTitle'),
              text: t('cards.native'),
            ),
            CenturyPoint(
              icon: Icons.build_outlined,
              title: t('cards.toolTitle'),
              text: t('cards.tool'),
            ),
            CenturyPoint(
              icon: Icons.person_add_alt_outlined,
              title: t('cards.settlersTitle'),
              text: t('cards.settlers'),
            ),
            CenturyPoint(
              icon: Icons.explore_outlined,
              title: t('cards.explorationTitle'),
              text: t('cards.exploration'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-play-rest'),
          title: l10n.t('centuryEtw.play.rest.title'),
          body: l10n.t('centuryEtwEw.play.rest.body'),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('nw-play-storage'),
          title: l10n.t('centuryEtw.play.storage.title'),
          body: l10n.t('centuryEtw.play.storage.body', {
            'n': '${NewWorldRules.storageLimit}',
          }),
          children: const [],
        ),
      ],
    );
  }
}

/// A New World's four location types; the From East to West games reuse it.
/// With [fortBonus] off, Forts only give their Point card.
class NewWorldLocationList extends StatelessWidget {
  const NewWorldLocationList({super.key, this.fortBonus = true});

  final bool fortBonus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String t(String key, [Map<String, String> args = const {}]) =>
        l10n.t('centuryNw.play.$key', args);

    return Column(
      children: [
        CenturyPoint(
          icon: Icons.add_box_outlined,
          title: t('locations.productionTitle'),
          text: t('locations.production'),
        ),
        CenturyPoint(
          icon: Icons.upgrade_rounded,
          title: t('locations.upgradeTitle'),
          text: t('locations.upgrade'),
        ),
        CenturyPoint(
          icon: Icons.swap_vert_rounded,
          title: t('locations.tradeTitle'),
          text: t('locations.trade'),
        ),
        if (fortBonus) ...[
          CenturyPoint(
            key: const ValueKey('nw-play-fort'),
            icon: Icons.fort_outlined,
            title: t('fort.title'),
            text: t('fort.body'),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28),
            child: Column(
              children: [
                CenturyPoint(
                  icon: Icons.workspace_premium_outlined,
                  title: t('fort.bonusTitle'),
                  text: t('fort.bonus', {'n': '${NewWorldRules.bonusSpaces}'}),
                ),
                CenturyPoint(
                  icon: Icons.style_outlined,
                  title: t('fort.cardTitle'),
                  text: t('fort.card'),
                ),
              ],
            ),
          ),
        ] else
          CenturyPoint(
            key: const ValueKey('nw-play-fort'),
            icon: Icons.fort_outlined,
            title: t('fort.title'),
            text: t('fort.card'),
          ),
      ],
    );
  }
}
