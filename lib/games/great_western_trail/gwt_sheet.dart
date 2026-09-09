import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
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
  });

  final GwtState state;
  final ValueChanged<GwtState> onChanged;
  final bool readOnly;

  static const _ink = Color(0xFF143528);
  static const _muted = Color(0xFF3F5C4C);
  static const _sage = Color(0xFFD7E6D4);
  static const _dust = Color(0xFFD5DDE6);
  static const _header = Color(0xFFF7F1E5);
  static const _grid = Color(0xFFB7C4B5);

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
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(draft),
                          child: const Text('Save'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
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
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(draft),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
    }
    if (saved == null) {
      return;
    }
    onChanged(state.updateLine(player.id, update(state.lineFor(player.id), saved)));
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

  @override
  Widget build(BuildContext context) {
    final rows = <_GwtRow>[
      _GwtRow(
        title: 'Coins',
        hint: '5 dollars = 1 VP',
        icon: Icons.monetization_on_outlined,
        color: _sage,
        valueOf: (line) => line.dollars,
        displayOf: (line) {
          final vp = GwtScoring.coinPoints(line.dollars);
          return line.dollars == 0 ? '0' : '${line.dollars}→$vp';
        },
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Dollars',
          helper:
              'Enter cash. Every 5 dollars becomes 1 victory point. Leftover dollars do not score.',
          value: line.dollars,
          min: 0,
          update: (current, value) => current.copyWith(dollars: value),
        ),
      ),
      _GwtRow(
        title: 'Buildings',
        hint: 'Private buildings',
        icon: Icons.home_work_outlined,
        color: _dust,
        valueOf: (line) => line.buildings,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Buildings',
          helper: 'Sum the VP printed on your private building tiles on the board.',
          value: line.buildings,
          min: 0,
          update: (current, value) => current.copyWith(buildings: value),
        ),
      ),
      _GwtRow(
        title: 'Deliveries',
        hint: 'Kansas City is −6',
        icon: Icons.flag_outlined,
        color: _sage,
        valueOf: (line) => line.deliveries,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Deliveries',
          helper: 'VP unlocked by discs on city crests, including −6 per Kansas City disc.',
          value: line.deliveries,
          update: (current, value) => current.copyWith(deliveries: value),
        ),
      ),
      _GwtRow(
        title: 'Stations',
        hint: 'Upgraded stations',
        icon: Icons.train_outlined,
        color: _dust,
        valueOf: (line) => line.stations,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Stations',
          helper: 'Sum the VP printed next to each train station that has your disc.',
          value: line.stations,
          min: 0,
          update: (current, value) => current.copyWith(stations: value),
        ),
      ),
      _GwtRow(
        title: 'Hazards',
        hint: 'Collected tiles',
        icon: Icons.landscape_outlined,
        color: _sage,
        valueOf: (line) => line.hazards,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Hazards',
          helper: 'Sum the VP printed on hazard tiles in front of you.',
          value: line.hazards,
          min: 0,
          update: (current, value) => current.copyWith(hazards: value),
        ),
      ),
      _GwtRow(
        title: 'Cattle',
        hint: 'Whole cattle deck',
        icon: Icons.agriculture_outlined,
        color: _dust,
        valueOf: (line) => line.cattle,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Cattle',
          helper: 'From draw stack, hand, and discard, sum VP printed on cattle cards.',
          value: line.cattle,
          min: 0,
          update: (current, value) => current.copyWith(cattle: value),
        ),
      ),
      _GwtRow(
        title: 'Objectives',
        hint: 'Unmet cards are negative',
        icon: Icons.task_alt_outlined,
        color: _sage,
        valueOf: (line) => line.objectives,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Objectives',
          helper:
              'Fulfilled cards score their positive VP. Incomplete cards subtract their negative VP.',
          value: line.objectives,
          update: (current, value) => current.copyWith(objectives: value),
        ),
      ),
      _GwtRow(
        title: 'Station masters',
        hint: 'Tile tasks',
        icon: Icons.badge_outlined,
        color: _dust,
        valueOf: (line) => line.stationMasters,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Station masters',
          helper: 'Score the individual tasks on station master tiles in front of you.',
          value: line.stationMasters,
          min: 0,
          update: (current, value) => current.copyWith(stationMasters: value),
        ),
      ),
      _GwtRow(
        title: 'Player board',
        hint: '4 VP per worker in 5–6',
        icon: Icons.person_outline,
        color: _sage,
        valueOf: (line) => line.playerBoard,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: 'Player board',
          helper: '4 VP for each worker on the 5th or 6th space of any worker row (max 24).',
          value: line.playerBoard,
          min: 0,
          update: (current, value) => current.copyWith(playerBoard: value),
        ),
      ),
      _GwtRow(
        title: '3-VP disc',
        hint: 'Tap 0 or 3',
        icon: Icons.looks_3_outlined,
        color: _dust,
        valueOf: (line) => GwtScoring.threeVpPoints(line.clearedThreeVpSpace),
        displayOf: (line) => line.clearedThreeVpSpace ? '3' : '—',
        onTap: _toggleThree,
      ),
      _GwtRow(
        title: 'End-game token',
        hint: 'Job market = 2 VP',
        icon: Icons.workspace_premium_outlined,
        color: _sage,
        valueOf: (line) => GwtScoring.jobMarketPoints(line.hasJobMarketToken),
        displayOf: (line) => line.hasJobMarketToken ? '2' : '—',
        onTap: _toggleJobMarket,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < Breakpoints.compact;
        final players = state.players.length;
        final labelWidth = compact ? 128.0 : 168.0;
        final minCol = compact ? 80.0 : 96.0;
        final openWidth = math.max(0.0, constraints.maxWidth - labelWidth);
        final columnWidth = players == 0
            ? minCol
            : (openWidth / players).clamp(minCol, compact ? 140.0 : 160.0);
        final tableWidth = labelWidth + columnWidth * players;
        final rowHeight = compact ? 68.0 : 58.0;
        final metrics = _PadMetrics(
          labelWidth: labelWidth,
          columnWidth: columnWidth,
          rowHeight: rowHeight,
          compact: compact,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score pad',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              compact
                  ? 'Tap a cell to enter points.'
                  : 'Tap a cell to enter points. The 3-VP disc row is on the official pad; leave it empty if you do not use it.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted),
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
            title: 'Players',
            hint: '1st Edition',
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

  Widget _buildRow(BuildContext context, _GwtRow row, _PadMetrics metrics) {
    return SizedBox(
      height: metrics.rowHeight,
      child: Row(
        children: [
          _labelCell(
            context,
            metrics: metrics,
            icon: row.icon,
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
                row.displayOf?.call(state.lineFor(player.id)) ??
                    '${row.valueOf(state.lineFor(player.id))}',
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
            title: 'Total',
            hint: 'Sum of VP',
            color: _header,
            bold: true,
          ),
          for (final player in state.players)
            _valueCell(
              context,
              metrics: metrics,
              color: _header,
              child: Text(
                '${GwtScoring.totalFor(state.lineFor(player.id))}',
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

  Widget _labelCell(
    BuildContext context, {
    required _PadMetrics metrics,
    required IconData icon,
    required String title,
    required String hint,
    required Color color,
    bool bold = false,
  }) {
    return Container(
      width: metrics.labelWidth,
      height: metrics.rowHeight,
      padding: EdgeInsets.symmetric(horizontal: metrics.compact ? 8 : 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _grid),
      ),
      child: Row(
        children: [
          Icon(icon, size: metrics.compact ? 22 : 20, color: _ink),
          SizedBox(width: metrics.compact ? 6 : 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
                    fontSize: metrics.compact ? 13 : 14,
                    height: 1.15,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _muted,
                    fontSize: metrics.compact ? 11 : 11,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          decoration: BoxDecoration(
            border: Border.all(color: _grid),
          ),
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
    required this.color,
    required this.valueOf,
    this.displayOf,
    this.onEdit,
    this.onTap,
  });

  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final int Function(GwtPlayerLine line) valueOf;
  final String Function(GwtPlayerLine line)? displayOf;
  final Future<void> Function(Player player, GwtPlayerLine line)? onEdit;
  final ValueChanged<Player>? onTap;
}
