import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n_scope.dart';
import '../../shared/export/png_save.dart';
import '../../shared/layout/breakpoints.dart';
import '../../shared/widgets/app_page.dart';
import 'turing_game.dart';
import 'turing_notes.dart';
import 'turing_sheet_image.dart';

/// Colors of the printed sheet.
class _Ink {
  static const green = TuringMachineGame.green;
  static const greenTint = Color(0xFFE9F6EC);
  static const red = Color(0xFFD64545);
  static const handicap = Color(0xFF5E6E64);
  static const blue = Color(0xFF4FB0DE);
  static const yellow = Color(0xFFF8B81D);
  static const purple = Color(0xFF8A62B3);

  static const shapes = [blue, yellow, purple];
}

enum _Shape { triangle, square, circle }

class TuringNoteSheetScreen extends StatefulWidget {
  const TuringNoteSheetScreen({super.key});

  @override
  State<TuringNoteSheetScreen> createState() => _TuringNoteSheetScreenState();
}

class _TuringNoteSheetScreenState extends State<TuringNoteSheetScreen> {
  TuringNotes? _notes;
  Timer? _saveTimer;
  var _savingImage = false;

  /// While on, taps on round 1 boxes fill them grey (handicap system).
  var _handicapMode = false;

  final _player = TextEditingController();
  final _problem = TextEditingController();
  final _noteControllers = List.generate(
    TuringNotes.verifiers,
    (_) => TextEditingController(),
  );
  final _criterionControllers = List.generate(
    TuringNotes.verifiers,
    (_) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    TuringNotesStore.load().then((notes) {
      if (!mounted) {
        return;
      }
      _fillControllers(notes);
      setState(() => _notes = notes);
    });
  }

  @override
  void dispose() {
    final notes = _notes;
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      if (notes != null) {
        TuringNotesStore.save(notes);
      }
    }
    _player.dispose();
    _problem.dispose();
    for (final controller in [..._noteControllers, ..._criterionControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _fillControllers(TuringNotes notes) {
    _player.text = notes.player;
    _problem.text = notes.problem;
    for (var i = 0; i < TuringNotes.verifiers; i++) {
      _noteControllers[i].text = notes.notes[i];
      _criterionControllers[i].text = notes.criteria[i];
    }
  }

  void _changed() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      final notes = _notes;
      if (notes != null) {
        TuringNotesStore.save(notes);
      }
    });
  }

  void _edit(void Function(TuringNotes notes) change) {
    final notes = _notes;
    if (notes == null) {
      return;
    }
    setState(() => change(notes));
    _changed();
  }

  void _say(String key) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.t(key))));
  }

  /// Whether a new answer may go in [round]: its proposal must be written,
  /// and a round holds at most 3 answers.
  bool _canAnswer(int round) {
    final notes = _notes!;
    if (!notes.hasProposal(round)) {
      _say('turing.needProposal');
      return false;
    }
    if (notes.questionsIn(round) >= TuringNotes.questionsPerRound) {
      _say('turing.limit');
      return false;
    }
    return true;
  }

  /// Tap cycles empty → ✗ → ✓ → empty. In handicap mode, taps fill grey.
  void _onResultTap(int round, int verifier) {
    if (_handicapMode) {
      _toggleHandicap(round, verifier);
      return;
    }
    final mark = _notes!.results[round][verifier];
    if (mark == VerifierMark.none && !_canAnswer(round)) {
      return;
    }
    _edit((n) {
      n.results[round][verifier] = switch (mark) {
        VerifierMark.none => VerifierMark.fail,
        VerifierMark.fail => VerifierMark.pass,
        VerifierMark.pass || VerifierMark.handicap => VerifierMark.none,
      };
    });
  }

  /// Hold marks ✓ straight away (or clears a ✓).
  void _onResultLongPress(int round, int verifier) {
    if (_handicapMode) {
      _toggleHandicap(round, verifier);
      return;
    }
    final mark = _notes!.results[round][verifier];
    if (mark == VerifierMark.none && !_canAnswer(round)) {
      return;
    }
    _edit((n) {
      n.results[round][verifier] = mark == VerifierMark.pass
          ? VerifierMark.none
          : VerifierMark.pass;
    });
  }

  /// Digits: tap cycles empty → ✗ → ✓ (circled) → empty; hold gives ✓.
  /// Nothing can be deduced before the first proposal.
  void _onDigit(int shape, int digit, {bool hold = false}) {
    final notes = _notes!;
    final mark = notes.digits[shape][digit];
    if (mark == DigitMark.none &&
        !List.generate(TuringNotes.rounds, notes.hasProposal).contains(true)) {
      _say('turing.needProposalDigits');
      return;
    }
    _edit((n) {
      n.digits[shape][digit] = hold
          ? (mark == DigitMark.circled ? DigitMark.none : DigitMark.circled)
          : switch (mark) {
              DigitMark.none => DigitMark.crossed,
              DigitMark.crossed => DigitMark.circled,
              DigitMark.circled => DigitMark.none,
            };
    });
  }

  /// Handicap: an experienced player fills up to 2 boxes, in round 1 only.
  void _toggleHandicap(int round, int verifier) {
    final notes = _notes!;
    if (round != 0) {
      _say('turing.handicap.firstRound');
      return;
    }
    final mark = notes.results[round][verifier];
    if (mark != VerifierMark.handicap) {
      final handicaps = notes.results[round]
          .where((m) => m == VerifierMark.handicap)
          .length;
      if (!notes.hasProposal(round)) {
        _say('turing.needProposal');
        return;
      }
      if (handicaps >= TuringNotes.maxHandicap) {
        _say('turing.handicap.max');
        return;
      }
      if (mark == VerifierMark.none &&
          notes.questionsIn(round) >= TuringNotes.questionsPerRound) {
        _say('turing.limit');
        return;
      }
    }
    _edit((n) {
      n.results[round][verifier] = mark == VerifierMark.handicap
          ? VerifierMark.none
          : VerifierMark.handicap;
    });
  }

  /// Writes the notes onto the printed sheet and saves it as a PNG.
  Future<void> _saveImage() async {
    final notes = _notes;
    if (notes == null || _savingImage) {
      return;
    }
    setState(() => _savingImage = true);
    try {
      final bytes = await TuringSheetImage.render(notes);
      await savePng(
        bytes,
        scoreSheetPngName(
          gameId: TuringMachineGame.idValue,
          now: DateTime.now(),
        ),
      );
      if (mounted) {
        _say('turing.saveImageSaved');
      }
    } catch (_) {
      if (mounted) {
        _say('turing.saveImageFailed');
      }
    } finally {
      if (mounted) {
        setState(() => _savingImage = false);
      }
    }
  }

  Future<void> _confirmClear() async {
    final l10n = context.l10n;
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('turing.clear.title')),
        content: Text(l10n.t('turing.clear.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('turing.clear.cancel')),
          ),
          FilledButton(
            key: const ValueKey('turing-clear-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('turing.clear.confirm')),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) {
      return;
    }
    final fresh = TuringNotes();
    _fillControllers(fresh);
    setState(() => _notes = fresh);
    _saveTimer?.cancel();
    await TuringNotesStore.save(fresh);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notes = _notes;
    return AppPage(
      title: l10n.t('hub.noteSheet'),
      coverImageAsset: TuringMachineGame.coverAsset,
      actions: [
        IconButton(
          key: const ValueKey('turing-save-image'),
          tooltip: l10n.t('play.saveImage'),
          icon: _savingImage
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.image_outlined),
          onPressed: notes == null || _savingImage ? null : _saveImage,
        ),
        IconButton(
          key: const ValueKey('turing-clear'),
          tooltip: l10n.t('turing.clear.tooltip'),
          icon: const Icon(Icons.restart_alt),
          onPressed: notes == null ? null : _confirmClear,
        ),
      ],
      body: notes == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < Breakpoints.compact;
                final padding = compact ? 12.0 : 20.0;
                final gap = compact ? 12.0 : 20.0;
                final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                );
                return ListView(
                  padding: EdgeInsets.all(padding),
                  children: [
                    _HeaderFields(
                      player: _player,
                      problem: _problem,
                      onPlayerChanged: (value) =>
                          _edit((n) => n.player = value),
                      onProblemChanged: (value) =>
                          _edit((n) => n.problem = value),
                    ),
                    SizedBox(height: gap),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _VerifierCountPicker(
                            count: notes.verifierCount,
                            onChanged: (count) =>
                                _edit((n) => n.verifierCount = count),
                            trailing: _HandicapToggle(
                              on: _handicapMode,
                              onChanged: (on) =>
                                  setState(() => _handicapMode = on),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _TopGrids(
                            notes: notes,
                            compact: compact,
                            onCode: (round, shape, digit) =>
                                _edit((n) => n.codes[round][shape] = digit),
                            onResult: _onResultTap,
                            onResultLongPress: _onResultLongPress,
                            onDigit: _onDigit,
                          ),
                          const SizedBox(height: 12),
                          _Tally(notes: notes),
                          const SizedBox(height: 10),
                          Text(
                            l10n.t('turing.hint'),
                            textAlign: TextAlign.center,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: gap),
                    _CriteriaNotes(
                      compact: compact,
                      count: notes.verifierCount,
                      notes: _noteControllers,
                      criteria: _criterionControllers,
                      onChanged: () => _edit((n) {
                        for (var i = 0; i < TuringNotes.verifiers; i++) {
                          n.notes[i] = _noteControllers[i].text;
                          n.criteria[i] = _criterionControllers[i].text;
                        }
                      }),
                    ),
                    SizedBox(height: gap),
                    _FinalCodePanel(
                      code: notes.finalCode,
                      onDigit: (shape, digit) =>
                          _edit((n) => n.finalCode[shape] = digit),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Ink.green.withValues(alpha: 0.25)),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _HeaderFields extends StatelessWidget {
  const _HeaderFields({
    required this.player,
    required this.problem,
    required this.onPlayerChanged,
    required this.onProblemChanged,
  });

  final TextEditingController player;
  final TextEditingController problem;
  final ValueChanged<String> onPlayerChanged;
  final ValueChanged<String> onProblemChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    InputDecoration decoration(IconData icon, String hint) => InputDecoration(
      prefixIcon: Icon(icon, color: _Ink.green),
      hintText: hint,
      filled: true,
      fillColor: _Ink.greenTint,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            key: const ValueKey('turing-player'),
            controller: player,
            textInputAction: TextInputAction.next,
            decoration: decoration(Icons.person, l10n.t('turing.player')),
            onChanged: onPlayerChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TextField(
            key: const ValueKey('turing-problem'),
            controller: problem,
            decoration: decoration(Icons.tag, l10n.t('turing.problem')),
            onChanged: onProblemChanged,
          ),
        ),
      ],
    );
  }
}

/// Handicap system: while on, taps on round 1 boxes fill them grey.
class _HandicapToggle extends StatelessWidget {
  const _HandicapToggle({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton(
      key: const ValueKey('turing-handicap-mode'),
      tooltip:
          '${l10n.t('turing.handicap.title')}: '
          '${l10n.t('turing.handicap.subtitle')}',
      isSelected: on,
      onPressed: () => onChanged(!on),
      visualDensity: VisualDensity.compact,
      style:
          IconButton.styleFrom(
            foregroundColor: _Ink.handicap,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            side: const BorderSide(color: _Ink.handicap, width: 1.4),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? _Ink.handicap
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : _Ink.handicap,
            ),
          ),
      icon: const Icon(Icons.balance_rounded, size: 20),
    );
  }
}

class _VerifierCountPicker extends StatelessWidget {
  const _VerifierCountPicker({
    required this.count,
    required this.onChanged,
    required this.trailing,
  });

  final int count;
  final ValueChanged<int> onChanged;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.l10n.t('turing.verifiers'),
            style: const TextStyle(
              color: _Ink.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SegmentedButton<int>(
          key: const ValueKey('turing-verifier-count'),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: _Ink.green,
            selectedForegroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          segments: [
            for (
              var n = TuringNotes.minVerifiers;
              n <= TuringNotes.verifiers;
              n++
            )
              ButtonSegment(
                value: n,
                label: Text(
                  'A–${TuringNotes.verifierLetters[n - 1]}',
                  key: ValueKey('turing-verifiers-$n'),
                ),
              ),
          ],
          selected: {count},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.notes});

  final TuringNotes notes;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(IconData icon, String text, Key key) => DecoratedBox(
      decoration: BoxDecoration(
        color: _Ink.greenTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _Ink.green),
            const SizedBox(width: 6),
            Text(
              text,
              key: key,
              style: const TextStyle(
                color: _Ink.green,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(
          Icons.replay_rounded,
          l10n.t('turing.rounds', {'count': '${notes.roundsPlayed}'}),
          const ValueKey('turing-rounds'),
        ),
        chip(
          Icons.help_outline_rounded,
          l10n.t('turing.questions', {'count': '${notes.questions}'}),
          const ValueKey('turing-questions'),
        ),
      ],
    );
  }
}

/// Code proposals, verifier results and the digit elimination grid.
class _TopGrids extends StatelessWidget {
  const _TopGrids({
    required this.notes,
    required this.compact,
    required this.onCode,
    required this.onResult,
    required this.onResultLongPress,
    required this.onDigit,
  });

  final TuringNotes notes;
  final bool compact;
  final void Function(int round, int shape, int? digit) onCode;
  final void Function(int round, int verifier) onResult;
  final void Function(int round, int verifier) onResultLongPress;
  final void Function(int shape, int digit, {bool hold}) onDigit;

  @override
  Widget build(BuildContext context) {
    // The printed sheet reads left to right in every language.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          Widget table(double cell) => _RoundsTable(
            notes: notes,
            cell: cell,
            onCode: onCode,
            onResult: onResult,
            onResultLongPress: onResultLongPress,
          );
          // 3 code columns + 6 verifier columns + a gap between them.
          final cell = math.min(compact ? 44.0 : 48.0, (width - 12) / 9);
          // The digit grid sits below, as wide as the table: a shape icon
          // and 5 digits per row.
          final tableWidth = cell * 9 + 12;
          final digitCell = math.min(
            46.0,
            (tableWidth - _DigitsPanel.padding * 2 - 3.2) / 6 * 0.85,
          );
          return Column(
            children: [
              table(cell),
              const SizedBox(height: 16),
              _DigitsPanel(notes: notes, cell: digitCell, onDigit: onDigit),
            ],
          );
        },
      ),
    );
  }
}

class _RoundsTable extends StatelessWidget {
  const _RoundsTable({
    required this.notes,
    required this.cell,
    required this.onCode,
    required this.onResult,
    required this.onResultLongPress,
  });

  final TuringNotes notes;
  final double cell;
  final void Function(int round, int shape, int? digit) onCode;
  final void Function(int round, int verifier) onResult;
  final void Function(int round, int verifier) onResultLongPress;

  static const _codeGap = 12.0;

  @override
  Widget build(BuildContext context) {
    const divider = BorderSide(color: _Ink.green, width: 1.2);
    final letterStyle = TextStyle(
      color: _Ink.green,
      fontWeight: FontWeight.w900,
      fontSize: cell * 0.5,
    );
    final active = notes.verifierCount;

    Widget header() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final shape in _Shape.values)
            SizedBox(
              width: cell,
              height: cell,
              child: Center(
                child: _ShapeIcon(shape: shape, size: cell * 0.6),
              ),
            ),
          const SizedBox(width: _codeGap),
          for (var v = 0; v < TuringNotes.verifiers; v++)
            Container(
              width: cell,
              height: cell,
              alignment: Alignment.center,
              decoration: v >= 4 ? _tintColumn(top: true) : null,
              child: Text(
                TuringNotes.verifierLetters[v],
                style: v < active
                    ? letterStyle
                    : letterStyle.copyWith(
                        color: _Ink.green.withValues(alpha: 0.3),
                      ),
              ),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header(),
        for (var round = 0; round < TuringNotes.rounds; round++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var shape = 0; shape < TuringNotes.shapes; shape++)
                Container(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    border: Border(
                      top: divider,
                      left: shape == 0 ? BorderSide.none : divider,
                    ),
                  ),
                  child: _CodeCell(
                    key: ValueKey('turing-code-$round-$shape'),
                    digit: notes.codes[round][shape],
                    color: _Ink.shapes[shape],
                    size: cell,
                    onSelected: (digit) => onCode(round, shape, digit),
                  ),
                ),
              const SizedBox(width: _codeGap),
              for (var v = 0; v < TuringNotes.verifiers; v++)
                Container(
                  width: cell,
                  height: cell,
                  decoration: v >= 4
                      ? _tintColumn(bottom: round == TuringNotes.rounds - 1)
                      : null,
                  child: v < active
                      ? _VerifierBox(
                          key: ValueKey('turing-result-$round-$v'),
                          mark: notes.results[round][v],
                          size: cell,
                          // A full round leaves its empty boxes faded.
                          faded:
                              notes.questionsIn(round) >=
                              TuringNotes.questionsPerRound,
                          onTap: () => onResult(round, v),
                          onLongPress: () => onResultLongPress(round, v),
                        )
                      : _StruckBox(
                          key: ValueKey('turing-struck-$round-$v'),
                          size: cell,
                        ),
                ),
            ],
          ),
      ],
    );
  }

  BoxDecoration _tintColumn({bool top = false, bool bottom = false}) {
    const r = Radius.circular(8);
    return BoxDecoration(
      color: _Ink.greenTint,
      borderRadius: BorderRadius.only(
        topLeft: top ? r : Radius.zero,
        topRight: top ? r : Radius.zero,
        bottomLeft: bottom ? r : Radius.zero,
        bottomRight: bottom ? r : Radius.zero,
      ),
      border: const Border.symmetric(
        vertical: BorderSide(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class _CodeCell extends StatelessWidget {
  const _CodeCell({
    super.key,
    required this.digit,
    required this.color,
    required this.size,
    required this.onSelected,
  });

  final int? digit;
  final Color color;
  final double size;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 56, maxWidth: 72),
      onSelected: (value) => onSelected(value == 0 ? null : value),
      itemBuilder: (context) => [
        for (var d = 1; d <= TuringNotes.digitCount; d++)
          PopupMenuItem<int>(
            value: d,
            height: 40,
            child: Center(
              child: Text(
                '$d',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        const PopupMenuItem<int>(
          value: 0,
          height: 40,
          child: Center(child: Icon(Icons.backspace_outlined, size: 20)),
        ),
      ],
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: digit == null
              ? null
              : Text(
                  '$digit',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.55,
                  ),
                ),
        ),
      ),
    );
  }
}

class _VerifierBox extends StatelessWidget {
  const _VerifierBox({
    super.key,
    required this.mark,
    required this.size,
    required this.faded,
    required this.onTap,
    required this.onLongPress,
  });

  final VerifierMark mark;
  final double size;
  final bool faded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final box = size * 0.66;
    final (fill, border, icon) = switch (mark) {
      VerifierMark.none => (Colors.white, _Ink.green, null),
      VerifierMark.pass => (_Ink.green, _Ink.green, Icons.check_rounded),
      VerifierMark.fail => (_Ink.red, _Ink.red, Icons.close_rounded),
      VerifierMark.handicap => (_Ink.handicap, _Ink.handicap, null),
    };
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: const CircleBorder(),
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: faded && mark == VerifierMark.none ? 0.3 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: box,
            height: box,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(box * 0.22),
              border: Border.all(color: border, width: 1.6),
            ),
            child: icon == null
                ? null
                : Icon(icon, color: Colors.white, size: box * 0.8),
          ),
        ),
      ),
    );
  }
}

/// An unused verifier column, struck through like on paper.
class _StruckBox extends StatelessWidget {
  const _StruckBox({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final box = size * 0.66;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(box * 0.22),
            border: Border.all(
              color: _Ink.green.withValues(alpha: 0.25),
              width: 1.6,
            ),
          ),
        ),
        Container(
          width: 2.5,
          height: size,
          color: _Ink.green.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _DigitsPanel extends StatelessWidget {
  const _DigitsPanel({
    required this.notes,
    required this.cell,
    required this.onDigit,
  });

  final TuringNotes notes;
  final double cell;
  final void Function(int shape, int digit, {bool hold}) onDigit;

  /// Horizontal padding inside the border, on each side.
  static const padding = 8.0;

  /// One row per shape: its icon, then the digits 1 to 5.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: padding, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Ink.green, width: 1.6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var shape = 0; shape < TuringNotes.shapes; shape++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: cell,
                  height: cell,
                  child: Center(
                    child: _ShapeIcon(
                      shape: _Shape.values[shape],
                      size: cell * 0.55,
                    ),
                  ),
                ),
                for (var digit = 1; digit <= TuringNotes.digitCount; digit++)
                  _DigitCell(
                    key: ValueKey('turing-digit-$shape-$digit'),
                    digit: digit,
                    mark: notes.digits[shape][digit - 1],
                    size: cell,
                    onTap: () => onDigit(shape, digit - 1),
                    onLongPress: () => onDigit(shape, digit - 1, hold: true),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DigitCell extends StatelessWidget {
  const _DigitCell({
    super.key,
    required this.digit,
    required this.mark,
    required this.size,
    required this.onTap,
    required this.onLongPress,
  });

  final int digit;
  final DigitMark mark;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final crossed = mark == DigitMark.crossed;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (mark == DigitMark.circled)
              Container(
                width: size * 0.82,
                height: size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _Ink.green.withValues(alpha: 0.12),
                  border: Border.all(color: _Ink.green, width: 2.2),
                ),
              ),
            Text(
              '$digit',
              style: TextStyle(
                color: crossed ? _Ink.green.withValues(alpha: 0.3) : _Ink.green,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.52,
              ),
            ),
            if (crossed)
              Icon(Icons.close_rounded, color: _Ink.red, size: size * 0.82),
          ],
        ),
      ),
    );
  }
}

class _ShapeIcon extends StatelessWidget {
  const _ShapeIcon({required this.shape, required this.size});

  final _Shape shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _ShapePainter(shape));
  }
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.shape);

  final _Shape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _Ink.shapes[shape.index];
    final rect = Offset.zero & size;
    switch (shape) {
      case _Shape.triangle:
        final path = Path()
          ..moveTo(size.width / 2, size.height * 0.04)
          ..lineTo(size.width, size.height * 0.92)
          ..lineTo(0, size.height * 0.92)
          ..close();
        canvas.drawPath(path, paint);
      case _Shape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(size.width * 0.06),
            Radius.circular(size.width * 0.08),
          ),
          paint,
        );
      case _Shape.circle:
        canvas.drawCircle(rect.center, size.width / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) => oldDelegate.shape != shape;
}

/// One box per verifier in play: free notes plus the deduced criterion.
class _CriteriaNotes extends StatelessWidget {
  const _CriteriaNotes({
    required this.compact,
    required this.count,
    required this.notes,
    required this.criteria,
    required this.onChanged,
  });

  final bool compact;
  final int count;
  final List<TextEditingController> notes;
  final List<TextEditingController> criteria;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 8.0 : 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var v = 0; v < count; v++)
              SizedBox(
                width: width,
                child: _CriterionCard(
                  letter: TuringNotes.verifierLetters[v],
                  index: v,
                  notes: notes[v],
                  criterion: criteria[v],
                  onChanged: onChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CriterionCard extends StatelessWidget {
  const _CriterionCard({
    required this.letter,
    required this.index,
    required this.notes,
    required this.criterion,
    required this.onChanged,
  });

  final String letter;
  final int index;
  final TextEditingController notes;
  final TextEditingController criterion;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            letter,
            style: const TextStyle(
              color: _Ink.green,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          TextField(
            key: ValueKey('turing-notes-$index'),
            controller: notes,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText: l10n.t('turing.notesHint'),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _Ink.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: ValueKey('turing-criterion-$index'),
                  controller: criterion,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    hintText: l10n.t('turing.criterionHint'),
                    filled: true,
                    fillColor: _Ink.greenTint,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The code a player commits to when they point their thumb up. Folded by
/// default, since the code is written secretly.
class _FinalCodePanel extends StatelessWidget {
  const _FinalCodePanel({required this.code, required this.onDigit});

  final List<int?> code;
  final void Function(int shape, int? digit) onDigit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const cell = 52.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Ink.green.withValues(alpha: 0.25)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const ValueKey('turing-final-toggle'),
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          iconColor: _Ink.green,
          collapsedIconColor: _Ink.green,
          leading: const Icon(Icons.key_rounded, color: _Ink.green),
          title: Text(
            l10n.t('turing.finalCode.title'),
            style: const TextStyle(
              color: _Ink.green,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            Text(
              l10n.t('turing.finalCode.hint'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final shape in _Shape.values) ...[
                    if (shape.index > 0) const SizedBox(width: 10),
                    Column(
                      children: [
                        _ShapeIcon(shape: shape, size: 22),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _Ink.shapes[shape.index],
                              width: 2,
                            ),
                          ),
                          child: _CodeCell(
                            key: ValueKey('turing-final-${shape.index}'),
                            digit: code[shape.index],
                            color: _Ink.shapes[shape.index],
                            size: cell,
                            onSelected: (digit) => onDigit(shape.index, digit),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
