import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/score_stepper.dart';
import 'arnak_altars_dialog.dart';
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
              l10n.t('arnak.padHint'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 12),
            _buildSpiderTempleBar(context),
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
                      if (state.spiderTemple)
                        _buildDarkTabletsRow(context, metrics),
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
            title: context.l10n.t('game.arnak.headerPlayers'),
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
                  : () => row.onEdit?.call(player, state.lineFor(player.id)),
              color: row.color,
              child: Text(
                _cellText('${row.valueOf(state.lineFor(player.id))}'),
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

  Future<void> _openAltars(BuildContext context) async {
    final saved = await showArnakAltarsDialog(
      context,
      players: state.players,
      altars: state.altarTablets,
      readOnly: readOnly,
    );
    if (saved != null) {
      onChanged(state.copyWith(altarTablets: saved));
    }
  }

  Widget _buildSpiderTempleBar(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Material(
          color: _paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _grid.withValues(alpha: state.spiderTemple ? 0.8 : 0.4),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: readOnly
                ? null
                : () => onChanged(
                    state.copyWith(spiderTemple: !state.spiderTemple),
                  ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(darkTabletAsset, height: 28),
                  const SizedBox(width: 8),
                  Text(
                    l10n.t('arnak.spiderTemple'),
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    key: const ValueKey('arnak-spider-temple'),
                    value: state.spiderTemple,
                    onChanged: readOnly
                        ? null
                        : (on) => onChanged(state.copyWith(spiderTemple: on)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.spiderTemple)
          FilledButton.tonalIcon(
            key: const ValueKey('arnak-altars-button'),
            onPressed: () => _openAltars(context),
            icon: Image.asset(darkTabletAsset, height: 20),
            label: Text(l10n.t('arnak.altarsButton')),
          ),
      ],
    );
  }

  /// Read-only row: values come from the altars dialog, which a tap opens.
  Widget _buildDarkTabletsRow(BuildContext context, _PadMetrics metrics) {
    final l10n = context.l10n;
    return SizedBox(
      key: const ValueKey('arnak-dark-tablets-row'),
      height: metrics.rowHeight,
      child: Row(
        children: [
          _labelCell(
            context,
            metrics: metrics,
            icon: Icons.dark_mode_outlined,
            iconAsset: darkTabletAsset,
            title: l10n.t('arnak.darkTablets'),
            hint: l10n.t('arnak.darkTabletsHint'),
            color: _paperAlt,
          ),
          for (final player in state.players)
            _valueCell(
              context,
              metrics: metrics,
              onTap: () => _openAltars(context),
              color: _paperAlt,
              child: Text(
                switch (ArnakScoring.darkTabletsFor(state, player.id)) {
                  null => '—',
                  // A scored 0 is a result, so show it (unlike empty cells).
                  final points => '$points',
                },
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

  /// Blank until something is scored for [player]; after that a total of 0
  /// (e.g. dark tablets that broke even) is shown.
  String _totalText(Player player) {
    final total = ArnakScoring.totalForPlayer(state, player.id);
    final line = state.lineFor(player.id);
    final scored =
        line.research != 0 ||
        line.templeTiles != 0 ||
        line.idols != 0 ||
        line.guardians != 0 ||
        line.cards != 0 ||
        line.fear != 0 ||
        ArnakScoring.darkTabletsFor(state, player.id) != null;
    return scored ? '$total' : '';
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
                _totalText(player),
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
