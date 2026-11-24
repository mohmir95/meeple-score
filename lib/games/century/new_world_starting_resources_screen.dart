import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import 'century_east_to_west_ew_rules.dart';
import 'century_new_world_rules.dart';
import 'century_rules.dart';
import 'century_widgets.dart';

/// What each player starts with: a player board, settlers, and cubes that
/// depend on the seat. The settlers depend on the player count, so they are
/// shown for every count. Every seat is listed, up to 4 players.
class NewWorldStartingResourcesScreen extends StatelessWidget {
  const NewWorldStartingResourcesScreen({
    super.key,
    this.style = CenturyStyleData.newWorld,
    this.easternWonders = false,
  });

  /// Also used by From East to West, which starts the same way.
  final CenturyStyleData style;

  /// From East to West (Eastern Wonders + A New World): side B of the player board, plus a
  /// boat and outposts from Eastern Wonders.
  final bool easternWonders;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final icon = compact ? 26.0 : 30.0;
    final cube = compact ? 20.0 : 24.0;
    final forest = style.accent;

    return CenturyPage(
      titleKey: 'hub.startingResources',
      style: style,
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
              hint: l10n.t(
                easternWonders
                    ? 'centuryEtwEw.start.boardHint'
                    : 'centuryNw.start.boardHint',
              ),
              value: '1',
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
              child: CenturyCountTable(
                key: const ValueKey('nw-start-settlers'),
                counts: NewWorldRules.playerCounts,
                rows: [
                  CenturyCountRow(
                    lead: Icon(Icons.person_rounded, color: forest, size: icon),
                    label: l10n.t('centuryNw.start.settlersBoard'),
                    value: NewWorldRules.settlersOnBoard,
                  ),
                  CenturyCountRow(
                    lead: Icon(
                      Icons.person_outline_rounded,
                      color: forest,
                      size: icon,
                    ),
                    label: l10n.t('centuryNw.start.settlersReserve'),
                    hint: l10n.t('centuryNw.start.settlersReserveHint'),
                    value: (n) =>
                        NewWorldRules.settlers -
                        NewWorldRules.settlersOnBoard(n),
                  ),
                ],
              ),
            ),
            CenturyRow(
              key: const ValueKey('nw-start-storage'),
              lead: Icon(Icons.inventory_2_outlined, color: forest, size: icon),
              label: l10n.t('centuryNw.start.storage'),
              hint: l10n.t('centuryNw.start.storageHint'),
              value: '${NewWorldRules.storageLimit}',
            ),
            if (easternWonders) ...[
              CenturyRow(
                key: const ValueKey('nw-start-boat'),
                lead: Icon(Icons.sailing_rounded, color: forest, size: icon),
                label: l10n.t('centuryEw.start.boat'),
                hint: l10n.t('centuryEtwEw.start.boatHint'),
                value: '1',
              ),
              CenturyRow(
                key: const ValueKey('nw-start-outposts'),
                lead: Icon(Icons.house_rounded, color: forest, size: icon),
                label: l10n.t('centuryEw.start.outposts'),
                hint: l10n.t('centuryEtwEw.start.outpostsHint'),
                value: '${EastToWestEwRules.outpostsPerPlayer}',
              ),
            ],
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
        color: seat == 1
            ? const Color(0xFFE2B33C)
            : CenturyStyle.of(context).accent,
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
