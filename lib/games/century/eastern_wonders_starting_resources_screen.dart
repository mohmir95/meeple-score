import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_eastern_wonders_game.dart';
import 'century_eastern_wonders_rules.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// What each player starts with, and the starting cube sets they choose
/// from in reverse turn order.
class EasternWondersStartingResourcesScreen extends StatelessWidget {
  const EasternWondersStartingResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final icon = compact ? 26.0 : 30.0;
    final cube = compact ? 20.0 : 24.0;
    const brick = CenturyEasternWondersGame.brick;

    return CenturyPage(
      titleKey: 'hub.startingResources',
      style: CenturyStyleData.easternWonders,
      children: [
        CenturyPanel(
          key: const ValueKey('ew-start-each'),
          title: l10n.t('century.start.eachTitle'),
          children: [
            CenturyRow(
              key: const ValueKey('ew-start-board'),
              lead: Container(
                width: icon * 1.3,
                height: icon * 0.9,
                decoration: BoxDecoration(
                  color: brick,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              label: l10n.t('centuryEw.start.board'),
              hint: l10n.t('centuryEw.start.boardHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('ew-start-boat'),
              lead: Icon(Icons.sailing_rounded, color: brick, size: icon),
              label: l10n.t('centuryEw.start.boat'),
              hint: l10n.t('centuryEw.start.boatHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('ew-start-outposts'),
              lead: Icon(Icons.house_rounded, color: brick, size: icon),
              label: l10n.t('centuryEw.start.outposts'),
              hint: l10n.t('centuryEw.start.outpostsHint'),
              value: '${EasternWondersRules.outpostsPerPlayer}',
            ),
            CenturyRow(
              key: const ValueKey('ew-start-cargo'),
              lead: Icon(Icons.inventory_2_outlined, color: brick, size: icon),
              label: l10n.t('centuryEw.start.cargo'),
              hint: l10n.t('centuryEw.start.cargoHint'),
              value: '${EasternWondersRules.cargoLimit}',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('ew-start-cubes'),
          title: l10n.t('centuryEw.start.cubesTitle'),
          body: l10n.t('centuryEw.start.cubesBody', {
            'n': '${EasternWondersRules.startingSets.length}',
          }),
          children: [
            for (var i = 0; i < EasternWondersRules.startingSets.length; i++)
              _setRow(context, i, cube),
            SizedBox(height: compact ? 10 : 12),
            CenturyNote(text: l10n.t('centuryEw.start.cubesNote')),
          ],
        ),
      ],
    );
  }

  Widget _setRow(BuildContext context, int index, double cube) {
    final l10n = context.l10n;
    final set = EasternWondersRules.startingSets[index];
    final total = set.values.fold(0, (sum, n) => sum + n);
    return CenturyRow(
      key: ValueKey('ew-start-set-$index'),
      lead: _SetBadge(letter: String.fromCharCode(65 + index)),
      label: [
        for (final spice in CenturySpice.values)
          if ((set[spice] ?? 0) > 0)
            l10n.t('century.start.cubes', {
              'n': '${set[spice]}',
              'spice': l10n.t('century.colour.${spice.name}'),
            }),
      ].join(' + '),
      value: '$total',
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: SpiceCubes(counts: set, size: cube),
      ),
    );
  }
}

class _SetBadge extends StatelessWidget {
  const _SetBadge({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CenturyEasternWondersGame.brick,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
