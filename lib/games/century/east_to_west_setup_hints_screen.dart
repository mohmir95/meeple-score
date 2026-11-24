import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_east_to_west_rules.dart';
import 'century_new_world_rules.dart';
import 'century_widgets.dart';

const _board = Color(0xFF7A8F4E);
const _exploration = Color(0xFF8A6A3E);
const _pointCard = Color(0xFF2F5D3A);

/// The From East to West rulebook's Game Setup steps: the A New World board,
/// then Spice Road's Merchant cards below it.
class EastToWestSetupHintsScreen extends StatelessWidget {
  const EastToWestSetupHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final card = compact ? 40.0 : 56.0;
    final spacing = compact ? 6.0 : 10.0;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.eastToWest,
      children: [
        CenturyPanel(
          key: const ValueKey('etw-setup-board'),
          title: l10n.t('centuryNw.setup.boardTitle'),
          body: l10n.t('centuryEtw.setup.boardBody'),
          children: [Center(child: _BoardGrid(size: compact ? 64.0 : 84.0))],
        ),
        CenturyPanel(
          key: const ValueKey('etw-setup-points'),
          title: l10n.t('centuryNw.setup.pointsTitle'),
          body: l10n.t('centuryNw.setup.pointsBody'),
          children: [
            Center(
              child: CenturyBadge(
                key: const ValueKey('etw-setup-remove-star'),
                icon: Icons.star_rounded,
                iconColor: Colors.black,
                text: l10n.t('centuryEtw.setup.removeStar'),
                error: true,
              ),
            ),
            const SizedBox(height: 12),
            CenturyCountTable(
              key: const ValueKey('etw-setup-remove-marks'),
              counts: EastToWestRules.playerCounts,
              rows: [
                CenturyCountRow(
                  label: l10n.t('centuryNw.setup.removeMarksRow'),
                  value: (n) =>
                      EastToWestRules.pointCardMarksRemoved(n).join(', '),
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-setup-bonus'),
          title: l10n.t('centuryNw.setup.bonusTitle'),
          body: l10n.t('centuryNw.setup.bonusBody', {
            'n': '${EastToWestRules.bonusTilesInPlay}',
            'icons': 'III',
          }),
          children: const [],
        ),
        CenturyPanel(
          key: const ValueKey('etw-setup-exploration'),
          title: l10n.t('centuryNw.setup.explorationTitle'),
          body: l10n.t('centuryEtw.setup.explorationBody', {
            'n': '${EastToWestRules.explorationTiles}',
          }),
          children: [
            CenturyCountTable(
              key: const ValueKey('etw-setup-exploration-table'),
              counts: EastToWestRules.playerCounts,
              rows: [
                CenturyCountRow(
                  lead: _ExplorationTile(size: compact ? 24 : 28),
                  label: l10n.t('centuryEtw.setup.explorationBeside'),
                  value: EastToWestRules.explorationBeside,
                ),
                CenturyCountRow(
                  lead: _ExplorationTile(size: compact ? 24 : 28, label: '2-3'),
                  label: l10n.t('centuryNw.setup.explorationTwoThree'),
                  value: EastToWestRules.explorationOnBoard,
                ),
              ],
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-setup-goods'),
          title: l10n.t('centuryNw.setup.goodsTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) => 'centuryNw.goods.${NewWorldRules.goodsNames[s]}',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('etw-setup-merchants'),
          title: l10n.t('centuryFs.setup.merchantsTitle'),
          body: l10n.t('centuryEtw.setup.merchantsBody', {
            'n': '${EastToWestRules.marketLocations}',
          }),
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (var i = 0; i < EastToWestRules.marketLocations; i++)
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
                key: const ValueKey('etw-setup-starting-cards'),
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

/// The game board: A1 and B1 on top, E2 and C2 below.
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
          for (final row in EastToWestRules.boards)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final label in row) board(label)],
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
        color: label == null ? _exploration : _pointCard,
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
