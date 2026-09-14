import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/models/player.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/score_stepper.dart';
import 'arnak_player_line.dart';
import 'arnak_scoring.dart';
import 'arnak_state.dart';

typedef _LineUpdate = ArnakPlayerLine Function(ArnakPlayerLine line, int value);

class ArnakSheet extends StatelessWidget {
  const ArnakSheet({
    super.key,
    required this.state,
    required this.onChanged,
    required this.readOnly,
  });

  static const _iconResearch =
      'assets/games/lost_ruins_of_arnak/icons/research.png';
  static const _iconTemple =
      'assets/games/lost_ruins_of_arnak/icons/temple.png';
  static const _iconIdols = 'assets/games/lost_ruins_of_arnak/icons/idols.png';
  static const _iconGuardians =
      'assets/games/lost_ruins_of_arnak/icons/guardians.png';
  static const _iconCards = 'assets/games/lost_ruins_of_arnak/icons/cards.png';
  static const _iconFear = 'assets/games/lost_ruins_of_arnak/icons/fear.png';
  static const _iconTotal = 'assets/games/lost_ruins_of_arnak/icons/total.png';

  final ArnakState state;
  final ValueChanged<ArnakState> onChanged;
  final bool readOnly;

  static const _ink = Color(0xFF3C2415);
  static const _muted = Color(0xFF6B5344);
  static const _paper = Color(0xFFE8D4B0);
  static const _paperAlt = Color(0xFFDFC49A);
  static const _header = Color(0xFFD4B88A);
  static const _grid = Color(0xFF8B6B4A);

  Future<void> _editNumber({
    required BuildContext context,
    required Player player,
    required String title,
    required String helper,
    required int value,
    required _LineUpdate update,
    int? min,
    int? max,
  }) async {
    if (readOnly) {
      return;
    }
    var draft = value;
    if (max != null && draft > max) {
      draft = max;
    }
    if (min != null && draft < min) {
      draft = min;
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
                      min: min,
                      max: max,
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
                      max: max,
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

  List<_ArnakRow> _rows(BuildContext context, AppLocalizations l10n) {
    return [
      _ArnakRow(
        title: l10n.t('arnak.research'),
        hint: l10n.t('arnak.researchHint'),
        icon: Icons.search,
        iconAsset: _iconResearch,
        wideIcon: true,
        color: _paper,
        valueOf: (line) => line.research,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.research'),
          helper: l10n.t('arnak.researchHelper'),
          value: line.research,
          min: 0,
          update: (current, value) => current.copyWith(research: value),
        ),
      ),
      _ArnakRow(
        title: l10n.t('arnak.templeTiles'),
        hint: l10n.t('arnak.templeTilesHint'),
        icon: Icons.account_balance,
        iconAsset: _iconTemple,
        wideIcon: true,
        color: _paperAlt,
        valueOf: (line) => line.templeTiles,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.templeTiles'),
          helper: l10n.t('arnak.templeTilesHelper'),
          value: line.templeTiles,
          min: 0,
          update: (current, value) => current.copyWith(templeTiles: value),
        ),
      ),
      _ArnakRow(
        title: l10n.t('arnak.idols'),
        hint: l10n.t('arnak.idolsHint'),
        icon: Icons.brightness_high_outlined,
        iconAsset: _iconIdols,
        wideIcon: true,
        color: _paper,
        valueOf: (line) => line.idols,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.idols'),
          helper: l10n.t('arnak.idolsHelper'),
          value: line.idols,
          min: 0,
          update: (current, value) => current.copyWith(idols: value),
        ),
      ),
      _ArnakRow(
        title: l10n.t('arnak.guardians'),
        hint: l10n.t('arnak.guardiansHint'),
        icon: Icons.pets_outlined,
        iconAsset: _iconGuardians,
        color: _paperAlt,
        valueOf: (line) => line.guardians,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.guardians'),
          helper: l10n.t('arnak.guardiansHelper'),
          value: line.guardians,
          min: 0,
          update: (current, value) => current.copyWith(guardians: value),
        ),
      ),
      _ArnakRow(
        title: l10n.t('arnak.cards'),
        hint: l10n.t('arnak.cardsHint'),
        icon: Icons.style_outlined,
        iconAsset: _iconCards,
        wideIcon: true,
        color: _paper,
        valueOf: (line) => line.cards,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.cards'),
          helper: l10n.t('arnak.cardsHelper'),
          value: line.cards,
          min: 0,
          update: (current, value) => current.copyWith(cards: value),
        ),
      ),
      _ArnakRow(
        title: l10n.t('arnak.fear'),
        hint: l10n.t('arnak.fearHint'),
        icon: Icons.sentiment_very_dissatisfied_outlined,
        iconAsset: _iconFear,
        color: _paperAlt,
        valueOf: (line) => line.fear,
        onEdit: (player, line) => _editNumber(
          context: context,
          player: player,
          title: l10n.t('arnak.fear'),
          helper: l10n.t('arnak.fearHelper'),
          value: line.fear,
          max: 0,
          update: (current, value) => current.copyWith(fear: value),
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
              l10n.t('arnak.padHint'),
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

  Widget _buildMobilePad(BuildContext context, List<_ArnakRow> rows) {
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _muted),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
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
                              '${ArnakScoring.totalFor(state.lineFor(state.players[i].id))}',
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

  Widget _mobileCategory(BuildContext context, _ArnakRow row) {
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
                _sheetIcon(row, size: 32, color: AppTheme.brand),
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

  Widget _mobileScoreButtons(_ArnakRow row) {
    final twoCol = state.players.length >= 3;
    final buttons = [
      for (final player in state.players) _mobileScoreButton(player, row),
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
                child: i + 1 < buttons.length
                    ? buttons[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _mobileScoreButton(Player player, _ArnakRow row) {
    final line = state.lineFor(player.id);
    final label = '${row.valueOf(line)}';
    return Material(
      color: _paper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: readOnly ? null : () => row.onEdit?.call(player, line),
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
            title: context.l10n.t('game.arnak.headerPlayers'),
            hint: '',
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

  Widget _buildRow(BuildContext context, _ArnakRow row, _PadMetrics metrics) {
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
                  : () => row.onEdit?.call(
                      player,
                      state.lineFor(player.id),
                    ),
              color: row.color,
              child: Text(
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
            iconAsset: _iconTotal,
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
                '${ArnakScoring.totalFor(state.lineFor(player.id))}',
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

  Widget _sheetIcon(_ArnakRow row, {required double size, Color? color}) {
    return _padIcon(
      icon: row.icon,
      iconAsset: row.iconAsset,
      size: size,
      wide: row.wideIcon,
      color: color ?? _ink,
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
          _padIcon(
            icon: icon,
            iconAsset: iconAsset,
            size: metrics.compact ? 32 : 30,
            wide: wideIcon,
            color: _ink,
          ),
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
                if (hint.isNotEmpty)
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

class _ArnakRow {
  const _ArnakRow({
    required this.title,
    required this.hint,
    required this.icon,
    this.iconAsset,
    this.wideIcon = false,
    required this.color,
    required this.valueOf,
    this.onEdit,
  });

  final String title;
  final String hint;
  final IconData icon;
  final String? iconAsset;
  final bool wideIcon;
  final Color color;
  final int Function(ArnakPlayerLine line) valueOf;
  final Future<void> Function(Player player, ArnakPlayerLine line)? onEdit;
}
