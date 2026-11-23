import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_eastern_wonders_game.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

const _vpTile = Color(0xFFD9822B);

/// The Eastern Wonders rulebook's Game End rules, gathered as scoring hints.
class EasternWondersScoringHintsScreen extends StatelessWidget {
  const EasternWondersScoringHintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final hex = compact ? 24.0 : 28.0;
    final cube = compact ? 18.0 : 22.0;
    final leadWidth = compact ? 56.0 : 64.0;
    const brick = CenturyEasternWondersGame.brick;

    Widget square(String text) => Container(
      width: hex,
      height: hex,
      decoration: BoxDecoration(
        color: brick,
        borderRadius: BorderRadius.circular(hex * 0.16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: hex * 0.48,
          height: 1,
        ),
      ),
    );

    return CenturyPage(
      titleKey: 'hub.scoringHints',
      style: CenturyStyleData.easternWonders,
      children: [
        CenturyPanel(
          key: const ValueKey('ew-score-end'),
          title: l10n.t('century.score.endTitle'),
          body: l10n.t('centuryEw.score.endBody', {
            'n': '${EasternWondersRules.vpTilesToEnd}',
          }),
          children: [
            CenturyRow(
              key: const ValueKey('ew-score-end-row'),
              lead: HexTile(color: _vpTile, size: hex, label: 'VP'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.endPlayers'),
              value: l10n.t('centuryEw.score.endTile', {
                'n': '${EasternWondersRules.vpTilesToEnd}',
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
          key: const ValueKey('ew-score-final'),
          title: l10n.t('century.score.finalTitle'),
          body: l10n.t('century.score.finalBody'),
          children: [
            CenturyRow(
              key: const ValueKey('ew-score-vp-tiles'),
              lead: HexTile(color: _vpTile, size: hex, label: 'VP'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.vpTiles'),
              hint: l10n.t('centuryEw.score.vpTilesHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('ew-score-board'),
              lead: Icon(Icons.house_outlined, color: brick, size: hex),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.board'),
              hint: l10n.t('centuryEw.score.boardHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('ew-score-bonus-vp'),
              lead: square('${EasternWondersRules.bonusVp.first}'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.bonusVp'),
              hint: l10n.t('centuryEw.score.bonusVpHint'),
              value: EasternWondersRules.bonusVp.join('/'),
            ),
            CenturyRow(
              key: const ValueKey('ew-score-harvest'),
              lead: square('+'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.harvest'),
              hint: l10n.t('centuryEw.score.harvestHint'),
              value: '${EasternWondersRules.harvestBonusVp}',
            ),
            CenturyRow(
              key: const ValueKey('ew-score-upgrade'),
              lead: square('↑'),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.upgrade'),
              hint: l10n.t('centuryEw.score.upgradeHint'),
              value: '${EasternWondersRules.upgradeBonusVp}',
            ),
            CenturyRow(
              key: const ValueKey('ew-score-cubes'),
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
              key: const ValueKey('ew-score-yellow'),
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
