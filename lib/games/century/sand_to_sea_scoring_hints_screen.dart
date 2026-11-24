import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_rules.dart';
import 'century_sand_to_sea_game.dart';
import 'century_sand_to_sea_rules.dart';
import 'century_widgets.dart';

const _vpTile = Color(0xFFD9822B);

/// The From Sand to Sea rulebook's Game End rules, gathered as scoring
/// hints.
class SandToSeaScoringHintsScreen extends StatelessWidget {
  const SandToSeaScoringHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final hex = compact ? 24.0 : 28.0;
    final cube = compact ? 18.0 : 22.0;
    final leadWidth = compact ? 56.0 : 64.0;
    const purple = CenturySandToSeaGame.purple;

    return CenturyPage(
      titleKey: 'hub.scoringHints',
      style: CenturyStyleData.sandToSea,
      children: [
        CenturyPanel(
          key: const ValueKey('fs-score-end'),
          title: l10n.t('century.score.endTitle'),
          body: l10n.t('centuryEw.score.endBody', {
            'n': '${SandToSeaRules.vpTilesToEnd}',
          }),
          children: [
            CenturyRow(
              key: const ValueKey('fs-score-end-row'),
              lead: HexTile(color: _vpTile, size: hex, label: 'VP'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.endPlayers'),
              value: l10n.t('centuryEw.score.endTile', {
                'n': '${SandToSeaRules.vpTilesToEnd}',
              }),
            ),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(
              icon: Icons.emoji_events_outlined,
              text: l10n.t('century.score.tie'),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('fs-score-final'),
          title: l10n.t('century.score.finalTitle'),
          body: l10n.t('century.score.finalBody'),
          children: [
            CenturyRow(
              key: const ValueKey('fs-score-vp-tiles'),
              lead: HexTile(color: _vpTile, size: hex, label: 'VP'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.vpTiles'),
              hint: l10n.t('centuryEw.score.vpTilesHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('fs-score-board'),
              lead: Icon(Icons.house_outlined, color: purple, size: hex),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.board'),
              hint: l10n.t('centuryEw.score.boardHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('fs-score-bonus-vp'),
              lead: Container(
                width: hex,
                height: hex,
                decoration: BoxDecoration(
                  color: const Color(0xFFB23A2E),
                  borderRadius: BorderRadius.circular(hex * 0.16),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${SandToSeaRules.bonusVp.first}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: hex * 0.48,
                    height: 1,
                  ),
                ),
              ),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.bonusVp'),
              hint: l10n.t('centuryEw.score.bonusVpHint'),
              value: SandToSeaRules.bonusVp.join('/'),
            ),
            CenturyRow(
              key: const ValueKey('fs-score-cubes'),
              lead: Directionality(
                textDirection: TextDirection.ltr,
                child: SpiceCubes(
                  counts: const {
                    CenturySpice.saffron: 1,
                    CenturySpice.cardamom: 1,
                    CenturySpice.cinnamon: 1,
                  },
                  size: cube * 0.8,
                ),
              ),
              leadWidth: leadWidth,
              label: l10n.t('century.score.cubes'),
              hint: l10n.t('centuryEw.score.cubesHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('fs-score-yellow'),
              lead: SpiceCube(spice: CenturySpice.turmeric, size: cube),
              leadWidth: leadWidth,
              label: l10n.t('century.score.yellow'),
              value: '0',
            ),
          ],
        ),
      ],
    );
  }
}
