import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_widgets.dart';
import 'eastern_wonders_tiles.dart';

/// The Eastern Wonders rulebook's Game Setup steps for the shared table.
class EasternWondersSetupHintsScreen extends StatelessWidget {
  const EasternWondersSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final hex = compact ? 30.0 : 40.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.easternWonders,
      children: [
        CenturyPanel(
          key: const ValueKey('ew-setup-map'),
          title: l10n.t('centuryEw.setup.mapTitle'),
          body: l10n.t('centuryEw.setup.mapBody', {
            'ports': '${EasternWondersRules.ports}',
          }),
          children: [
            Center(child: EwMiniMap(hex: hex)),
            SizedBox(height: compact ? 12 : 16),
            Center(
              child: CenturyBadge(
                key: const ValueKey('ew-setup-to-box'),
                text: l10n.t('centuryEw.setup.toBox', {
                  'n': '${EasternWondersRules.tradeSymbols}',
                }),
                error: true,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-own-maps'),
          title: l10n.t('centuryEw.setup.ownMapsTitle'),
          body: l10n.t('centuryEw.setup.ownMapsBody'),
          children: [EwMapShapes(hex: compact ? 16.0 : 22.0)],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-vp'),
          title: l10n.t('centuryEw.setup.vpTitle'),
          body: l10n.t('centuryEw.setup.vpBody', {
            'ports': '${EasternWondersRules.ports}',
            'n': '${EasternWondersRules.closedPortAmong}',
            'top': '${EasternWondersRules.closedPortAmong + 1}',
          }),
          children: [EwVpTiles(hex: hex * 0.85)],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-bonus'),
          title: l10n.t('centuryEw.setup.bonusTitle'),
          body: l10n.t('centuryEw.setup.bonusBody'),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: compact ? 8 : 12,
                children: [
                  for (final vp in EasternWondersRules.bonusVp)
                    EwBonusTile(
                      key: ValueKey('ew-setup-bonus-$vp'),
                      vp: vp,
                      size: hex,
                      top: vp == EasternWondersRules.bonusVp.first,
                    ),
                ],
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-setup-spices'),
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
