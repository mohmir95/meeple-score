import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_sand_to_sea_rules.dart';
import 'century_widgets.dart';
import 'eastern_wonders_tiles.dart';

/// The From Sand to Sea rulebook's Game Setup steps: Spice Road's cards,
/// then the Eastern Wonders map with sea tiles.
class SandToSeaSetupHintsScreen extends StatelessWidget {
  const SandToSeaSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final cardWidth = compact ? 40.0 : 56.0;
    final spacing = compact ? 6.0 : 10.0;
    final hex = compact ? 30.0 : 40.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.sandToSea,
      children: [
        CenturyPanel(
          key: const ValueKey('fs-setup-merchants'),
          title: l10n.t('centuryFs.setup.merchantsTitle'),
          body: l10n.t('centuryFs.setup.merchantsBody', {
            'cards': '${SandToSeaRules.faceUpMerchantCards}',
          }),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (var i = 0; i < SandToSeaRules.faceUpMerchantCards; i++)
                      Padding(
                        padding: EdgeInsets.only(right: spacing),
                        child: CenturyCard(
                          color: centuryMerchantBack,
                          width: cardWidth,
                          faceUp: true,
                        ),
                      ),
                    SizedBox(width: spacing),
                    CenturyCard(
                      color: centuryMerchantBack,
                      width: cardWidth,
                      deck: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            CenturyCountTable(
              key: const ValueKey('fs-setup-to-box'),
              counts: SandToSeaRules.playerCounts,
              rows: [
                CenturyCountRow(
                  lead: CenturyCard(
                    color: centuryMerchantBack,
                    width: compact ? 16 : 20,
                  ),
                  label: l10n.t('century.setup.toBoxRow'),
                  value: SandToSeaRules.startingCardsToBox,
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-setup-map'),
          title: l10n.t('centuryEw.setup.mapTitle'),
          body: l10n.t('centuryFs.setup.mapBody', {
            'per': '${SandToSeaRules.marketTilesRemovedPerSymbol}',
            'sea': '${SandToSeaRules.seaTiles}',
            'ports': '${SandToSeaRules.ports}',
          }),
          children: [
            Center(child: EwMiniMap(hex: hex, sea: true)),
            SizedBox(height: compact ? 12 : 16),
            Center(
              child: CenturyBadge(
                key: const ValueKey('fs-setup-tiles-to-box'),
                text: l10n.t('centuryEw.setup.toBox', {
                  'n': '${SandToSeaRules.marketTilesRemoved}',
                }),
                error: true,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-setup-own-maps'),
          title: l10n.t('centuryEw.setup.ownMapsTitle'),
          body: l10n.t('centuryEw.setup.ownMapsBody'),
          children: [EwMapShapes(hex: compact ? 16.0 : 22.0)],
        ),
        CenturyPanel(
          key: const ValueKey('fs-setup-vp'),
          title: l10n.t('centuryEw.setup.vpTitle'),
          body: l10n.t('centuryEw.setup.vpBody', {
            'ports': '${SandToSeaRules.ports}',
            'n': '${SandToSeaRules.closedPortAmong}',
            'top': '${SandToSeaRules.closedPortAmong + 1}',
          }),
          children: [EwVpTiles(hex: hex * 0.85)],
        ),
        CenturyPanel(
          key: const ValueKey('fs-setup-bonus'),
          title: l10n.t('centuryEw.setup.bonusTitle'),
          body: l10n.t('centuryEw.setup.bonusBody'),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: compact ? 8 : 12,
                children: [
                  for (final vp in SandToSeaRules.bonusVp)
                    EwBonusTile(
                      key: ValueKey('fs-setup-bonus-$vp'),
                      vp: vp,
                      size: hex,
                      top: vp == SandToSeaRules.bonusVp.first,
                    ),
                ],
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-setup-spices'),
          title: l10n.t('century.setup.spicesTitle'),
          body: l10n.t('centuryEw.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) =>
                  'centuryEw.spice.${EasternWondersRules.spiceNames[s]}',
            ),
          ],
        ),
      ],
    );
  }
}
