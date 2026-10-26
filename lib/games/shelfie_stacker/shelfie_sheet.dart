import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/export/score_sheet_export.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/score_stepper.dart';
import 'shelfie_player_line.dart';
import 'shelfie_scoring.dart';
import 'shelfie_state.dart';

typedef _LineUpdate =
    ShelfiePlayerLine Function(ShelfiePlayerLine line, int value);

class ShelfieSheet extends StatelessWidget {
  const ShelfieSheet({
    super.key,
    required this.state,
    required this.onChanged,
    required this.readOnly,
  });

  final ShelfieState state;
  final ValueChanged<ShelfieState> onChanged;
  final bool readOnly;

  // Colors from the printed Scoring Pad.
  static const _ink = Color(0xFF26313D);
  static const _muted = Color(0xFF55606C);
  static const _blue = Color(0xFF2F6DB5);
  static const _label = Color(0xFFDADADA);
  static const _labelAlt = Color(0xFFCFCFCF);
  static const _cell = Color(0xFFF7F7F5);
  static const _grid = Color(0xFF4A535C);

  Future<void> _editCount({
    required BuildContext context,
    required Player player,
    required String title,
    required String helper,
    required int value,
    required int Function(int value) pointsOf,
    required _LineUpdate update,
    int? max,
  }) async {
    if (readOnly) {
      return;
    }
    var draft = value.clamp(0, max ?? value);
    Widget preview(BuildContext context) {
      return Text(
        context.l10n.t('shelfie.pointsPreview', {'points': '${pointsOf(draft)}'}),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      );
    }

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
                      min: 0,
                      max: max,
                      large: true,
                      onChanged: (next) => setModalState(() => draft = next),
                    ),
                    const SizedBox(height: 12),
                    preview(context),
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
                      min: 0,
                      max: max,
                      onChanged: (next) => setModalState(() => draft = next),
                    ),
                    const SizedBox(height: 12),
                    preview(context),
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

  /// Columns a 5/4/3-tall row may still claim, keeping the Big Shelf at five.
  static int _columnsLeft(ShelfiePlayerLine line, int current) {
    return ShelfiePlayerLine.columns - line.scoredColumns + current;
  }

  List<_ShelfieRow> _rows(BuildContext context, AppLocalizations l10n) {
    _ShelfieRow columnRow({
      required String key,
      required int perColumn,
      required Color color,
      required int Function(ShelfiePlayerLine line) countOf,
      required _LineUpdate update,
    }) {
      return _ShelfieRow(
        key: key,
        title: l10n.t('shelfie.$key'),
        hint: l10n.t('shelfie.${key}Hint'),
        icon: Icons.view_week_outlined,
        color: color,
        pointsOf: (line) => countOf(line) * perColumn,
        countOf: countOf,
        onEdit: (player, line) => _editCount(
          context: context,
          player: player,
          title: l10n.t('shelfie.$key'),
          helper: l10n.t('shelfie.${key}Helper'),
          value: countOf(line),
          max: _columnsLeft(line, countOf(line)),
          pointsOf: (value) => value * perColumn,
          update: update,
        ),
      );
    }

    return [
      columnRow(
        key: 'fiveTall',
        perColumn: ShelfieScoring.fiveTallPoints,
        color: _label,
        countOf: (line) => line.fiveTall,
        update: (line, value) => line.copyWith(fiveTall: value),
      ),
      columnRow(
        key: 'fourTall',
        perColumn: ShelfieScoring.fourTallPoints,
        color: _labelAlt,
        countOf: (line) => line.fourTall,
        update: (line, value) => line.copyWith(fourTall: value),
      ),
      columnRow(
        key: 'threeTall',
        perColumn: ShelfieScoring.threeTallPoints,
        color: _label,
        countOf: (line) => line.threeTall,
        update: (line, value) => line.copyWith(threeTall: value),
      ),
      _ShelfieRow(
        key: 'pips',
        title: l10n.t('shelfie.pips'),
        hint: l10n.t('shelfie.pipsHint'),
        icon: Icons.casino_outlined,
        color: _labelAlt,
        pointsOf: (line) => line.pips,
        onEdit: (player, line) => _editCount(
          context: context,
          player: player,
          title: l10n.t('shelfie.pips'),
          helper: l10n.t('shelfie.pipsHelper'),
          value: line.pips,
          max: ShelfiePlayerLine.maxPips,
          pointsOf: (value) => value,
          update: (line, value) => line.copyWith(pips: value),
        ),
      ),
      _ShelfieRow(
        key: 'rewards',
        title: l10n.t('shelfie.rewards'),
        hint: l10n.t('shelfie.rewardsHint'),
        icon: Icons.style_outlined,
        color: _label,
        pointsOf: (line) => line.rewards,
        onEdit: (player, line) => _editCount(
          context: context,
          player: player,
          title: l10n.t('shelfie.rewards'),
          helper: l10n.t('shelfie.rewardsHelper'),
          value: line.rewards,
          pointsOf: (value) => value,
          update: (line, value) => line.copyWith(rewards: value),
        ),
      ),
      _ShelfieRow(
        key: 'shame',
        title: l10n.t('shelfie.shame'),
        hint: l10n.t('shelfie.shameHint'),
        icon: Icons.sentiment_very_dissatisfied_outlined,
        color: _labelAlt,
        pointsOf: ShelfieScoring.shame,
        countOf: (line) => line.shameDice,
        onEdit: (player, line) => _editCount(
          context: context,
          player: player,
          title: l10n.t('shelfie.shame'),
          helper: l10n.t('shelfie.shameHelper'),
          value: line.shameDice,
          pointsOf: ShelfieScoring.shameFor,
          update: (line, value) => line.copyWith(shameDice: value),
        ),
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
        final labelWidth = compact ? 96.0 : 220.0;
        final minCol = compact ? 68.0 : 96.0;
        final openWidth = math.max(0.0, constraints.maxWidth - labelWidth);
        final columnWidth = players == 0
            ? minCol
            : (openWidth / players).clamp(minCol, 160.0);
        final metrics = _PadMetrics(
          labelWidth: labelWidth,
          columnWidth: columnWidth,
          rowHeight: compact ? 58 : 52,
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
              l10n.t('shelfie.padHint'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              color: _blue,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Marks the full table (even scrolled off) for "Save image".
                child: ScoreSheetExportTarget(
                  child: SizedBox(
                    width: labelWidth + columnWidth * players,
                    child: Column(
                      children: [
                        _buildHeader(context, metrics),
                        for (final row in rows)
                          _buildRow(context, row, metrics),
                        _buildTotalRow(context, metrics),
                      ],
                    ),
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
          Container(
            width: metrics.labelWidth,
            height: metrics.rowHeight,
            alignment: AlignmentDirectional.centerStart,
            padding: EdgeInsets.symmetric(horizontal: metrics.compact ? 6 : 12),
            color: _blue,
            child: Text(
              context.l10n.t('game.shelfie.headerPlayers'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: metrics.compact ? 13 : 15,
              ),
            ),
          ),
          for (final player in state.players)
            Container(
              width: metrics.columnWidth,
              height: metrics.rowHeight,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: playerColor(player.colorValue),
                border: Border.all(color: _grid),
              ),
              child: Text(
                player.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: onPlayerColor(player.colorValue),
                  fontWeight: FontWeight.w800,
                  fontSize: metrics.compact ? 12 : 14,
                  height: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Zero cells stay blank so the pad reads like paper.
  static String _cellText(int points) => points == 0 ? '' : '$points';

  Widget _buildRow(BuildContext context, _ShelfieRow row, _PadMetrics metrics) {
    return SizedBox(
      key: ValueKey('shelfie-row-${row.key}'),
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
              metrics: metrics,
              onTap: readOnly
                  ? null
                  : () => row.onEdit(player, state.lineFor(player.id)),
              child: _pointsText(row, state.lineFor(player.id), metrics),
            ),
        ],
      ),
    );
  }

  /// Points in the cell, with the column/dice count underneath when the row
  /// is counted rather than entered as points.
  Widget _pointsText(
    _ShelfieRow row,
    ShelfiePlayerLine line,
    _PadMetrics metrics,
  ) {
    final points = Text(
      _cellText(row.pointsOf(line)),
      style: TextStyle(
        color: _ink,
        fontWeight: FontWeight.w800,
        fontSize: metrics.compact ? 20 : 18,
      ),
    );
    final count = row.countOf?.call(line) ?? 0;
    if (count == 0) {
      return points;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        points,
        Text(
          '×$count',
          style: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            height: 1,
          ),
        ),
      ],
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
            icon: Icons.functions,
            title: context.l10n.t('score.total'),
            color: _cell,
            bold: true,
          ),
          for (final player in state.players)
            _valueCell(
              metrics: metrics,
              child: Text(
                state.lineFor(player.id).isEmpty
                    ? ''
                    : '${ShelfieScoring.totalFor(state.lineFor(player.id))}',
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
                Icon(icon, size: 20, color: _ink),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ink,
                    fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(icon, size: 24, color: _ink),
                const SizedBox(width: 8),
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
                          fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                      if (hint.isNotEmpty)
                        Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
    if (hint.isEmpty || !metrics.compact) {
      return cell;
    }
    // Phones have no room for the hint line, so it lives in a tooltip.
    return Tooltip(
      message: hint,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      child: cell,
    );
  }

  Widget _valueCell({
    required _PadMetrics metrics,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Material(
      color: _cell,
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

class _ShelfieRow {
  const _ShelfieRow({
    required this.key,
    required this.title,
    required this.hint,
    required this.icon,
    required this.color,
    required this.pointsOf,
    this.countOf,
    required this.onEdit,
  });

  final String key;
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final int Function(ShelfiePlayerLine line) pointsOf;

  /// Set for rows entered as a count (columns, dice) rather than points.
  final int Function(ShelfiePlayerLine line)? countOf;
  final Future<void> Function(Player player, ShelfiePlayerLine line) onEdit;
}
