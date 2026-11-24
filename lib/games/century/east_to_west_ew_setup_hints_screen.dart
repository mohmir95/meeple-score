import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_east_to_west_ew_rules.dart';
import 'century_new_world_rules.dart';
import 'century_widgets.dart';

const _board = Color(0xFF7A8F4E);
const _exploration = Color(0xFF8A6A3E);
const _market = Color(0xFF7FA66B);
const _sea = Color(0xFF7CC4D6);

/// The From East to West (Eastern Wonders + A New World) rulebook's Game Setup steps: the A
/// New World board, then a small Eastern Wonders island map beside it.
class EastToWestEwSetupHintsScreen extends StatelessWidget {
  const EastToWestEwSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final tile = compact ? 24.0 : 28.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.eastToWestEw,
      children: [
        CenturyPanel(
          key: const ValueKey('etwew-setup-board'),
          title: l10n.t('centuryNw.setup.boardTitle'),
          body: l10n.t('centuryEtwEw.setup.boardBody'),
          children: [Center(child: _BoardGrid(size: compact ? 64.0 : 84.0))],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-setup-points'),
          title: l10n.t('centuryNw.setup.pointsTitle'),
          body: l10n.t('centuryNw.setup.pointsBody'),
          children: [
            Center(
              child: CenturyBadge(
                key: const ValueKey('etwew-setup-remove-star'),
                icon: Icons.star_rounded,
                text: l10n.t('centuryNw.setup.removeStar'),
                error: true,
              ),
            ),
            const SizedBox(height: 12),
            CenturyCountTable(
              key: const ValueKey('etwew-setup-remove-marks'),
              counts: EastToWestEwRules.playerCounts,
              rows: [
                CenturyCountRow(
                  label: l10n.t('centuryNw.setup.removeMarksRow'),
                  value: (n) =>
                      EastToWestEwRules.pointCardMarksRemoved(n).join(', '),
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-setup-bonus'),
          title: l10n.t('centuryNw.setup.bonusTitle'),
          body: l10n.t('centuryNw.setup.bonusBody', {
            'n': '${EastToWestEwRules.bonusTilesInPlay}',
            'icons': l10n.t('centuryNw.setup.bonusIcons'),
          }),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-setup-exploration'),
          title: l10n.t('centuryNw.setup.explorationTitle'),
          body: l10n.t('centuryNw.setup.explorationBody', {
            'n': '${EastToWestEwRules.explorationTiles}',
          }),
          children: [
            CenturyCountTable(
              key: const ValueKey('etwew-setup-exploration-table'),
              counts: EastToWestEwRules.playerCounts,
              rows: [
                CenturyCountRow(
                  lead: _ExplorationTile(size: tile),
                  label: l10n.t('centuryNw.setup.explorationIcons'),
                  value: (_) => EastToWestEwRules.explorationOnIcons,
                ),
                CenturyCountRow(
                  lead: _ExplorationTile(size: tile, label: '2-3'),
                  label: l10n.t('centuryNw.setup.explorationTwoThree'),
                  value: EastToWestEwRules.explorationOnTwoThree,
                ),
                CenturyCountRow(
                  lead: Icon(
                    Icons.inventory_2_outlined,
                    color: centuryMuted,
                    size: compact ? 18 : 20,
                  ),
                  label: l10n.t('century.setup.toBoxShort'),
                  value: EastToWestEwRules.explorationToBox,
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-setup-goods'),
          title: l10n.t('centuryNw.setup.goodsTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) => 'centuryNw.goods.${NewWorldRules.goodsNames[s]}',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etwew-setup-island'),
          title: l10n.t('centuryEtwEw.setup.islandTitle'),
          body: l10n.t('centuryEtwEw.setup.islandBody', {
            'per': '${EastToWestEwRules.marketTilesPerSymbol}',
            'n': '${EastToWestEwRules.marketTiles}',
          }),
          children: [Center(child: _IslandMap(hex: compact ? 32.0 : 40.0))],
        ),
      ],
    );
  }
}

/// The game board: A2 and B2 on top, C1 and F2 below.
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
        children: [
          for (final row in EastToWestEwRules.boards)
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
class _IslandMap extends StatelessWidget {
  const _IslandMap({required this.hex});

  final double hex;

  /// Rows as (offset in tiles, tiles); true is the Sea tile.
  static const _rows = [
    (1.0, [false, false]),
    (0.5, [false, false, false]),
    (0.0, [false, false, true, false]),
    (0.5, [false, false, false]),
    (1.0, [false]),
  ];

  @override
  Widget build(BuildContext context) {
    final h = hex * 1.1547;
    final step = hex * 1.06;
    return SizedBox(
      key: const ValueKey('etwew-setup-island-map'),
      width: 4 * step,
      height: (_rows.length - 1) * h * 0.75 + h,
      child: Stack(
        children: [
          for (var r = 0; r < _rows.length; r++)
            for (var i = 0; i < _rows[r].$2.length; i++)
              Positioned(
                left: (_rows[r].$1 + i) * step,
                top: r * h * 0.75,
                child: _rows[r].$2[i]
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          HexTile(color: _sea, size: hex),
                          Icon(
                            Icons.sailing_rounded,
                            color: Colors.white,
                            size: hex * 0.5,
                          ),
                        ],
                      )
                    : HexTile(color: _market, size: hex),
              ),
        ],
      ),
    );
  }
}

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
