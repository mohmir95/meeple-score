import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/score_stepper.dart';
import 'gwt_player_line.dart';
import 'gwt_scoring.dart';
import 'gwt_state.dart';

typedef _LineUpdate = GwtPlayerLine Function(GwtPlayerLine line, int value);

class GwtSheet extends StatelessWidget {
  const GwtSheet({
    super.key,
    required this.state,
    required this.onChanged,
    required this.readOnly,
    this.l10nPrefix = 'game.gwt',
    this.pad = GwtPadKind.classic,
  });

  static const _iconCoins = 'assets/games/great_western_trail/icons/coins.png';
  static const _iconBuildings =
      'assets/games/great_western_trail/icons/buildings.png';
  static const _iconDeliveries =
      'assets/games/great_western_trail/icons/deliveries.png';
  static const _iconStations =
      'assets/games/great_western_trail/icons/stations.png';
  static const _iconThreeVp =
      'assets/games/great_western_trail/icons/three-vp.png';
  static const _iconHazards =
      'assets/games/great_western_trail/icons/hazards.png';
  static const _iconCattle =
      'assets/games/great_western_trail/icons/cattle.png';
  static const _iconObjectives =
      'assets/games/great_western_trail/icons/objectives.png';
  static const _iconStationMasters =
      'assets/games/great_western_trail/icons/station-master.png';
  static const _iconPlayerBoard =
      'assets/games/great_western_trail/icons/player-board.png';
  static const _iconJobMarket =
      'assets/games/great_western_trail/icons/job-market.png';
  static const _iconShips =
      'assets/games/great_western_trail_argentina/icons/ships.png';
  static const _iconCityMaps =
      'assets/games/great_western_trail_argentina/icons/city-maps.png';
  static const _iconFarmers =
      'assets/games/great_western_trail_argentina/icons/farmers.png';
  static const _iconTwoVp =
      'assets/games/great_western_trail_argentina/icons/two-vp.png';

  final GwtState state;
  final ValueChanged<GwtState> onChanged;
  final bool readOnly;
  final String l10nPrefix;
  final GwtPadKind pad;

  String _pad(AppLocalizations l10n, String name) {
    return l10n.tOr('$l10nPrefix.$name', 'gwt.$name');
  }

  static const _ink = Color(0xFF1B3A4B);
  static const _muted = Color(0xFF4A6B7C);
  static const _sage = Color(0xFFD6EAF8);
  static const _dust = Color(0xFFEAF3FA);
  static const _header = Color(0xFFD4E6F1);
  static const _grid = Color(0xFFB8D4E8);

  Future<void> _editNumber({
    required BuildContext context,
    required Player player,
    required String title,
    required String helper,
    required int value,
    required _LineUpdate update,
    int? min,
  }) async {
    if (readOnly) {
      return;
    }
    var draft = value;
    final compact = Breakpoints.isCompact(context);
    final int? saved;
    if (compact) {
      saved = await showModalBottomSheet<int>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (dialogContext) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 4,
              bottom: MediaQuery.viewInsetsOf(dialogContext).bottom + 24,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${player.name} · $title',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(helper, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    ScoreStepper(
                      value: draft,
                      min: min,
                      large: true,
                      onChanged: (next) => setModalState(() => draft = next),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(draft),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(dialogContext.l10n.t('common.save')),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(dialogContext.l10n.t('common.cancel')),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    } else {
      saved = await showDialog<int>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('${player.name} · $title'),
            content: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(helper, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    ScoreStepper(
                      value: draft,
                      min: min,
                      onChanged: (next) => setModalState(() => draft = next),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogContext.l10n.t('common.cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(draft),
                child: Text(dialogContext.l10n.t('common.save')),
              ),
            ],
          );
        },
      );
    }
    if (saved == null) {
      return;
    }
    onChanged(
      state.updateLine(player.id, update(state.lineFor(player.id), saved)),
    );
  }

  void _toggleThree(Player player) {
    if (readOnly) {
      return;
    }
    final line = state.lineFor(player.id);
    onChanged(
      state.updateLine(
        player.id,
        line.copyWith(clearedThreeVpSpace: !line.clearedThreeVpSpace),
      ),
    );
  }

  void _toggleJobMarket(Player player) {
    if (readOnly) {
      return;
    }
    final line = state.lineFor(player.id);
    onChanged(
      state.updateLine(
        player.id,
        line.copyWith(hasJobMarketToken: !line.hasJobMarketToken),
      ),
    );
  }

  List<_GwtRow> _rows(BuildContext context, AppLocalizations l10n) {
    if (pad == GwtPadKind.argentina) {
      return _argentinaRows(context, l10n);
    }
    return _classicRows(context, l10n);
  }

  List<_GwtRow> _classicRows(BuildContext context, AppLocalizations l10n) {
    return [
      _GwtRow(
        title: _pad(l10n, 'coins'),
        hint: _pad(l10n, 'coinsHint'),
        icon: Icons.monetization_on_outlined,
        iconAsset: _iconCoins,
        wideIcon: true,
        color: _sage,
        valueOf: (line) => line.dollars,
        displayOf: (line) {
          final vp = GwtScoring.coinPoints(line.dollars);
          return line.dollars == 0 ? '0' : '${line.dollars}→$vp';
        },
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'coinsTitle'),
          helper: _pad(l10n, 'coinsHelper'),
          value: line.dollars,
          min: 0,
          update: (current, value) => current.copyWith(dollars: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'buildings'),
        hint: _pad(l10n, 'buildingsHint'),
        icon: Icons.home_work_outlined,
        iconAsset: _iconBuildings,
        color: _dust,
        valueOf: (line) => line.buildings,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'buildings'),
          helper: _pad(l10n, 'buildingsHelper'),
          value: line.buildings,
          min: 0,
          update: (current, value) => current.copyWith(buildings: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'deliveries'),
        hint: _pad(l10n, 'deliveriesHint'),
        icon: Icons.flag_outlined,
        iconAsset: _iconDeliveries,
        color: _sage,
        valueOf: (line) => line.deliveries,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'deliveries'),
          helper: _pad(l10n, 'deliveriesHelper'),
          value: line.deliveries,
          update: (current, value) => current.copyWith(deliveries: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'stations'),
        hint: _pad(l10n, 'stationsHint'),
        icon: Icons.train_outlined,
        iconAsset: _iconStations,
        color: _dust,
        valueOf: (line) => line.stations,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'stations'),
          helper: _pad(l10n, 'stationsHelper'),
          value: line.stations,
          min: 0,
          update: (current, value) => current.copyWith(stations: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'hazards'),
        hint: _pad(l10n, 'hazardsHint'),
        icon: Icons.landscape_outlined,
        iconAsset: _iconHazards,
        color: _sage,
        valueOf: (line) => line.hazards,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'hazards'),
          helper: _pad(l10n, 'hazardsHelper'),
          value: line.hazards,
          min: 0,
          update: (current, value) => current.copyWith(hazards: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'cattle'),
        hint: _pad(l10n, 'cattleHint'),
        icon: Icons.agriculture_outlined,
        iconAsset: _iconCattle,
        color: _dust,
        valueOf: (line) => line.cattle,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'cattle'),
          helper: _pad(l10n, 'cattleHelper'),
          value: line.cattle,
          min: 0,
          update: (current, value) => current.copyWith(cattle: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'objectives'),
        hint: _pad(l10n, 'objectivesHint'),
        icon: Icons.task_alt_outlined,
        iconAsset: _iconObjectives,
        color: _sage,
        valueOf: (line) => line.objectives,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'objectives'),
          helper: _pad(l10n, 'objectivesHelper'),
          value: line.objectives,
          update: (current, value) => current.copyWith(objectives: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'stationMasters'),
        hint: _pad(l10n, 'stationMastersHint'),
        icon: Icons.badge_outlined,
        iconAsset: _iconStationMasters,
        color: _dust,
        valueOf: (line) => line.stationMasters,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'stationMasters'),
          helper: _pad(l10n, 'stationMastersHelper'),
          value: line.stationMasters,
          min: 0,
          update: (current, value) => current.copyWith(stationMasters: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'playerBoard'),
        hint: _pad(l10n, 'playerBoardHint'),
        icon: Icons.person_outline,
        iconAsset: _iconPlayerBoard,
        color: _sage,
        valueOf: (line) => line.playerBoard,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'playerBoard'),
          helper: _pad(l10n, 'playerBoardHelper'),
          value: line.playerBoard,
          min: 0,
          update: (current, value) => current.copyWith(playerBoard: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'threeVp'),
        hint: _pad(l10n, 'threeVpHint'),
        icon: Icons.looks_3_outlined,
        iconAsset: _iconThreeVp,
        color: _dust,
        valueOf: (line) => GwtScoring.discPoints(line.clearedThreeVpSpace, pad),
        displayOf: (line) => line.clearedThreeVpSpace
            ? '${GwtScoring.discPoints(true, pad)}'
            : '—',
        onTap: _toggleThree,
      ),
      _GwtRow(
        title: _pad(l10n, 'endGameToken'),
        hint: _pad(l10n, 'endGameTokenHint'),
        icon: Icons.workspace_premium_outlined,
        iconAsset: _iconJobMarket,
        color: _sage,
        valueOf: (line) => GwtScoring.jobMarketPoints(line.hasJobMarketToken),
        displayOf: (line) => line.hasJobMarketToken ? '2' : '—',
        onTap: _toggleJobMarket,
      ),
    ];
  }

  List<_GwtRow> _argentinaRows(BuildContext context, AppLocalizations l10n) {
    return [
      _GwtRow(
        title: _pad(l10n, 'coins'),
        hint: _pad(l10n, 'coinsHint'),
        icon: Icons.monetization_on_outlined,
        iconAsset: _iconCoins,
        wideIcon: true,
        color: _sage,
        valueOf: (line) => line.dollars,
        displayOf: (line) {
          final vp = GwtScoring.coinPoints(line.dollars);
          return line.dollars == 0 ? '0' : '${line.dollars}→$vp';
        },
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'coinsTitle'),
          helper: _pad(l10n, 'coinsHelper'),
          value: line.dollars,
          min: 0,
          update: (current, value) => current.copyWith(dollars: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'buildings'),
        hint: _pad(l10n, 'buildingsHint'),
        icon: Icons.home_work_outlined,
        iconAsset: _iconBuildings,
        color: _dust,
        valueOf: (line) => line.buildings,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'buildings'),
          helper: _pad(l10n, 'buildingsHelper'),
          value: line.buildings,
          min: 0,
          update: (current, value) => current.copyWith(buildings: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'ships'),
        hint: _pad(l10n, 'shipsHint'),
        icon: Icons.directions_boat_outlined,
        iconAsset: _iconShips,
        color: _sage,
        valueOf: (line) => line.ships,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'ships'),
          helper: _pad(l10n, 'shipsHelper'),
          value: line.ships,
          update: (current, value) => current.copyWith(ships: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'cityMaps'),
        hint: _pad(l10n, 'cityMapsHint'),
        icon: Icons.map_outlined,
        iconAsset: _iconCityMaps,
        wideIcon: true,
        color: _dust,
        valueOf: (line) => line.cityMaps,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'cityMaps'),
          helper: _pad(l10n, 'cityMapsHelper'),
          value: line.cityMaps,
          update: (current, value) => current.copyWith(cityMaps: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'stations'),
        hint: _pad(l10n, 'stationsHint'),
        icon: Icons.train_outlined,
        iconAsset: _iconStations,
        color: _sage,
        valueOf: (line) => line.stations,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'stations'),
          helper: _pad(l10n, 'stationsHelper'),
          value: line.stations,
          min: 0,
          update: (current, value) => current.copyWith(stations: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'farmers'),
        hint: _pad(l10n, 'farmersHint'),
        icon: Icons.agriculture_outlined,
        iconAsset: _iconFarmers,
        color: _dust,
        valueOf: (line) => line.farmers,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'farmers'),
          helper: _pad(l10n, 'farmersHelper'),
          value: line.farmers,
          min: 0,
          update: (current, value) => current.copyWith(farmers: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'cattle'),
        hint: _pad(l10n, 'cattleHint'),
        icon: Icons.style_outlined,
        iconAsset: _iconCattle,
        color: _sage,
        valueOf: (line) => line.cattle,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'cattle'),
          helper: _pad(l10n, 'cattleHelper'),
          value: line.cattle,
          update: (current, value) => current.copyWith(cattle: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'objectives'),
        hint: _pad(l10n, 'objectivesHint'),
        icon: Icons.task_alt_outlined,
        iconAsset: _iconObjectives,
        color: _dust,
        valueOf: (line) => line.objectives,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'objectives'),
          helper: _pad(l10n, 'objectivesHelper'),
          value: line.objectives,
          update: (current, value) => current.copyWith(objectives: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'stationMasters'),
        hint: _pad(l10n, 'stationMastersHint'),
        icon: Icons.badge_outlined,
        iconAsset: _iconStationMasters,
        color: _sage,
        valueOf: (line) => line.stationMasters,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'stationMasters'),
          helper: _pad(l10n, 'stationMastersHelper'),
          value: line.stationMasters,
          min: 0,
          update: (current, value) => current.copyWith(stationMasters: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'playerBoard'),
        hint: _pad(l10n, 'playerBoardHint'),
        icon: Icons.person_outline,
        iconAsset: _iconPlayerBoard,
        color: _dust,
        valueOf: (line) => line.playerBoard,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: _pad(l10n, 'playerBoard'),
          helper: _pad(l10n, 'playerBoardHelper'),
          value: line.playerBoard,
          min: 0,
          update: (current, value) => current.copyWith(playerBoard: value),
        ),
      ),
      _GwtRow(
        title: _pad(l10n, 'twoVp'),
        hint: _pad(l10n, 'twoVpHint'),
        icon: Icons.looks_two_outlined,
        iconAsset: _iconTwoVp,
        color: _sage,
        valueOf: (line) => GwtScoring.discPoints(line.clearedThreeVpSpace, pad),
        displayOf: (line) => line.clearedThreeVpSpace
            ? '${GwtScoring.discPoints(true, pad)}'
            : '—',
        onTap: _toggleThree,
      ),
      _GwtRow(
        title: _pad(l10n, 'endGameToken'),
        hint: _pad(l10n, 'endGameTokenHint'),
        icon: Icons.workspace_premium_outlined,
        iconAsset: _iconJobMarket,
        color: _dust,
        valueOf: (line) => GwtScoring.jobMarketPoints(line.hasJobMarketToken),
        displayOf: (line) => line.hasJobMarketToken ? '2' : '—',
        onTap: _toggleJobMarket,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = _rows(context, l10n);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Same table on every screen size; phones get tighter columns and
        // scroll horizontally when the players don't fit.
        final compact = constraints.maxWidth < Breakpoints.compact;
        final players = state.players.length;
        final labelWidth = compact ? 84.0 : 160.0;
        final minCol = compact ? 72.0 : 96.0;
        final openWidth = math.max(0.0, constraints.maxWidth - labelWidth);
        final columnWidth = players == 0
            ? minCol
            : (openWidth / players).clamp(minCol, 160.0);
        final tableWidth = labelWidth + columnWidth * players;
        final metrics = _PadMetrics(
          labelWidth: labelWidth,
          columnWidth: columnWidth,
          rowHeight: compact ? 56 : 50,
          compact: compact,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('score.pad'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _pad(l10n, 'padHint'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              color: _header,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      _buildHeader(context, metrics),
                      for (final row in rows) _buildRow(context, row, metrics),
                      _buildTotalRow(context, metrics),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, _PadMetrics metrics) {
    return SizedBox(
      height: metrics.rowHeight,
      child: Row(
        children: [
          _labelCell(
            context,
            metrics: metrics,
            icon: Icons.shield_outlined,
            title: context.l10n.t('$l10nPrefix.headerPlayers'),
            hint: context.l10n.has('$l10nPrefix.headerEdition')
                ? context.l10n.t('$l10nPrefix.headerEdition')
                : '',
            color: _header,
            bold: true,
          ),
          for (final player in state.players)
            _valueCell(
              context,
              metrics: metrics,
              color: _header,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: metrics.compact ? 24 : 20,
                    height: metrics.compact ? 24 : 20,
                    decoration: BoxDecoration(
                      color: playerColor(player.colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(color: _grid),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    player.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      fontSize: metrics.compact ? 12 : 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Zero cells (scores and totals) stay blank so the pad reads like paper.
  static String _cellText(String text) => text == '0' ? '' : text;

  Widget _buildRow(BuildContext context, _GwtRow row, _PadMetrics metrics) {
    return SizedBox(
      height: metrics.rowHeight,
      child: Row(
        children: [
          _labelCell(
            context,
            metrics: metrics,
            icon: row.icon,
            iconAsset: row.iconAsset,
            wideIcon: row.wideIcon,
            title: row.title,
            hint: row.hint,
            color: row.color,
          ),
          for (final player in state.players)
            _valueCell(
              context,
              metrics: metrics,
              onTap: readOnly
                  ? null
                  : () {
                      final line = state.lineFor(player.id);
                      if (row.onTap != null) {
                        row.onTap!(player);
                      } else {
                        row.onEdit?.call(player, line);
                      }
                    },
              color: row.color,
              child: Text(
                _cellText(
                  row.displayOf?.call(state.lineFor(player.id)) ??
                      '${row.valueOf(state.lineFor(player.id))}',
                ),
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: metrics.compact ? 20 : 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, _PadMetrics metrics) {
    return SizedBox(
      height: metrics.rowHeight,
      child: Row(
        children: [
          _labelCell(
            context,
            metrics: metrics,
            icon: Icons.drag_handle,
            title: context.l10n.t('score.total'),
            hint: context.l10n.t('score.totalHint'),
            color: _header,
            bold: true,
          ),
          for (final player in state.players)
            _valueCell(
              context,
              metrics: metrics,
              color: _header,
              child: Text(
                _cellText(
                  '${GwtScoring.totalFor(state.lineFor(player.id), pad: pad)}',
                ),
                style: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: metrics.compact ? 22 : 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _padIcon({
    required IconData icon,
    String? iconAsset,
    required double size,
    required Color color,
    bool wide = false,
  }) {
    if (iconAsset == null) {
      return Icon(icon, size: size, color: color);
    }
    final height = wide ? size - 6 : size;
    final width = wide ? height * 2.1 : size;
    return Image.asset(
      iconAsset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) =>
          Icon(icon, size: size, color: color),
    );
  }

  Widget _labelCell(
    BuildContext context, {
    required _PadMetrics metrics,
    required IconData icon,
    String? iconAsset,
    bool wideIcon = false,
    required String title,
    String hint = '',
    required Color color,
    bool bold = false,
  }) {
    final cell = Container(
      width: metrics.labelWidth,
      height: metrics.rowHeight,
      padding: EdgeInsets.symmetric(horizontal: metrics.compact ? 4 : 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _grid),
      ),
      // Phones stack the label under the icon to keep the column narrow.
      child: metrics.compact
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _padIcon(
                  icon: icon,
                  iconAsset: iconAsset,
                  size: 24,
                  wide: wideIcon,
                  color: _ink,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                _padIcon(
                  icon: icon,
                  iconAsset: iconAsset,
                  size: 30,
                  wide: wideIcon,
                  color: _ink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _ink,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                      fontSize: 14,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
    );
    if (hint.isEmpty) {
      return cell;
    }
    // Descriptions live in a tooltip: hover on desktop, tap on phones.
    return Tooltip(
      message: hint,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: cell,
    );
  }

  Widget _valueCell(
    BuildContext context, {
    required _PadMetrics metrics,
    required Widget child,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: metrics.columnWidth,
          height: metrics.rowHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: _grid)),
          child: child,
        ),
      ),
    );
  }
}

class _PadMetrics {
  const _PadMetrics({
    required this.labelWidth,
    required this.columnWidth,
    required this.rowHeight,
    required this.compact,
  });

  final double labelWidth;
  final double columnWidth;
  final double rowHeight;
  final bool compact;
}

class _GwtRow {
  const _GwtRow({
    required this.title,
    required this.hint,
    required this.icon,
    this.iconAsset,
    this.wideIcon = false,
    required this.color,
    required this.valueOf,
    this.displayOf,
    this.onEdit,
    this.onTap,
  });

  final String title;

  final String hint;
  final IconData icon;
  final String? iconAsset;
  final bool wideIcon;
  final Color color;
  final int Function(GwtPlayerLine line) valueOf;
  final String Function(GwtPlayerLine line)? displayOf;
  final Future<void> Function(Player player, GwtPlayerLine line)? onEdit;
  final ValueChanged<Player>? onTap;
}
