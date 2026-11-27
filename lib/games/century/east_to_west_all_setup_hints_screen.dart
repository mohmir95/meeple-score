import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_east_to_west_all_rules.dart';
import 'century_new_world_rules.dart';
import 'century_widgets.dart';
import 'east_to_west_ew_setup_hints_screen.dart';

const _board = Color(0xFF7A8F4E);
const _exploration = Color(0xFF8A6A3E);

/// The From East to West (Spice Road + Eastern Wonders + A New World) rulebook's Game Setup steps:
/// the A New World board, Spice Road Merchant cards and an island map.
class EastToWestAllSetupHintsScreen extends StatelessWidget {
  const EastToWestAllSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final tile = compact ? 24.0 : 28.0;
    final card = compact ? 40.0 : 56.0;
    final spacing = compact ? 6.0 : 10.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.eastToWestAll,
      children: [
        CenturyPanel(
          key: const ValueKey('etwall-setup-board'),
          title: l10n.t('centuryNw.setup.boardTitle'),
          body: l10n.t('centuryEtwAll.setup.boardBody'),
          children: [Center(child: _BoardGrid(size: compact ? 60.0 : 84.0))],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-points'),
          title: l10n.t('centuryNw.setup.pointsTitle'),
          body: l10n.t('centuryNw.setup.pointsBody'),
          children: [
            Center(
              child: CenturyBadge(
                key: const ValueKey('etwall-setup-remove-star'),
                icon: Icons.star_rounded,
                iconColor: Colors.black,
                text: l10n.t('centuryEtw.setup.removeStar'),
                error: true,
              ),
            ),
            const SizedBox(height: 12),
            CenturyCountTable(
              key: const ValueKey('etwall-setup-remove-marks'),
              counts: EastToWestAllRules.playerCounts,
              rows: [
                CenturyCountRow(
                  label: l10n.t('centuryNw.setup.removeMarksRow'),
                  value: (n) =>
                      EastToWestAllRules.pointCardMarksRemoved(n).join(', '),
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-bonus'),
          title: l10n.t('centuryNw.setup.bonusTitle'),
          body: l10n.t('centuryEtwAll.setup.bonusBody', {
            'n': '${EastToWestAllRules.bonusTiles}',
          }),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-exploration'),
          title: l10n.t('centuryNw.setup.explorationTitle'),
          body: l10n.t('centuryNw.setup.explorationBody', {
            'n': '${EastToWestAllRules.explorationTiles}',
          }),
          children: [
            CenturyCountTable(
              key: const ValueKey('etwall-setup-exploration-table'),
              counts: EastToWestAllRules.playerCounts,
              rows: [
                CenturyCountRow(
                  lead: _ExplorationTile(size: tile),
                  label: l10n.t('centuryNw.setup.explorationIcons'),
                  value: (_) => EastToWestAllRules.explorationOnIcons,
                ),
                CenturyCountRow(
                  lead: _ExplorationTile(size: tile, label: '2-3'),
                  label: l10n.t('centuryNw.setup.explorationTwoThree'),
                  value: EastToWestAllRules.explorationOnTwoThree,
                ),
                CenturyCountRow(
                  lead: Icon(
                    Icons.inventory_2_outlined,
                    color: centuryMuted,
                    size: compact ? 18 : 20,
                  ),
                  label: l10n.t('century.setup.toBoxShort'),
                  value: EastToWestAllRules.explorationToBox,
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-goods'),
          title: l10n.t('centuryNw.setup.goodsTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) => 'centuryNw.goods.${NewWorldRules.goodsNames[s]}',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-island'),
          title: l10n.t('centuryEtwEw.setup.islandTitle'),
          body: l10n.t('centuryEtwEw.setup.islandBody', {
            'per': '${EastToWestAllRules.marketTilesPerSymbol}',
            'n': '${EastToWestAllRules.marketTiles}',
          }),
          children: [
            Center(
              child: EtwIslandMap(
                key: const ValueKey('etwall-setup-island-map'),
                hex: compact ? 32.0 : 40.0,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwall-setup-merchants'),
          title: l10n.t('centuryFs.setup.merchantsTitle'),
          body: l10n.t('centuryEtw.setup.merchantsBody', {
            'n': '${EastToWestAllRules.marketLocations}',
          }),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (var i = 0; i < EastToWestAllRules.marketLocations; i++)
                      Padding(
                        padding: EdgeInsets.only(right: spacing),
                        child: CenturyCard(
                          color: centuryMerchantBack,
                          width: card,
                          faceUp: true,
                        ),
                      ),
                    SizedBox(width: spacing),
                    CenturyCard(
                      color: centuryMerchantBack,
                      width: card,
                      deck: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            Center(
              child: CenturyBadge(
                key: const ValueKey('etwall-setup-starting-cards'),
                text: l10n.t('centuryEtw.setup.startingCardsToBox'),
                error: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The game board: A2 B2 E2 D2 on top, C1 F2 below A2 and B2.
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget board(String label) => Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _board,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.26,
        ),
      ),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in EastToWestAllRules.boards)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final label in row) board(label)],
            ),
        ],
      ),
    );
  }
}

/// 12 market tiles around the Sea tile, where every boat starts.
class _ExplorationTile extends StatelessWidget {
  const _ExplorationTile({required this.size, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.75,
      height: size * 1.1,
      decoration: BoxDecoration(
        color: _exploration,
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: label == null
          ? Icon(Icons.explore, color: Colors.white, size: size * 0.5)
          : Text(
              label!,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.26,
              ),
            ),
    );
  }
}
