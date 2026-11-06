import 'dart:ui' show Color;

part 'turing_challenge_bank.dart';

/// One printed sheet of the Offline Challenge Bank.
class TuringBankSheet {
  const TuringBankSheet({
    required this.number,
    required this.difficulty,
    required this.puzzles,
  });

  final int number;

  /// Difficulty factor of every puzzle on the sheet, 1–3.
  final int difficulty;
  final List<TuringPuzzle> puzzles;

  String get label => number.toString().padLeft(2, '0');
}

/// Verification cards come in four sets, each with its own colour and corner
/// icon. A puzzle uses cards from one set.
enum TuringCardSet {
  /// ◇ diamond.
  green(Color(0xFF3BAA4E), Color(0xFF1F6B33)),

  /// # hash.
  orange(Color(0xFFF0A030), Color(0xFFE08A12)),

  /// / slash.
  blue(Color(0xFF4BA3D6), Color(0xFF253A6B)),

  /// Square with spokes from its corners.
  purple(Color(0xFF8A62B3), Color(0xFF2E2A5E));

  const TuringCardSet(this.color, this.ink);

  /// Border and icon.
  final Color color;

  /// The card number, as printed.
  final Color ink;
}

/// One verifier's cards in a puzzle setup.
class TuringVerifierSetup {
  const TuringVerifierSetup(this.criteriaCard, this.verificationCard);

  /// Criteria card placed in front of the verifier.
  final int criteriaCard;

  /// Verification card placed face down next to it.
  final int verificationCard;
}

/// A puzzle to set up: one of the rulebook's 20, or one from the Offline
/// Challenge Bank.
class TuringPuzzle {
  const TuringPuzzle({
    required this.label,
    required this.cardSet,
    required this.difficulty,
    this.luck,
    required this.verifiers,
    required this.code,
    this.machineRounds,
    this.machineQuestions,
  });

  /// As printed: "01" in the rulebook, a code like "A41 AA5" in the bank.
  final String label;

  /// The Verification card set this puzzle's cards come from.
  final TuringCardSet cardSet;

  /// Difficulty factor, 1–3.
  final int difficulty;

  /// Luck, 1–3. Only the rulebook rates it.
  final int? luck;

  /// Verifiers A, B, C… in order.
  final List<TuringVerifierSetup> verifiers;

  /// The secret code as printed in SOLUTIONS: blue, yellow, purple.
  final String code;

  /// The bank's "Did you beat the machine?" score: the rounds and questions
  /// the machine needs.
  final int? machineRounds;
  final int? machineQuestions;

  /// The secret code: triangle, square, circle.
  List<int> get solution => [for (final c in code.split('')) int.parse(c)];

  /// [label] without spaces, for keys and search.
  String get key => label.replaceAll(' ', '');

  /// The Offline Challenge Bank #1: 16 sheets of puzzles.
  static final List<TuringBankSheet> challengeBank = [
    for (var i = 0; i < _challengeBankSheets.length; i++)
      TuringBankSheet(
        number: i + 1,
        difficulty: _challengeBankSheets[i].$1,
        puzzles: [
          for (final row in _challengeBankSheets[i].$2)
            TuringPuzzle._fromRow(row, _challengeBankSheets[i].$1),
        ],
      ),
  ];

  /// Parses a bank row: code | set | criteria:verification … | solution |
  /// rounds/questions.
  factory TuringPuzzle._fromRow(String row, int difficulty) {
    final parts = row.split('|');
    final machine = parts[4].split('/');
    return TuringPuzzle(
      label: parts[0],
      cardSet: switch (parts[1]) {
        'g' => TuringCardSet.green,
        'o' => TuringCardSet.orange,
        'b' => TuringCardSet.blue,
        _ => TuringCardSet.purple,
      },
      difficulty: difficulty,
      verifiers: [
        for (final pair in parts[2].split(' '))
          TuringVerifierSetup(
            int.parse(pair.split(':')[0]),
            int.parse(pair.split(':')[1]),
          ),
      ],
      code: parts[3],
      machineRounds: int.parse(machine[0]),
      machineQuestions: int.parse(machine[1]),
    );
  }

  static const rulebook = [
    TuringPuzzle(
      label: '01',
      code: '241',
      cardSet: TuringCardSet.green,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(4, 447),
        TuringVerifierSetup(9, 646),
        TuringVerifierSetup(11, 566),
        TuringVerifierSetup(14, 322),
      ],
    ),
    TuringPuzzle(
      label: '02',
      code: '435',
      cardSet: TuringCardSet.orange,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(3, 564),
        TuringVerifierSetup(7, 355),
        TuringVerifierSetup(10, 635),
        TuringVerifierSetup(14, 720),
      ],
    ),
    TuringPuzzle(
      label: '03',
      code: '331',
      cardSet: TuringCardSet.blue,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(4, 677),
        TuringVerifierSetup(9, 217),
        TuringVerifierSetup(13, 634),
        TuringVerifierSetup(17, 528),
      ],
    ),
    TuringPuzzle(
      label: '04',
      code: '345',
      cardSet: TuringCardSet.purple,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(3, 662),
        TuringVerifierSetup(8, 790),
        TuringVerifierSetup(15, 404),
        TuringVerifierSetup(16, 509),
      ],
    ),
    TuringPuzzle(
      label: '05',
      code: '354',
      cardSet: TuringCardSet.green,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(2, 413),
        TuringVerifierSetup(6, 532),
        TuringVerifierSetup(14, 596),
        TuringVerifierSetup(17, 537),
      ],
    ),
    TuringPuzzle(
      label: '06',
      code: '512',
      cardSet: TuringCardSet.blue,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(2, 437),
        TuringVerifierSetup(7, 405),
        TuringVerifierSetup(10, 378),
        TuringVerifierSetup(13, 797),
      ],
    ),
    TuringPuzzle(
      label: '07',
      code: '241',
      cardSet: TuringCardSet.green,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(8, 356),
        TuringVerifierSetup(12, 695),
        TuringVerifierSetup(15, 329),
        TuringVerifierSetup(17, 618),
      ],
    ),
    TuringPuzzle(
      label: '08',
      code: '423',
      cardSet: TuringCardSet.orange,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(3, 631),
        TuringVerifierSetup(5, 252),
        TuringVerifierSetup(9, 219),
        TuringVerifierSetup(15, 349),
        TuringVerifierSetup(16, 374),
      ],
    ),
    TuringPuzzle(
      label: '09',
      code: '344',
      cardSet: TuringCardSet.purple,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(1, 357),
        TuringVerifierSetup(7, 610),
        TuringVerifierSetup(10, 463),
        TuringVerifierSetup(12, 399),
        TuringVerifierSetup(17, 393),
      ],
    ),
    TuringPuzzle(
      label: '10',
      code: '242',
      cardSet: TuringCardSet.orange,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(2, 224),
        TuringVerifierSetup(6, 543),
        TuringVerifierSetup(8, 793),
        TuringVerifierSetup(12, 757),
        TuringVerifierSetup(15, 687),
      ],
    ),
    TuringPuzzle(
      label: '11',
      code: '325',
      cardSet: TuringCardSet.orange,
      difficulty: 1,
      luck: 3,
      verifiers: [
        TuringVerifierSetup(5, 445),
        TuringVerifierSetup(10, 639),
        TuringVerifierSetup(11, 289),
        TuringVerifierSetup(15, 406),
        TuringVerifierSetup(17, 484),
      ],
    ),
    TuringPuzzle(
      label: '12',
      code: '111',
      cardSet: TuringCardSet.purple,
      difficulty: 2,
      luck: 2,
      verifiers: [
        TuringVerifierSetup(4, 335),
        TuringVerifierSetup(9, 362),
        TuringVerifierSetup(18, 421),
        TuringVerifierSetup(20, 747),
      ],
    ),
    TuringPuzzle(
      label: '13',
      code: '111',
      cardSet: TuringCardSet.orange,
      difficulty: 2,
      luck: 2,
      verifiers: [
        TuringVerifierSetup(11, 279),
        TuringVerifierSetup(16, 515),
        TuringVerifierSetup(19, 770),
        TuringVerifierSetup(21, 523),
      ],
    ),
    TuringPuzzle(
      label: '14',
      code: '422',
      cardSet: TuringCardSet.purple,
      difficulty: 2,
      luck: 2,
      verifiers: [
        TuringVerifierSetup(2, 585),
        TuringVerifierSetup(13, 228),
        TuringVerifierSetup(17, 647),
        TuringVerifierSetup(20, 268),
      ],
    ),
    TuringPuzzle(
      label: '15',
      code: '253',
      cardSet: TuringCardSet.blue,
      difficulty: 2,
      luck: 2,
      verifiers: [
        TuringVerifierSetup(5, 763),
        TuringVerifierSetup(14, 598),
        TuringVerifierSetup(18, 223),
        TuringVerifierSetup(19, 317),
        TuringVerifierSetup(20, 520),
      ],
    ),
    TuringPuzzle(
      label: '16',
      code: '243',
      cardSet: TuringCardSet.green,
      difficulty: 2,
      luck: 2,
      verifiers: [
        TuringVerifierSetup(2, 778),
        TuringVerifierSetup(7, 654),
        TuringVerifierSetup(12, 614),
        TuringVerifierSetup(16, 640),
        TuringVerifierSetup(19, 751),
        TuringVerifierSetup(22, 485),
      ],
    ),
    TuringPuzzle(
      label: '17',
      code: '133',
      cardSet: TuringCardSet.blue,
      difficulty: 3,
      luck: 1,
      verifiers: [
        TuringVerifierSetup(21, 341),
        TuringVerifierSetup(31, 432),
        TuringVerifierSetup(37, 706),
        TuringVerifierSetup(39, 495),
      ],
    ),
    TuringPuzzle(
      label: '18',
      code: '331',
      cardSet: TuringCardSet.green,
      difficulty: 3,
      luck: 1,
      verifiers: [
        TuringVerifierSetup(23, 681),
        TuringVerifierSetup(28, 244),
        TuringVerifierSetup(41, 440),
        TuringVerifierSetup(48, 737),
      ],
    ),
    TuringPuzzle(
      label: '19',
      code: '224',
      cardSet: TuringCardSet.blue,
      difficulty: 3,
      luck: 1,
      verifiers: [
        TuringVerifierSetup(19, 237),
        TuringVerifierSetup(24, 353),
        TuringVerifierSetup(30, 204),
        TuringVerifierSetup(31, 423),
        TuringVerifierSetup(38, 606),
      ],
    ),
    TuringPuzzle(
      label: '20',
      code: '411',
      cardSet: TuringCardSet.purple,
      difficulty: 3,
      luck: 1,
      verifiers: [
        TuringVerifierSetup(11, 287),
        TuringVerifierSetup(22, 533),
        TuringVerifierSetup(30, 389),
        TuringVerifierSetup(33, 486),
        TuringVerifierSetup(34, 547),
        TuringVerifierSetup(40, 615),
      ],
    ),
  ];
}
