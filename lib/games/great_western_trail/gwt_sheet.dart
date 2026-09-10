import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
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
  });

  final GwtState state;
  final ValueChanged<GwtState> onChanged;
  final bool readOnly;

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

  List<_GwtRow> _rows(BuildContext context, AppLocalizations l10n) {
    return [
      _GwtRow(
        title: l10n.t('gwt.coins'),
        hint: l10n.t('gwt.coinsHint'),
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
          title: l10n.t('gwt.coinsTitle'),
          helper: l10n.t('gwt.coinsHelper'),
          value: line.dollars,
          min: 0,
          update: (current, value) => current.copyWith(dollars: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.buildings'),
        hint: l10n.t('gwt.buildingsHint'),
        icon: Icons.home_work_outlined,
        color: _dust,
        valueOf: (line) => line.buildings,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.buildings'),
          helper: l10n.t('gwt.buildingsHelper'),
          value: line.buildings,
          min: 0,
          update: (current, value) => current.copyWith(buildings: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.deliveries'),
        hint: l10n.t('gwt.deliveriesHint'),
        icon: Icons.flag_outlined,
        color: _sage,
        valueOf: (line) => line.deliveries,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.deliveries'),
          helper: l10n.t('gwt.deliveriesHelper'),
          value: line.deliveries,
          update: (current, value) => current.copyWith(deliveries: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.stations'),
        hint: l10n.t('gwt.stationsHint'),
        icon: Icons.train_outlined,
        color: _dust,
        valueOf: (line) => line.stations,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.stations'),
          helper: l10n.t('gwt.stationsHelper'),
          value: line.stations,
          min: 0,
          update: (current, value) => current.copyWith(stations: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.hazards'),
        hint: l10n.t('gwt.hazardsHint'),
        icon: Icons.landscape_outlined,
        color: _sage,
        valueOf: (line) => line.hazards,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.hazards'),
          helper: l10n.t('gwt.hazardsHelper'),
          value: line.hazards,
          min: 0,
          update: (current, value) => current.copyWith(hazards: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.cattle'),
        hint: l10n.t('gwt.cattleHint'),
        icon: Icons.agriculture_outlined,
        color: _dust,
        valueOf: (line) => line.cattle,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.cattle'),
          helper: l10n.t('gwt.cattleHelper'),
          value: line.cattle,
          min: 0,
          update: (current, value) => current.copyWith(cattle: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.objectives'),
        hint: l10n.t('gwt.objectivesHint'),
        icon: Icons.task_alt_outlined,
        color: _sage,
        valueOf: (line) => line.objectives,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.objectives'),
          helper: l10n.t('gwt.objectivesHelper'),
          value: line.objectives,
          update: (current, value) => current.copyWith(objectives: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.stationMasters'),
        hint: l10n.t('gwt.stationMastersHint'),
        icon: Icons.badge_outlined,
        color: _dust,
        valueOf: (line) => line.stationMasters,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.stationMasters'),
          helper: l10n.t('gwt.stationMastersHelper'),
          value: line.stationMasters,
          min: 0,
          update: (current, value) => current.copyWith(stationMasters: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.playerBoard'),
        hint: l10n.t('gwt.playerBoardHint'),
        icon: Icons.person_outline,
        color: _sage,
        valueOf: (line) => line.playerBoard,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('gwt.playerBoard'),
          helper: l10n.t('gwt.playerBoardHelper'),
          value: line.playerBoard,
          min: 0,
          update: (current, value) => current.copyWith(playerBoard: value),
        ),
      ),
      _GwtRow(
        title: l10n.t('gwt.threeVp'),
        hint: l10n.t('gwt.threeVpHint'),
        icon: Icons.looks_3_outlined,
        color: _dust,
        valueOf: (line) => GwtScoring.threeVpPoints(line.clearedThreeVpSpace),
        displayOf: (line) => line.clearedThreeVpSpace ? '3' : '—',
        onTap: _toggleThree,
      ),
      _GwtRow(
        title: l10n.t('gwt.endGameToken'),
        hint: l10n.t('gwt.endGameTokenHint'),
        icon: Icons.workspace_premium_outlined,
        color: _sage,
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
        final compact = constraints.maxWidth < Breakpoints.compact;
        if (compact) {
          return _buildMobilePad(context, rows);
        }

        final players = state.players.length;
        const labelWidth = 168.0;
        const minCol = 96.0;
        final openWidth = math.max(0.0, constraints.maxWidth - labelWidth);
        final columnWidth = players == 0
            ? minCol
            : (openWidth / players).clamp(minCol, 160.0);
        final tableWidth = labelWidth + columnWidth * players;
        final metrics = _PadMetrics(
          labelWidth: labelWidth,
          columnWidth: columnWidth,
          rowHeight: 58,
          compact: false,
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
              l10n.t('score.padHint'),
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

  Widget _buildMobilePad(BuildContext context, List<_GwtRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('score.pad'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.t('score.padHintMobile'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _muted),
        ),
        const SizedBox(height: 12),
        _mobileTotals(context),
        const SizedBox(height: 12),
        for (final row in rows) ...[
          _mobileCategory(context, row),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _mobileTotals(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.brand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.t('score.totals'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < state.players.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Column(
                          children: [
                            Text(
                              state.players[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${GwtScoring.totalFor(state.lineFor(state.players[i].id))}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileCategory(BuildContext context, _GwtRow row) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _grid),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(row.icon, color: AppTheme.brand, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.title,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        row.hint,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _mobileScoreButtons(row),
          ],
        ),
      ),
    );
  }

  Widget _mobileScoreButtons(_GwtRow row) {
    final twoCol = state.players.length >= 3;
    final buttons = [
      for (final player in state.players)
        _mobileScoreButton(player, row),
    ];
    if (!twoCol) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < buttons.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: buttons[i]),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < buttons.length ? buttons[i + 1] : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _mobileScoreButton(Player player, _GwtRow row) {
    final line = state.lineFor(player.id);
    final label = row.displayOf?.call(line) ?? '${row.valueOf(line)}';
    return Material(
      color: _dust,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: readOnly
            ? null
            : () {
                if (row.onTap != null) {
                  row.onTap!(player);
                } else {
                  row.onEdit?.call(player, line);
                }
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: playerColor(player.colorValue), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: playerColor(player.colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: playerColorOutline(player.colorValue),
                        width: isLightPlayerColor(player.colorValue) ? 1 : 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
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
            title: context.l10n.t('game.gwt.headerPlayers'),
            hint: context.l10n.t('game.gwt.headerEdition'),
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
