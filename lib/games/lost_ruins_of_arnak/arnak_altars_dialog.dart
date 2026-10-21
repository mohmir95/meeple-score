import 'package:flutter/material.dart';

import '../../domain/models/player.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import 'arnak_dark_tablets.dart';

const darkTabletAsset =
    'assets/games/lost_ruins_of_arnak/icons/dark_tablet.png';

/// Opens the altar editor. Returns the new tablet counts, or `null` if the
/// dialog was cancelled (or opened read-only).
Future<Map<String, List<int>>?> showArnakAltarsDialog(
  BuildContext context, {
  required List<Player> players,
  Map<String, List<int>>? altars,
  bool readOnly = false,
}) {
  final compact = Breakpoints.isCompact(context);
  final body = _AltarsEditor(
    players: players,
    initial: {
      for (final player in players)
        player.id: ArnakDarkTablets.countsFor(altars ?? const {}, player.id),
    },
    readOnly: readOnly,
  );
  return showDialog<Map<String, List<int>>>(
    context: context,
    builder: (_) => compact
        ? Dialog.fullscreen(child: body)
        : Dialog(
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
              child: body,
            ),
          ),
  );
}

class _AltarsEditor extends StatefulWidget {
  const _AltarsEditor({
    required this.players,
    required this.initial,
    required this.readOnly,
  });

  final List<Player> players;
  final Map<String, List<int>> initial;
  final bool readOnly;

  @override
  State<_AltarsEditor> createState() => _AltarsEditorState();
}

class _AltarsEditorState extends State<_AltarsEditor> {
  late final Map<String, List<int>> _draft = {
    for (final entry in widget.initial.entries) entry.key: List.of(entry.value),
  };

  static const _ink = Color(0xFF3C2415);
  static const _muted = Color(0xFF6B5344);
  static const _paper = Color(0xFFF3E6CC);
  static const _stone = Color(0xFF39425A);
  static const _stoneEdge = Color(0xFF242B3D);
  static const _gold = Color(0xFFE0B53A);

  void _set(String playerId, int altar, int value) {
    setState(() {
      _draft[playerId]![altar] = value.clamp(0, ArnakDarkTablets.maxPerAltar);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = Breakpoints.isCompact(context);
    final players = widget.players;
    final results = ArnakDarkTablets.results(players, _draft);

    return Material(
      color: _paper,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              20,
              compact ? 12 : 18,
              8,
              4,
            ),
            child: Row(
              children: [
                Image.asset(darkTabletAsset, height: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.t('arnak.altars.title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('common.cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                _RulesNotes(),
                const SizedBox(height: 16),
                Text(
                  l10n.t('arnak.altars.intro'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _muted),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 10.0;
                    final perRow = constraints.maxWidth < 640 ? 2 : 3;
                    final width =
                        (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (
                          var altar = 0;
                          altar < ArnakDarkTablets.altarValues.length;
                          altar++
                        )
                          SizedBox(
                            width: width,
                            child: _altarCard(
                              context,
                              altar,
                              inline: width >= 200,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ResultsCard(players: players, results: results, draft: _draft),
              ],
            ),
          ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.t('common.cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('arnak-altars-save'),
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: Text(l10n.t('common.save')),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _altarCard(BuildContext context, int altar, {required bool inline}) {
    final l10n = context.l10n;
    final winners = {
      for (final p in ArnakDarkTablets.altarWinners(
        widget.players,
        _draft,
        altar,
      ))
        p.id,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A5573), _stone],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _stoneEdge, width: 2),
      ),
      child: Padding(
        padding: inline
            ? const EdgeInsets.fromLTRB(10, 8, 10, 8)
            : const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          children: [
            // Gem and label share one line to keep the card short.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.t('arnak.altars.altar', {
                      'n': '${ArnakDarkTablets.altarRows[altar]}',
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: inline ? 14 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ArnakVpGem(
                  value: ArnakDarkTablets.altarValues[altar],
                  size: inline ? 32 : 28,
                ),
              ],
            ),
            const SizedBox(height: 3),
            for (final player in widget.players)
              _CounterRow(
                key: ValueKey('arnak-altar-$altar-${player.id}'),
                player: player,
                value: _draft[player.id]![altar],
                winner: winners.contains(player.id),
                readOnly: widget.readOnly,
                inline: inline,
                onChanged: (v) => _set(player.id, altar, v),
                gold: _gold,
              ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    super.key,
    required this.player,
    required this.value,
    required this.winner,
    required this.readOnly,
    required this.inline,
    required this.onChanged,
    required this.gold,
  });

  final Player player;
  final int value;
  final bool winner;
  final bool readOnly;

  /// Name beside the counter (wide cards) instead of above it (phones).
  final bool inline;
  final ValueChanged<int> onChanged;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final buttonSize = inline ? 28.0 : 26.0;
    final buttonStyle = IconButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.14),
      disabledForegroundColor: Colors.white24,
      minimumSize: Size(buttonSize, buttonSize),
      maximumSize: Size(buttonSize, buttonSize),
      padding: EdgeInsets.zero,
      iconSize: 16,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
    final nameParts = <Widget>[
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: playerColor(player.colorValue),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: inline ? 13 : 11.5,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    ];
    final counter = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.t('score.decrease'),
          style: buttonStyle,
          onPressed: readOnly || value <= 0 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: inline ? 18 : 16,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.t('score.increase'),
          style: buttonStyle,
          onPressed: readOnly || value >= ArnakDarkTablets.maxPerAltar
              ? null
              : () => onChanged(value + 1),
          icon: const Icon(Icons.add),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Tooltip(
        message: player.name,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 6,
            vertical: inline ? 3 : 2,
          ),
          decoration: BoxDecoration(
            color: winner ? gold.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: winner ? gold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: inline
              ? Row(children: [...nameParts, counter])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: nameParts),
                    const SizedBox(height: 3),
                    Center(child: counter),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.players,
    required this.results,
    required this.draft,
  });

  final List<Player> players;
  final Map<String, DarkTabletResult> results;
  final Map<String, List<int>> draft;

  static const _ink = Color(0xFF3C2415);
  static const _muted = Color(0xFF6B5344);

  String _signed(int n) => n > 0 ? '+$n' : '$n';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final used = ArnakDarkTablets.totalUsed(players, draft);
    final supply = ArnakDarkTablets.supplySize(players.length);
    final emptied = ArnakDarkTablets.emptiedSpaces(players, draft);
    final perTablet = ArnakDarkTablets.pointsPerTablet(players, draft);
    final overSupply = used > supply;

    return Card(
      key: const ValueKey('arnak-altars-results'),
      color: Colors.white,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Two players per row.
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 16.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: 10,
                  children: [
                    for (final player in players)
                      SizedBox(
                        width: width,
                        child: _playerResult(
                          context,
                          player,
                          results[player.id]!,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            const Divider(height: 12),
            Text(
              l10n.t('arnak.altars.supply', {
                'used': '$used',
                'total': '$supply',
                'emptied': '$emptied',
                'per': '$perTablet',
              }),
              style: const TextStyle(color: _muted, fontSize: 12, height: 1.3),
            ),
            if (overSupply) ...[
              const SizedBox(height: 4),
              Text(
                l10n.t('arnak.altars.overSupply', {'total': '$supply'}),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _playerResult(
    BuildContext context,
    Player player,
    DarkTabletResult result,
  ) {
    final l10n = context.l10n;
    return Row(
      key: ValueKey('arnak-altars-result-${player.id}'),
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: playerColor(player.colorValue),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                l10n.t('arnak.altars.breakdown', {
                  'altars': _signed(result.altarPoints),
                  'used': '${result.usedTablets}',
                  'per': '${result.pointsPerTablet}',
                  'cost': '${result.tabletPoints}',
                }),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        ArnakVpGem(
          key: ValueKey('arnak-altars-net-${player.id}'),
          value: result.total,
          size: 44,
          signed: true,
        ),
      ],
    );
  }
}

class _RulesNotes extends StatelessWidget {
  const _RulesNotes();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const style = TextStyle(color: Color(0xFF3C2415), height: 1.35);
    return Card(
      color: Colors.white.withValues(alpha: 0.7),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(
          l10n.t('arnak.altars.rulesTitle'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final key in const [
            'arnak.altars.rule1',
            'arnak.altars.rule2',
            'arnak.altars.rule3',
            'arnak.altars.tip',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.t(key), style: style),
            ),
        ],
      ),
    );
  }
}

/// A number on Arnak's purple victory-point gem (the Total row's icon with
/// its Σ painted out).
class ArnakVpGem extends StatelessWidget {
  const ArnakVpGem({
    super.key,
    required this.value,
    this.size = 36,
    this.signed = false,
  });

  static const asset = 'assets/games/lost_ruins_of_arnak/icons/vp_gem.png';

  static const _numeralColor = Color(0xFFDDD0EA);

  static const _numeral = TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: ['Georgia', 'Times New Roman', 'Noto Serif'],
    fontWeight: FontWeight.w700,
    fontSize: 40,
    height: 1,
  );

  final int value;
  final double size;

  /// Prefix positive values with "+".
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final text = signed && value > 0 ? '+$value' : '$value';
    return Semantics(
      label: '$text VP',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            // Bold serif numeral with a thin dark outline, like the printed
            // gems. Short values fill the stone; wide ones (-12) shrink.
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: size * (text.length > 1 ? 0.2 : 0.26),
                vertical: size * 0.23,
              ),
              child: FittedBox(
                child: Stack(
                  children: [
                    Text(
                      text,
                      style: _numeral.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..strokeJoin = StrokeJoin.round
                          ..color = const Color(0xFF3A0F55),
                      ),
                    ),
                    Text(text, style: _numeral.copyWith(color: _numeralColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
