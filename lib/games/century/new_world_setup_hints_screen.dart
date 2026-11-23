import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_new_world_game.dart';
import 'century_new_world_rules.dart';
import 'century_widgets.dart';

const _board = Color(0xFF7A8F4E);
const _exploration = Color(0xFF8A6A3E);

/// The A New World rulebook's Game Setup steps, with the changes for the
/// player count.
class NewWorldSetupHintsScreen extends StatefulWidget {
  const NewWorldSetupHintsScreen({super.key});

  @override
  State<NewWorldSetupHintsScreen> createState() =>
      _NewWorldSetupHintsScreenState();
}

class _NewWorldSetupHintsScreenState extends State<NewWorldSetupHintsScreen> {
  var _players = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final card = compact ? 40.0 : 56.0;
    final marks = NewWorldRules.pointCardMarksRemoved(_players);
    final onTwoThree = NewWorldRules.explorationOnTwoThree(_players);
    final onIcons =
        NewWorldRules.explorationTiles - NewWorldRules.explorationExtra;

    return CenturyPage(
      titleKey: 'hub.setupHints',
      style: CenturyStyleData.newWorld,
      children: [
        CenturyPlayerPicker(
          players: _players,
          counts: NewWorldRules.playerCounts,
          onChanged: (n) => setState(() => _players = n),
        ),
        CenturyPanel(
          key: const ValueKey('nw-setup-board'),
          title: l10n.t('centuryNw.setup.boardTitle'),
          body: l10n.t('centuryNw.setup.boardBody'),
          children: [
            Center(child: _BoardGrid(size: compact ? 64.0 : 84.0)),
            SizedBox(height: compact ? 12 : 16),
            Center(
              child: CenturyBadge(
                key: const ValueKey('nw-setup-boards-to-box'),
                text: l10n.t('centuryNw.setup.boardsToBox', {
                  'n': '${NewWorldRules.choiceBoards.length - 1}',
                }),
                error: true,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-setup-points'),
          title: l10n.t('centuryNw.setup.pointsTitle'),
          body: l10n.t('centuryNw.setup.pointsBody'),
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                CenturyBadge(
                  key: const ValueKey('nw-setup-remove-star'),
                  text: l10n.t('centuryNw.setup.removeStar'),
                  error: true,
                ),
                for (final mark in marks)
                  CenturyBadge(
                    key: ValueKey('nw-setup-remove-$mark'),
                    text: l10n.t('centuryNw.setup.removeMark', {'mark': mark}),
                    error: true,
                  ),
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      CenturyCard(
                        color: CenturyNewWorldGame.forest,
                        width: card,
                        faceUp: true,
                      ),
                      SizedBox(width: compact ? 6 : 10),
                    ],
                    SizedBox(width: compact ? 6 : 10),
                    CenturyCard(
                      color: CenturyNewWorldGame.forest,
                      width: card,
                      faceUp: true,
                      deck: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-setup-bonus'),
          title: l10n.t('centuryNw.setup.bonusTitle'),
          body: l10n.t('centuryNw.setup.bonusBody', {
            'n': '${NewWorldRules.bonusTilesInPlay}',
          }),
          children: [
            Center(
              child: CenturyBadge(
                key: const ValueKey('nw-setup-bonus-remove'),
                text: l10n.t('centuryNw.setup.bonusRemove'),
                error: true,
              ),
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-setup-exploration'),
          title: l10n.t('centuryNw.setup.explorationTitle'),
          body: l10n.t('centuryNw.setup.explorationBody', {
            'n': '${NewWorldRules.explorationTiles}',
          }),
          children: [
            CenturyRow(
              key: const ValueKey('nw-setup-exploration-icons'),
              lead: _ExplorationTile(size: compact ? 24 : 28),
              label: l10n.t('centuryNw.setup.explorationIcons'),
              value: '$onIcons',
            ),
            CenturyRow(
              key: const ValueKey('nw-setup-exploration-23'),
              lead: _ExplorationTile(size: compact ? 24 : 28, label: '2-3'),
              label: l10n.t('centuryNw.setup.explorationTwoThree'),
              hint: l10n.t(
                onTwoThree > 0
                    ? 'centuryNw.setup.explorationTwoThreeHint'
                    : 'centuryNw.setup.explorationFourHint',
              ),
              value: '$onTwoThree',
              highlight: true,
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-setup-goods'),
          title: l10n.t('centuryNw.setup.goodsTitle'),
          body: l10n.t('century.setup.spicesBody'),
          children: [
            CenturySpiceOrder(
              nameKey: (s) => 'centuryNw.goods.${NewWorldRules.goodsNames[s]}',
            ),
          ],
        ),
      ],
    );
  }
}

/// The game board: A1, B1 and C1, plus one of D1, E1 or F1.
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    Widget board(String label, {bool choice = false}) => Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: choice ? _board.withValues(alpha: 0.55) : _board,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: choice ? const Color(0xFFF0C674) : Colors.white,
          width: choice ? 2.5 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * (choice ? 0.17 : 0.26),
          height: 1.1,
        ),
      ),
    );
    final [a, b, c] = NewWorldRules.fixedBoards;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [board(a), board(b)]),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              board(c),
              board(NewWorldRules.choiceBoards.join(' / '), choice: true),
            ],
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
