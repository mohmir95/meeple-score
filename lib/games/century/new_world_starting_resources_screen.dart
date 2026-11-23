import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_new_world_game.dart';
import 'century_new_world_rules.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// What each player starts with: a player board, settlers, and cubes that
/// depend on the seat. Every seat is listed, up to 4 players.
class NewWorldStartingResourcesScreen extends StatelessWidget {
  const NewWorldStartingResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final icon = compact ? 26.0 : 30.0;
    final cube = compact ? 20.0 : 24.0;
    const forest = CenturyNewWorldGame.forest;
    final onBoard = NewWorldRules.settlersOnBoard(4);
    final onBoardTwo = NewWorldRules.settlersOnBoard(2);

    return CenturyPage(
      titleKey: 'hub.startingResources',
      style: CenturyStyleData.newWorld,
      children: [
        CenturyPanel(
          key: const ValueKey('nw-start-each'),
          title: l10n.t('century.start.eachTitle'),
          children: [
            CenturyRow(
              key: const ValueKey('nw-start-board'),
              lead: Container(
                width: icon * 1.3,
                height: icon * 0.9,
                decoration: BoxDecoration(
                  color: forest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              label: l10n.t('centuryNw.start.board'),
              hint: l10n.t('centuryNw.start.boardHint'),
              value: '1',
            ),
            CenturyRow(
              key: const ValueKey('nw-start-settlers-board'),
              lead: Icon(Icons.person_rounded, color: forest, size: icon),
              label: l10n.t('centuryNw.start.settlersBoard'),
              hint: l10n.t('centuryNw.start.settlersBoardHint', {
                'n': '$onBoardTwo',
              }),
              value: '$onBoard',
            ),
            CenturyRow(
              key: const ValueKey('nw-start-settlers-reserve'),
              lead: Icon(
                Icons.person_outline_rounded,
                color: forest,
                size: icon,
              ),
              label: l10n.t('centuryNw.start.settlersReserve'),
              hint: l10n.t('centuryNw.start.settlersReserveHint', {
                'n': '${NewWorldRules.settlers - onBoardTwo}',
              }),
              value: '${NewWorldRules.settlers - onBoard}',
            ),
            CenturyRow(
              key: const ValueKey('nw-start-storage'),
              lead: Icon(Icons.inventory_2_outlined, color: forest, size: icon),
              label: l10n.t('centuryNw.start.storage'),
              hint: l10n.t('centuryNw.start.storageHint'),
              value: '${NewWorldRules.storageLimit}',
            ),
          ],
        ),
        CenturyPanel(
          key: const ValueKey('nw-start-cubes'),
          title: l10n.t('century.start.spicesTitle'),
          body: l10n.t('centuryNw.start.cubesBody'),
          children: [
            for (var seat = 1; seat <= NewWorldRules.playerCounts.last; seat++)
              _seatRow(context, seat, cube),
          ],
        ),
      ],
    );
  }

  Widget _seatRow(BuildContext context, int seat, double cube) {
    final l10n = context.l10n;
    final cubes = NewWorldRules.startingCubes(seat);
    final total = cubes.values.fold(0, (sum, n) => sum + n);
    return CenturyRow(
      key: ValueKey('nw-start-seat-$seat'),
      lead: _SeatBadge(seat: seat),
      label: l10n.t('century.start.seat.$seat'),
      hint: [
        for (final spice in CenturySpice.values)
          if ((cubes[spice] ?? 0) > 0)
            l10n.t('century.start.cubes', {
              'n': '${cubes[spice]}',
              'spice': l10n.t('century.colour.${spice.name}'),
            }),
      ].join(' + '),
      value: '$total',
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: SpiceCubes(counts: cubes, size: cube),
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({required this.seat});

  final int seat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: seat == 1 ? const Color(0xFFE2B33C) : CenturyNewWorldGame.forest,
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
        '$seat',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}
