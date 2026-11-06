import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'turing_game.dart';
import 'turing_notes.dart';
import 'turing_puzzles.dart';

/// The rulebook's 20 puzzles and the Offline Challenge Bank, with the cards
/// each one is set up with.
class TuringPuzzlesScreen extends StatefulWidget {
  const TuringPuzzlesScreen({super.key});

  static const _green = TuringMachineGame.green;
  static const _tint = Color(0xFFE9F6EC);
  static const _gear = Color(0xFFB8782F);

  @override
  State<TuringPuzzlesScreen> createState() => _TuringPuzzlesScreenState();
}

class _TuringPuzzlesScreenState extends State<TuringPuzzlesScreen> {
  final _search = TextEditingController();
  var _bank = false;
  var _sheet = 0;
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _normalize(String text) =>
      text.replaceAll(RegExp(r'\s'), '').toUpperCase();

  List<TuringPuzzle> get _results {
    final query = _normalize(_query);
    return [
      for (final puzzle in [
        ...TuringPuzzle.rulebook,
        for (final sheet in TuringPuzzle.challengeBank) ...sheet.puzzles,
      ])
        if (puzzle.key.toUpperCase().contains(query)) puzzle,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searching = _query.trim().isNotEmpty;
    final sheet = TuringPuzzle.challengeBank[_sheet];
    final puzzles = searching
        ? _results
        : _bank
        ? sheet.puzzles
        : TuringPuzzle.rulebook;
    final intro = searching
        ? (puzzles.isEmpty
              ? l10n.t('turing.puzzles.noMatch')
              : l10n.t('turing.puzzles.matches', {
                  'count': '${puzzles.length}',
                }))
        : _bank
        ? l10n.t('turing.puzzles.bankIntro', {
            'sheet': sheet.label,
            'count': '${sheet.puzzles.length}',
            'verifiers': '${sheet.puzzles.first.verifiers.length}',
          })
        : l10n.t('turing.puzzles.intro');

    return AppPage(
      title: l10n.t('hub.puzzles'),
      coverImageAsset: TuringMachineGame.coverAsset,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < Breakpoints.compact;
          final padding = compact ? 12.0 : 20.0;
          final gap = compact ? 10.0 : 14.0;
          final columns = width < Breakpoints.compact
              ? 2
              : width < Breakpoints.medium
              ? 3
              : 4;
          final cardWidth =
              (width - padding * 2 - gap * (columns - 1)) / columns;
          return ListView(
            key: const ValueKey('turing-puzzles-list'),
            padding: EdgeInsets.all(padding),
            children: [
              TextField(
                key: const ValueKey('turing-puzzles-search'),
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: TuringPuzzlesScreen._green,
                  ),
                  suffixIcon: searching
                      ? IconButton(
                          tooltip: l10n.t('turing.puzzles.clearSearch'),
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  hintText: l10n.t('turing.puzzles.search'),
                  filled: true,
                  fillColor: TuringPuzzlesScreen._tint,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (!searching) ...[
                SizedBox(height: gap),
                SegmentedButton<bool>(
                  key: const ValueKey('turing-puzzles-source'),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: TuringPuzzlesScreen._green,
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l10n.t('turing.puzzles.rulebook')),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.grid_view_rounded),
                      label: Text(l10n.t('turing.puzzles.bank')),
                    ),
                  ],
                  selected: {_bank},
                  onSelectionChanged: (selection) =>
                      setState(() => _bank = selection.first),
                ),
                if (_bank) ...[
                  SizedBox(height: gap),
                  _SheetPicker(
                    selected: _sheet,
                    onSelected: (index) => setState(() => _sheet = index),
                  ),
                ],
              ],
              SizedBox(height: gap),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: TuringPuzzlesScreen._tint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: TuringPuzzlesScreen._green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          intro,
                          key: const ValueKey('turing-puzzles-intro'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gap + 4),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final puzzle in puzzles)
                    SizedBox(
                      // A new card per puzzle, so a flipped tile never
                      // carries over to another puzzle.
                      key: ObjectKey(puzzle),
                      width: cardWidth,
                      child: _PuzzleCard(puzzle: puzzle),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The bank's 16 sheets, each with its difficulty gears.
class _SheetPicker extends StatelessWidget {
  const _SheetPicker({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < TuringPuzzle.challengeBank.length; i++)
          Tooltip(
            message: l10n.t('turing.puzzles.difficulty', {
              'value': '${TuringPuzzle.challengeBank[i].difficulty}',
            }),
            child: ChoiceChip(
              key: ValueKey('turing-sheet-${i + 1}'),
              showCheckmark: false,
              selected: i == selected,
              onSelected: (_) => onSelected(i),
              selectedColor: TuringPuzzlesScreen._green,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TuringPuzzle.challengeBank[i].label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: i == selected ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (
                    var g = 0;
                    g < TuringPuzzle.challengeBank[i].difficulty;
                    g++
                  )
                    Icon(
                      Icons.settings_rounded,
                      size: 11,
                      color: i == selected
                          ? Colors.white
                          : TuringPuzzlesScreen._gear,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One puzzle tile. Hold it to flip it over and see the solution; tap the
/// back to flip it again.
class _PuzzleCard extends StatefulWidget {
  const _PuzzleCard({required this.puzzle});

  final TuringPuzzle puzzle;

  /// Long enough that a scroll or a stray press does not spoil the code.
  static const holdToFlip = Duration(milliseconds: 900);

  @override
  State<_PuzzleCard> createState() => _PuzzleCardState();
}

class _PuzzleCardState extends State<_PuzzleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _show() => _flip.forward();

  void _hide() => _flip.reverse();

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLowest;
    final front = _PuzzleFront(puzzle: widget.puzzle, surface: surface);
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
              () =>
                  LongPressGestureRecognizer(duration: _PuzzleCard.holdToFlip),
              (recognizer) => recognizer.onLongPress = _show,
            ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              TapGestureRecognizer.new,
              (recognizer) => recognizer.onTap = () {
                if (_flip.value > 0) {
                  _hide();
                }
              },
            ),
      },
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_flip.value);
          final showBack = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(t * math.pi),
            // The front keeps the tile's size; the back fills the same box.
            child: Stack(
              children: [
                Visibility(
                  visible: !showBack,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: front,
                ),
                if (showBack)
                  Positioned.fill(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(math.pi),
                      child: _PuzzleBack(
                        key: ValueKey('turing-solution-${widget.puzzle.key}'),
                        puzzle: widget.puzzle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PuzzleFront extends StatelessWidget {
  const _PuzzleFront({required this.puzzle, required this.surface});

  final TuringPuzzle puzzle;
  final Color surface;

  static const _green = TuringPuzzlesScreen._green;
  static const _gear = Color(0xFFB8782F);
  static const _clover = Color(0xFF1E7A3C);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final headStyle = TextStyle(
      color: muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    Widget rating(
      Widget Function(Color color) icon,
      Color color,
      int value,
      String tooltip,
    ) {
      return Tooltip(
        message: tooltip,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: icon(i < value ? color : color.withValues(alpha: 0.2)),
              ),
          ],
        ),
      );
    }

    return DecoratedBox(
      key: ValueKey('turing-puzzle-${puzzle.key}'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        // Card numbers read left to right, like the rulebook.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          puzzle.label,
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w900,
                            // Bank codes like "A41 AA5" are longer than "01".
                            fontSize: puzzle.label.length <= 2 ? 28 : 19,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      rating(
                        (color) => Icon(
                          Icons.settings_rounded,
                          size: 15,
                          color: color,
                        ),
                        _gear,
                        puzzle.difficulty,
                        l10n.t('turing.puzzles.difficulty', {
                          'value': '${puzzle.difficulty}',
                        }),
                      ),
                      if (puzzle.luck case final luck?) ...[
                        const SizedBox(height: 2),
                        rating(
                          (color) => CustomPaint(
                            size: const Size.square(15),
                            painter: _CloverPainter(color),
                          ),
                          _clover,
                          luck,
                          l10n.t('turing.puzzles.luck', {'value': '$luck'}),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 26),
                  Expanded(
                    child: Text(
                      l10n.t('turing.puzzles.criteria'),
                      textAlign: TextAlign.center,
                      style: headStyle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      l10n.t('turing.puzzles.verification'),
                      textAlign: TextAlign.center,
                      style: headStyle,
                    ),
                  ),
                ],
              ),
              for (var v = 0; v < puzzle.verifiers.length; v++)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 26,
                        child: Text(
                          TuringNotes.verifierLetters[v],
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _CriteriaBadge(
                            number: puzzle.verifiers[v].criteriaCard,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _VerificationBadge(
                            key: ValueKey(
                              'turing-verification-${puzzle.key}-$v',
                            ),
                            number: puzzle.verifiers[v].verificationCard,
                            set: puzzle.cardSet,
                            surface: surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The back of a tile: the puzzle's solution.
class _PuzzleBack extends StatelessWidget {
  const _PuzzleBack({super.key, required this.puzzle});

  final TuringPuzzle puzzle;

  static const _green = TuringPuzzlesScreen._green;

  /// Punch card colours: blue triangle, yellow square, purple circle.
  static const _colors = [
    Color(0xFF4FB0DE),
    Color(0xFFF8B81D),
    Color(0xFF8A62B3),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final digits = puzzle.solution;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Shrinks to fit the short 4-verifier tiles.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                puzzle.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: puzzle.label.length <= 2 ? 28 : 22,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.t('turing.puzzles.solution'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < digits.length; i++)
                      Container(
                        width: 40,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${digits[i]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (puzzle.machineRounds != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.t('turing.puzzles.machine', {
                    'rounds': '${puzzle.machineRounds}',
                    'questions': '${puzzle.machineQuestions}',
                  }),
                  key: ValueKey('turing-machine-${puzzle.key}'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                l10n.t('turing.puzzles.tapToHide'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriteriaBadge extends StatelessWidget {
  const _CriteriaBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TuringPuzzlesScreen._green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// A Verification card number, drawn like the card: a coloured outline with
/// the set's icon breaking the top-right corner.
class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({
    super.key,
    required this.number,
    required this.set,
    required this.surface,
  });

  final int number;
  final TuringCardSet set;

  /// Behind the icon, so it cuts through the outline.
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 46),
          padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: set.color, width: 2),
          ),
          child: Text(
            '$number',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: set.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: Container(
            color: surface,
            padding: const EdgeInsets.all(1.5),
            child: CustomPaint(
              size: const Size.square(12),
              painter: _CardSetIconPainter(set),
            ),
          ),
        ),
      ],
    );
  }
}

/// The corner icon of each Verification card set.
class _CardSetIconPainter extends CustomPainter {
  const _CardSetIconPainter(this.set);

  final TuringCardSet set;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final paint = Paint()
      ..color = set.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (set) {
      case TuringCardSet.green:
        canvas.drawPath(
          Path()
            ..moveTo(w / 2, w * 0.1)
            ..lineTo(w * 0.9, w / 2)
            ..lineTo(w / 2, w * 0.9)
            ..lineTo(w * 0.1, w / 2)
            ..close(),
          paint,
        );
      case TuringCardSet.orange:
        for (final t in [0.36, 0.64]) {
          canvas.drawLine(
            Offset(w * t, w * 0.1),
            Offset(w * t, w * 0.9),
            paint,
          );
          canvas.drawLine(
            Offset(w * 0.1, w * t),
            Offset(w * 0.9, w * t),
            paint,
          );
        }
      case TuringCardSet.blue:
        canvas.drawLine(
          Offset(w * 0.2, w * 0.9),
          Offset(w * 0.8, w * 0.1),
          paint,
        );
      case TuringCardSet.purple:
        canvas.drawRect(
          Rect.fromLTRB(w * 0.32, w * 0.32, w * 0.68, w * 0.68),
          paint,
        );
        for (final (x, y) in [(0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0)]) {
          final corner = Offset(w * (0.32 + 0.36 * x), w * (0.32 + 0.36 * y));
          final out = Offset(w * (0.08 + 0.84 * x), w * (0.08 + 0.84 * y));
          canvas.drawLine(corner, out, paint);
        }
    }
  }

  @override
  bool shouldRepaint(_CardSetIconPainter oldDelegate) => oldDelegate.set != set;
}

/// The rulebook's luck shamrock: three round leaves and a stem.
class _CloverPainter extends CustomPainter {
  const _CloverPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final fill = Paint()..color = color;
    final r = w * 0.22;
    canvas.drawCircle(Offset(w * 0.5, w * 0.26), r, fill);
    canvas.drawCircle(Offset(w * 0.26, w * 0.5), r, fill);
    canvas.drawCircle(Offset(w * 0.74, w * 0.5), r, fill);
    canvas.drawCircle(Offset(w * 0.5, w * 0.5), r * 0.8, fill);
    canvas.drawLine(
      Offset(w * 0.5, w * 0.55),
      Offset(w * 0.68, w * 0.95),
      Paint()
        ..color = color
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CloverPainter oldDelegate) => oldDelegate.color != color;
}
