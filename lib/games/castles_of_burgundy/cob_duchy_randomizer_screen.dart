import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/player_colors.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/player_editor.dart';
import 'cob_duchy.dart';
import 'cob_palette.dart';

class CobDuchyRandomizerScreen extends StatefulWidget {
  const CobDuchyRandomizerScreen({
    super.key,
    this.random,
    this.initialPlayerCount = 2,
    this.initialPool = CobDuchyPool.base,
    this.initialFirstGame = false,
  });

  final math.Random? random;
  final int initialPlayerCount;
  final CobDuchyPool initialPool;
  final bool initialFirstGame;

  @override
  State<CobDuchyRandomizerScreen> createState() =>
      _CobDuchyRandomizerScreenState();
}

class _CobDuchyRandomizerScreenState extends State<CobDuchyRandomizerScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF7A2E3B);
  static const _coverAsset = 'assets/games/castles_of_burgundy/cover.webp';
  static const _stepMs = 220;
  static const _lockHoldMs = 520;
  static const _minPasses = 3;
  static const _maxPasses = 6;

  late int _players;
  late List<int> _colors;
  late CobDuchyPool _pool;
  late bool _firstGame;
  late List<CobDuchyAssignment> _deal;
  List<int>? _turnOrder;
  List<_TurnPlaceSpin> _placeSpins = const [];
  int _revealedPlaces = 0;
  int? _highlightSeat;
  bool _turnOrderSettled = false;
  AnimationController? _turnSpin;
  int _spinPhase = -1;
  final _spinRandom = math.Random();

  @override
  void initState() {
    super.initState();
    _players = widget.initialPlayerCount;
    _colors = [
      for (final option in cobPlayerColors.take(_players)) option.value,
    ];
    _pool = widget.initialPool;
    _firstGame = widget.initialFirstGame && _pool == CobDuchyPool.base;
    _deal = _draw();
  }

  void _fitColors(int count) {
    if (_colors.length > count) {
      _colors = _colors.sublist(0, count);
      return;
    }
    while (_colors.length < count) {
      final used = _colors.toSet();
      final next = cobPlayerColors.where(
        (option) => !used.contains(option.value),
      );
      if (next.isEmpty) {
        return;
      }
      _colors.add(next.first.value);
    }
  }

  PlayerColorOption _colorAt(int index) {
    final value = _colors[index];
    return cobPlayerColors.firstWhere((option) => option.value == value);
  }

  void _setColor(int index, int colorValue) {
    setState(() {
      final taken = _colors.indexOf(colorValue);
      final previous = _colors[index];
      if (taken == index || previous == colorValue) {
        return;
      }
      _colors[index] = colorValue;
      if (taken != -1) {
        _colors[taken] = previous;
      }
    });
  }

  List<CobDuchyAssignment> _draw() {
    return dealCobDuchies(
      playerCount: _players,
      pool: _pool,
      firstGame: _firstGame,
      random: widget.random,
    );
  }

  void _addColor(int colorValue) {
    if (_colors.length >= cobPlayerColors.length ||
        _colors.contains(colorValue)) {
      return;
    }
    setState(() {
      _colors.add(colorValue);
      _players = _colors.length;
      _clearTurnOrder();
      _deal = _draw();
    });
  }

  void _removeLastPlayer() {
    if (_players <= 2) {
      return;
    }
    setState(() {
      _colors.removeLast();
      _players = _colors.length;
      _clearTurnOrder();
      _deal = _draw();
    });
  }

  void _setPool(CobDuchyPool pool) {
    setState(() {
      _pool = pool;
      if (pool == CobDuchyPool.solo) {
        _players = 1;
        _firstGame = false;
      } else if (pool == CobDuchyPool.team) {
        _players = 2;
        _firstGame = false;
      } else {
        if (_players < 2) {
          _players = 2;
        }
        if (pool != CobDuchyPool.base) {
          _firstGame = false;
        }
      }
      _fitColors(_players);
      _clearTurnOrder();
      _deal = _draw();
    });
  }

  void _setFirstGame(bool enabled) {
    setState(() {
      _firstGame = enabled;
      _deal = _draw();
    });
  }

  void _randomize() {
    setState(() => _deal = _draw());
  }

  int get _turnSpinTotalMs {
    var total = 0;
    for (final place in _placeSpins) {
      total += place.lockStep * _stepMs + _lockHoldMs;
    }
    return total.clamp(_stepMs, 60000);
  }

  List<_TurnPlaceSpin> _planTurnOrder(List<int> order, math.Random random) {
    final remaining = [for (var i = 0; i < order.length; i++) i];
    final plans = <_TurnPlaceSpin>[];
    for (var place = 0; place < order.length; place++) {
      final winner = order[place];
      final cycle = [...remaining]..sort();
      if (cycle.length == 1) {
        plans.add(_TurnPlaceSpin(cycle: cycle, winner: winner, lockStep: 1));
        remaining.remove(winner);
        continue;
      }
      final minSteps = cycle.length * _minPasses;
      final maxSteps = cycle.length * _maxPasses;
      var lockStep = minSteps + random.nextInt(maxSteps - minSteps + 1);
      // Land on the chosen seat after walking the tiles in order.
      final offset = cycle.indexOf(winner);
      if (offset != -1) {
        final mod = lockStep % cycle.length;
        lockStep += (offset - mod + cycle.length) % cycle.length;
        if (lockStep < minSteps) {
          lockStep += cycle.length;
        }
      }
      plans.add(
        _TurnPlaceSpin(cycle: cycle, winner: winner, lockStep: lockStep),
      );
      remaining.remove(winner);
    }
    return plans;
  }

  void _stopTurnSpin() {
    _turnSpin
      ?..removeListener(_onTurnSpin)
      ..removeStatusListener(_onTurnStatus)
      ..dispose();
    _turnSpin = null;
  }

  void _clearTurnOrder() {
    _stopTurnSpin();
    _turnOrder = null;
    _placeSpins = const [];
    _revealedPlaces = 0;
    _highlightSeat = null;
    _turnOrderSettled = false;
    _spinPhase = -1;
  }

  void _rollTurnOrder() {
    final random = widget.random ?? _spinRandom;
    final order = [for (var i = 0; i < _players; i++) i]..shuffle(random);
    final plans = _planTurnOrder(order, random);
    _stopTurnSpin();
    setState(() {
      _turnOrder = order;
      _placeSpins = plans;
      _revealedPlaces = 0;
      _highlightSeat = plans.isEmpty ? null : plans.first.cycle.first;
      _turnOrderSettled = false;
      _spinPhase = -1;
    });
    _turnSpin =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: _turnSpinTotalMs),
          )
          ..addListener(_onTurnSpin)
          ..addStatusListener(_onTurnStatus)
          ..forward();
  }

  void _onTurnSpin() {
    final order = _turnOrder;
    final spin = _turnSpin;
    if (order == null || spin == null || _placeSpins.isEmpty) {
      return;
    }
    final elapsed = spin.value * _turnSpinTotalMs;
    var cursor = 0.0;
    var placeIndex = 0;
    int? active;
    var revealed = 0;
    for (; placeIndex < _placeSpins.length; placeIndex++) {
      final place = _placeSpins[placeIndex];
      final spinMs = place.lockStep * _stepMs;
      final segmentMs = spinMs + _lockHoldMs;
      if (elapsed < cursor + spinMs) {
        final step = ((elapsed - cursor) / _stepMs).floor().clamp(
          0,
          place.lockStep - 1,
        );
        active = place.cycle[step % place.cycle.length];
        revealed = placeIndex;
        break;
      }
      if (elapsed < cursor + segmentMs) {
        // Keep only the place tag once a seat is chosen.
        active = null;
        revealed = placeIndex + 1;
        break;
      }
      cursor += segmentMs;
      if (placeIndex == _placeSpins.length - 1) {
        active = null;
        revealed = order.length;
      }
    }
    final phase = (elapsed / (_stepMs / 2)).floor();
    if (phase == _spinPhase &&
        active == _highlightSeat &&
        revealed == _revealedPlaces) {
      return;
    }
    setState(() {
      _spinPhase = phase;
      _highlightSeat = active;
      _revealedPlaces = revealed;
    });
  }

  void _onTurnStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _turnOrder == null) {
      return;
    }
    setState(() {
      _revealedPlaces = _turnOrder!.length;
      _highlightSeat = null;
      _turnOrderSettled = true;
    });
  }

  @override
  void dispose() {
    _stopTurnSpin();
    super.dispose();
  }

  int? _rankAt(int index) {
    if (_turnOrder == null) {
      return null;
    }
    final rank = _turnOrder!.indexOf(index);
    if (rank == -1 || rank >= _revealedPlaces) {
      return null;
    }
    return rank;
  }

  bool _isHighlighted(int index) => _highlightSeat == index;

  String? _rankLabel(int index) {
    final rank = _rankAt(index);
    if (rank == null) {
      return null;
    }
    return context.l10n.t('cob.duchy.place.${rank + 1}');
  }

  String _hintKey() {
    if (_firstGame) {
      return 'cob.duchy.hint.firstGame';
    }
    return switch (_pool) {
      CobDuchyPool.base => 'cob.duchy.hint.base',
      CobDuchyPool.firstExpansion => 'cob.duchy.hint.firstExpansion',
      CobDuchyPool.championship => 'cob.duchy.hint.championship',
      CobDuchyPool.specialEdition => 'cob.duchy.hint.specialEdition',
      CobDuchyPool.borderPosts => 'cob.duchy.hint.borderPosts',
      CobDuchyPool.team => 'cob.duchy.hint.team',
      CobDuchyPool.solo => 'cob.duchy.hint.solo',
    };
  }

  String _cardLabel(int index) {
    final l10n = context.l10n;
    if (_pool == CobDuchyPool.team) {
      return index == 0 ? l10n.t('cob.duchy.teamA') : l10n.t('cob.duchy.teamB');
    }
    return l10n.colorLabel(_colorAt(index).name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPage(
      title: l10n.t('hub.duchyBoardRandomizer'),
      coverImageAsset: _coverAsset,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < Breakpoints.compact;
          final padding = compact ? 12.0 : 20.0;
          final multiplayer =
              _pool != CobDuchyPool.solo && _pool != CobDuchyPool.team;
          return ListView(
            padding: EdgeInsets.all(padding),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.t(_hintKey()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      _Controls(
                        colors: [
                          for (var i = 0; i < _colors.length; i++) _colorAt(i),
                        ],
                        pool: _pool,
                        firstGame: _firstGame,
                        showPlayerCount: multiplayer,
                        showColorPicker: _pool != CobDuchyPool.team,
                        onAdd: _addColor,
                        onRemove: _removeLastPlayer,
                        onColor: _setColor,
                        onPool: _setPool,
                        onFirstGame: _setFirstGame,
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _DealGrid(
                          key: ValueKey(
                            _deal
                                .map(
                                  (deal) => '${deal.boardId}:${deal.otherSide}',
                                )
                                .join('|'),
                          ),
                          deal: _deal,
                          compact: compact,
                          settled: _turnOrderSettled,
                          labelAt: _cardLabel,
                          rankAt: _rankLabel,
                          highlightedAt: _isHighlighted,
                          colorAt: (index) => _pool == CobDuchyPool.team
                              ? cobPlayerColors[index]
                              : _colorAt(index),
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                            key: const ValueKey('cob-duchy-randomize'),
                            onPressed: _randomize,
                            icon: const Icon(Icons.casino_outlined, size: 18),
                            label: Text(l10n.t('cob.duchy.randomize')),
                          ),
                          if (_players > 1)
                            FilledButton.icon(
                              key: const ValueKey('cob-duchy-turn-order'),
                              onPressed: _rollTurnOrder,
                              icon: const Icon(
                                Icons.emoji_events_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.t('cob.duchy.turnOrder')),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.colors,
    required this.pool,
    required this.firstGame,
    required this.showPlayerCount,
    required this.showColorPicker,
    required this.onAdd,
    required this.onRemove,
    required this.onColor,
    required this.onPool,
    required this.onFirstGame,
  });

  final List<PlayerColorOption> colors;
  final CobDuchyPool pool;
  final bool firstGame;
  final bool showPlayerCount;
  final bool showColorPicker;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;
  final void Function(int index, int colorValue) onColor;
  final ValueChanged<CobDuchyPool> onPool;
  final ValueChanged<bool> onFirstGame;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showColorPicker) ...[
          Text(
            l10n.t('players.title'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < colors.length; i++)
                PlayerColorBadge(
                  key: ValueKey('cob-duchy-color-$i'),
                  number: i + 1,
                  colorValue: colors[i].value,
                  colorName: l10n.colorLabel(colors[i].name),
                  options: cobPlayerColors,
                  enabled: true,
                  onSelected: (value) => onColor(i, value),
                ),
              if (showPlayerCount && colors.length < cobPlayerColors.length)
                _AddPlayerButton(
                  used: {for (final color in colors) color.value},
                  onSelected: onAdd,
                ),
              if (showPlayerCount && colors.length > 2)
                _PlayerCountButton(
                  key: const ValueKey('cob-duchy-remove-player'),
                  tooltip: l10n.t('players.remove'),
                  icon: Icons.remove,
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _poolChips(l10n))
              _PoolChip(
                chipKey: ValueKey(entry.key),
                label: entry.label,
                selected: pool == entry.pool,
                onSelected: () => onPool(entry.pool),
              ),
          ],
        ),
        if (pool == CobDuchyPool.base) ...[
          const SizedBox(height: 4),
          SwitchListTile(
            key: const ValueKey('cob-duchy-first-game'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.t('cob.duchy.firstGame'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            value: firstGame,
            onChanged: onFirstGame,
          ),
        ],
      ],
    );
  }

  List<({String key, String label, CobDuchyPool pool})> _poolChips(
    AppLocalizations l10n,
  ) {
    return [
      (
        key: 'cob-duchy-pool-base',
        label: l10n.t('cob.duchy.base'),
        pool: CobDuchyPool.base,
      ),
      (
        key: 'cob-duchy-pool-first',
        label: l10n.t('cob.duchy.firstExpansion'),
        pool: CobDuchyPool.firstExpansion,
      ),
      (
        key: 'cob-duchy-pool-championship',
        label: l10n.t('cob.duchy.championship'),
        pool: CobDuchyPool.championship,
      ),
      (
        key: 'cob-duchy-pool-special',
        label: l10n.t('cob.duchy.specialEdition'),
        pool: CobDuchyPool.specialEdition,
      ),
      (
        key: 'cob-duchy-pool-border',
        label: l10n.t('cob.duchy.borderPosts'),
        pool: CobDuchyPool.borderPosts,
      ),
      (
        key: 'cob-duchy-pool-team',
        label: l10n.t('cob.duchy.team'),
        pool: CobDuchyPool.team,
      ),
      (
        key: 'cob-duchy-pool-solo',
        label: l10n.t('cob.duchy.solo'),
        pool: CobDuchyPool.solo,
      ),
    ];
  }
}

class _AddPlayerButton extends StatelessWidget {
  const _AddPlayerButton({required this.used, required this.onSelected});

  final Set<int> used;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = [
      for (final option in cobPlayerColors)
        if (!used.contains(option.value)) option,
    ];
    if (remaining.length == 1) {
      return _PlayerCountButton(
        key: const ValueKey('cob-duchy-add-player'),
        tooltip: l10n.t('players.add'),
        icon: Icons.add,
        onPressed: () => onSelected(remaining.single.value),
      );
    }
    return PopupMenuButton<int>(
      key: const ValueKey('cob-duchy-add-player'),
      tooltip: l10n.t('players.add'),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in remaining)
          PopupMenuItem(
            value: option.value,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: playerColorOutline(option.value),
                      width: isLightPlayerColor(option.value) ? 1.5 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(l10n.colorLabel(option.name)),
              ],
            ),
          ),
      ],
      child: const _PlayerCircle(icon: Icons.add),
    );
  }
}

class _PlayerCountButton extends StatelessWidget {
  const _PlayerCountButton({
    super.key,
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: _PlayerCircle(icon: icon),
        ),
      ),
    );
  }
}

class _PlayerCircle extends StatelessWidget {
  const _PlayerCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = _CobDuchyRandomizerScreenState._accent;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Icon(icon, color: accent),
    );
  }
}

class _PoolChip extends StatelessWidget {
  const _PoolChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      key: chipKey,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: primary.withValues(alpha: 0.18),
      checkmarkColor: primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? primary : null,
      ),
    );
  }
}

class _DealGrid extends StatelessWidget {
  const _DealGrid({
    super.key,
    required this.deal,
    required this.compact,
    required this.settled,
    required this.labelAt,
    required this.rankAt,
    required this.highlightedAt,
    required this.colorAt,
  });

  final List<CobDuchyAssignment> deal;
  final bool compact;
  final bool settled;
  final String Function(int index) labelAt;
  final String? Function(int index) rankAt;
  final bool Function(int index) highlightedAt;
  final PlayerColorOption Function(int index) colorAt;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep every seated player on one row, even on narrow phones.
        final columns = deal.isEmpty ? 1 : deal.length;
        final gap = compact ? 6.0 : 12.0;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          key: ValueKey(
            settled ? 'cob-duchy-order-settled' : 'cob-duchy-order-spinning',
          ),
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < deal.length; i++)
              SizedBox(
                width: tileWidth,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _DuchyCard(
                    index: i,
                    assignment: deal[i],
                    label: labelAt(i),
                    rankLabel: rankAt(i),
                    highlighted: highlightedAt(i),
                    color: colorAt(i),
                    compact: compact,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DuchyCard extends StatelessWidget {
  const _DuchyCard({
    required this.index,
    required this.assignment,
    required this.label,
    required this.rankLabel,
    required this.highlighted,
    required this.color,
    required this.compact,
  });

  final int index;
  final CobDuchyAssignment assignment;
  final String label;
  final String? rankLabel;
  final bool highlighted;
  final PlayerColorOption color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final accent = _CobDuchyRandomizerScreenState._accent;
    final primary = scheme.primary;
    final wideNumber = assignment.boardId.length > 3;
    final semantics = l10n.t('cob.duchy.tileSemantics', {
      'id': assignment.boardId,
      'player': label,
    });
    return Semantics(
      label: rankLabel == null ? semantics : '$semantics, $rankLabel',
      child: AnimatedContainer(
        key: ValueKey('cob-duchy-card-$index'),
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted ? primary : accent.withValues(alpha: 0.28),
            width: highlighted ? 3.5 : 1.5,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.42),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 10 : 14,
                    height: compact ? 10 : 14,
                    decoration: BoxDecoration(
                      color: color.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: playerColorOutline(color.value),
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 4 : 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 11 : null,
                      ),
                    ),
                  ),
                  if (rankLabel != null) ...[
                    SizedBox(width: compact ? 4 : 6),
                    _RankChip(
                      key: ValueKey('cob-duchy-rank-$index'),
                      label: rankLabel!,
                      compact: compact,
                    ),
                  ],
                ],
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.t('cob.duchy.label'),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          assignment.boardId,
                          style:
                              (wideNumber
                                      ? Theme.of(
                                          context,
                                        ).textTheme.headlineMedium
                                      : Theme.of(
                                          context,
                                        ).textTheme.displaySmall)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    color: accent,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Visibility(
                        visible: assignment.isBeginner || assignment.isAdvanced,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              l10n.t(
                                assignment.isBeginner
                                    ? 'cob.duchy.beginner'
                                    : assignment.isAdvanced
                                    ? 'cob.duchy.advanced'
                                    : 'cob.duchy.beginner',
                              ),
                              style: TextStyle(
                                color: scheme.onTertiaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankChip extends StatelessWidget {
  const _RankChip({super.key, required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.2, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8,
            vertical: compact ? 2 : 3,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 9 : 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnPlaceSpin {
  const _TurnPlaceSpin({
    required this.cycle,
    required this.winner,
    required this.lockStep,
  });

  final List<int> cycle;
  final int winner;
  final int lockStep;
}
