import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_new_world_rules.dart';
import 'century_east_to_west_ew_rules.dart';
import 'century_east_to_west_rules.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

const _bonusTile = Color(0xFFB5895A);
const _exploration = Color(0xFF8A6A3E);

/// The A New World rulebook's Game End rules and the overview sheet's Bonus
/// tile scoring, gathered as scoring hints.
class NewWorldScoringHintsScreen extends StatelessWidget {
  const NewWorldScoringHintsScreen({
    super.key,
    this.style = CenturyStyleData.newWorld,
    this.merchantBonus = false,
    this.outposts = false,
  });

  /// From East to West (Eastern Wonders + A New World): uncovered outpost spaces score, and
  /// side B of the player board has 4 bonus spaces.
  final bool outposts;

  /// Also used by From East to West, which scores the same way.
  final CenturyStyleData style;

  /// Adds From East to West's bonus tile for Merchant cards.
  final bool merchantBonus;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final tile = compact ? 24.0 : 28.0;
    final cube = compact ? 18.0 : 22.0;
    final leadWidth = compact ? 56.0 : 64.0;

    Widget bonus(String text) => Container(
      width: tile * 1.3,
      height: tile,
      decoration: BoxDecoration(
        color: _bonusTile,
        borderRadius: BorderRadius.circular(tile * 0.25),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: tile * 0.45,
          height: 1,
        ),
      ),
    );

    return CenturyPage(
      titleKey: 'hub.scoringHints',
      style: style,
      children: [
        CenturyPanel(
          key: const ValueKey('nw-score-end'),
          title: l10n.t('century.score.endTitle'),
          body: l10n.t('centuryNw.score.endBody', {
            'n': '${NewWorldRules.pointCardsToEnd}',
          }),
          children: [
            CenturyRow(
              key: const ValueKey('nw-score-end-row'),
              lead: CenturyCard(color: style.accent, width: tile, faceUp: true),
              leadWidth: leadWidth,
              label: l10n.t('centuryEw.score.endPlayers'),
              value: l10n.t('centuryNw.score.endCard', {
                'n': '${NewWorldRules.pointCardsToEnd}',
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
          key: const ValueKey('nw-score-final'),
          title: l10n.t('century.score.finalTitle'),
          body: l10n.t('century.score.finalBody'),
          children: [
            CenturyRow(
              key: const ValueKey('nw-score-cards'),
              lead: CenturyCard(color: style.accent, width: tile, faceUp: true),
              leadWidth: leadWidth,
              label: l10n.t('century.score.cards'),
              hint: l10n.t('century.score.cardsHint'),
              value: l10n.t('century.score.printed'),
            ),
            CenturyRow(
              key: const ValueKey('nw-score-bonus'),
              lead: bonus('×'),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.bonus'),
              hint: l10n.t('centuryNw.score.bonusHint', {
                'n':
                    '${outposts ? EastToWestEwRules.bonusSpaces : NewWorldRules.bonusSpaces}',
              }),
              value: l10n.t('centuryNw.score.seeBelow'),
            ),
            if (outposts)
              CenturyRow(
                key: const ValueKey('nw-score-outposts'),
                lead: Icon(
                  Icons.house_outlined,
                  color: style.accent,
                  size: tile,
                ),
                leadWidth: leadWidth,
                label: l10n.t('centuryEtwEw.score.outposts'),
                hint: l10n.t('centuryEtwEw.score.outpostsHint'),
                value: l10n.t('century.score.printed'),
              ),
            CenturyRow(
              key: const ValueKey('nw-score-exploration'),
              lead: Container(
                width: tile * 0.75,
                height: tile * 1.1,
                decoration: BoxDecoration(
                  color: _exploration,
                  borderRadius: BorderRadius.circular(tile * 0.2),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${NewWorldRules.explorationTileVp}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: tile * 0.45,
                  ),
                ),
              ),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.exploration'),
              hint: l10n.t('centuryNw.score.explorationHint'),
              value: '${NewWorldRules.explorationTileVp}',
            ),
            CenturyRow(
              key: const ValueKey('nw-score-cubes'),
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
              hint: l10n.t('centuryNw.score.cubesHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('nw-score-yellow'),
              lead: SpiceCube(spice: CenturySpice.turmeric, size: cube),
              leadWidth: leadWidth,
              label: l10n.t('century.score.yellow'),
              value: '0',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-score-bonus-tiles'),
          title: l10n.t('centuryNw.score.bonusTitle'),
          body: l10n.t('centuryNw.score.bonusBody'),
          children: [
            CenturyRow(
              key: const ValueKey('nw-score-bonus-icon'),
              lead: bonus('${NewWorldRules.bonusPerIcon}'),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.perIcon'),
              value: '${NewWorldRules.bonusPerIcon}',
            ),
            CenturyRow(
              key: const ValueKey('nw-score-bonus-pair'),
              lead: bonus('${NewWorldRules.bonusPerPair}'),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.perPair'),
              value: '${NewWorldRules.bonusPerPair}',
            ),
            CenturyRow(
              key: const ValueKey('nw-score-bonus-settlers'),
              lead: bonus('${NewWorldRules.bonusPerTwoSettlers}'),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.perSettlers'),
              hint: l10n.t('centuryNw.score.perSettlersHint'),
              value: '${NewWorldRules.bonusPerTwoSettlers}',
            ),
            CenturyRow(
              key: const ValueKey('nw-score-bonus-flat'),
              lead: bonus('${NewWorldRules.bonusFlat}'),
              leadWidth: leadWidth,
              label: l10n.t('centuryNw.score.flat'),
              value: '${NewWorldRules.bonusFlat}',
            ),
            if (merchantBonus)
              CenturyRow(
                key: const ValueKey('nw-score-bonus-merchants'),
                lead: bonus('C'),
                leadWidth: leadWidth,
                label: l10n.t('centuryEtw.score.merchants'),
                hint: l10n.t('centuryEtw.score.merchantsHint'),
                value: '${EastToWestRules.merchantBonusVp}',
              ),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(text: l10n.t('centuryNw.score.iconsNote')),
          ],
        ),
      ],
    );
  }
}
