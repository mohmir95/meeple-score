import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'project_l_game.dart';

/// Setup numbers from Project L rulebook 2.5.
class ProjectLSetup {
  const ProjectLSetup._();

  static const whitePuzzles = 32;
  static const faceUpPerRow = 4;

  static int blackPuzzles(int players) => const {2: 12, 3: 14, 4: 16}[players]!;

  /// The original base game: 2–4 players (4 player mats).
  static const playerCounts = [2, 3, 4];
}

// Dark panels echo the black pages of the rulebook.
const _panel = Color(0xFF11161B);
const _ink = Color(0xFFE8EEF2);
const _muted = Color(0xFF9AA8B4);
const _level1 = Color(0xFFFFD60A);
const _level2 = Color(0xFF1FA34A);

const _monomino = [(0, 0)];
const _domino = [(0, 0), (0, 1)];

class ProjectLSetupHintsScreen extends StatefulWidget {
  const ProjectLSetupHintsScreen({super.key});

  @override
  State<ProjectLSetupHintsScreen> createState() =>
      _ProjectLSetupHintsScreenState();
}

class _ProjectLSetupHintsScreenState extends State<ProjectLSetupHintsScreen> {
  var _players = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.compact;
    final padding = compact ? 12.0 : 20.0;
    final gap = SizedBox(height: compact ? 16 : 20);

    return AppPage(
      title: l10n.t('hub.setupHints'),
      coverImageAsset: ProjectLGame.coverAsset,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  key: const ValueKey('project-l-setup-players'),
                  showSelectedIcon: false,
                  segments: [
                    for (final n in ProjectLSetup.playerCounts)
                      ButtonSegment(
                        value: n,
                        label: Text(
                          l10n.t('projectL.setup.players', {'n': '$n'}),
                        ),
                      ),
                  ],
                  selected: {_players},
                  onSelectionChanged: (selection) {
                    setState(() => _players = selection.first);
                  },
                ),
                gap,
                _puzzlesPanel(context, compact),
                gap,
                _piecesPanel(context, compact),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _puzzlesPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final black = ProjectLSetup.blackPuzzles(_players);
    const right = ProjectLSetup.faceUpPerRow;
    const cardWidth = 46.0;

    Widget row({required bool white, required int count}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Deck(
            white: white,
            width: cardWidth,
            count: count,
            label: l10n.t(
              white ? 'projectL.setup.white' : 'projectL.setup.black',
            ),
          ),
          const SizedBox(width: 6),
          for (var i = 0; i < right; i++) ...[
            const SizedBox(width: 8),
            const _PuzzleCard(width: cardWidth),
          ],
        ],
      );
    }

    return _Panel(
      key: const ValueKey('project-l-setup-puzzles'),
      compact: compact,
      title: l10n.t('projectL.setup.puzzlesTitle', {'n': '$black'}),
      body: l10n.t('projectL.setup.puzzlesBody', {'n': '$black'}),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            row(white: true, count: ProjectLSetup.whitePuzzles),
            const SizedBox(height: 14),
            row(white: false, count: black),
          ],
        ),
      ),
    );
  }

  Widget _piecesPanel(BuildContext context, bool compact) {
    final l10n = context.l10n;
    final cell = compact ? 22.0 : 28.0;

    Widget piece(int level, List<(int, int)> cells, Color color) {
      return Expanded(
        child: Column(
          key: ValueKey('project-l-setup-level-$level'),
          children: [
            SizedBox(
              height: cell * 2,
              child: Center(
                child: _Piece(cells: cells, color: color, cell: cell),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '× $_players',
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 20 : 24,
              ),
            ),
            Text(
              l10n.t('projectL.setup.level', {'n': '$level'}),
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return _Panel(
      key: const ValueKey('project-l-setup-pieces'),
      compact: compact,
      title: l10n.t('projectL.setup.piecesTitle'),
      body: l10n.t('projectL.setup.piecesBody'),
      child: Row(
        children: [piece(1, _monomino, _level1), piece(2, _domino, _level2)],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.compact,
    required this.title,
    required this.body,
    required this.child,
  });

  final bool compact;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const accent = ProjectLGame.cyan;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A cyan rule under the title, like the rulebook section headers.
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: accent, width: 2)),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 16 : 24,
              vertical: compact ? 10 : 12,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: _ink, height: 1.4),
                ),
                SizedBox(height: compact ? 14 : 18),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A piece drawn as square cells, `(x, y)` from the top left.
class _Piece extends StatelessWidget {
  const _Piece({required this.cells, required this.color, required this.cell});

  final List<(int, int)> cells;
  final Color color;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final cols = cells.map((c) => c.$1).reduce(math.max) + 1;
    final rows = cells.map((c) => c.$2).reduce(math.max) + 1;
    final edge = Color.lerp(color, Colors.black, 0.25)!;
    return SizedBox(
      width: cols * cell,
      height: rows * cell,
      child: Stack(
        children: [
          for (final (x, y) in cells)
            Positioned(
              left: x * cell,
              top: y * cell,
              width: cell,
              height: cell,
              child: Container(
                margin: EdgeInsets.all(cell * 0.03),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(cell * 0.12),
                  border: Border.all(color: edge),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A face-down puzzle deck with its size underneath.
class _Deck extends StatelessWidget {
  const _Deck({
    required this.white,
    required this.width,
    required this.count,
    required this.label,
  });

  final bool white;
  final double width;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final face = white ? const Color(0xFFF2F5F7) : const Color(0xFF05070A);
    final edge = white ? const Color(0xFFB8C0C8) : const Color(0xFF59636E);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: width * 1.3,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(width * 0.1),
            border: Border.all(color: edge, width: 1.5),
            boxShadow: [
              BoxShadow(color: edge, offset: const Offset(3, 3)),
              BoxShadow(
                color: Color.lerp(edge, Colors.black, 0.4)!,
                offset: const Offset(6, 6),
              ),
            ],
          ),
          child: Text(
            'L',
            style: TextStyle(
              fontSize: width * 0.55,
              fontWeight: FontWeight.w900,
              color: white ? const Color(0xFFCDD3D8) : const Color(0xFF2A333B),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '× $count',
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// A face-up puzzle: black card with a white recessed area.
class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.3,
      padding: EdgeInsets.all(width * 0.16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(width * 0.1),
        border: Border.all(color: Colors.white70, width: 1.2),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: 0.6,
          heightFactor: 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
              const Expanded(child: ColoredBox(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
