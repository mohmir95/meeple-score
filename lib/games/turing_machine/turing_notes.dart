import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/json_values.dart';

/// A box in the verifier grid: untested, passed or failed. [handicap] is a
/// box an experienced player fills in round 1 to give up a question.
enum VerifierMark { none, pass, fail, handicap }

/// A digit in the elimination grid: open, ruled out or confirmed.
enum DigitMark { none, crossed, circled }

/// Everything written on one Turing Machine note sheet.
class TuringNotes {
  TuringNotes({
    this.player = '',
    this.problem = '',
    this.verifierCount = minVerifiers,
    List<int?>? finalCode,
    List<List<int?>>? codes,
    List<List<VerifierMark>>? results,
    List<List<DigitMark>>? digits,
    List<String>? notes,
    List<String>? criteria,
  }) : codes = codes ?? _grid(rounds, shapes, null),
       results = results ?? _grid(rounds, verifiers, VerifierMark.none),
       digits = digits ?? _grid(shapes, digitCount, DigitMark.none),
       notes = notes ?? List.filled(verifiers, '', growable: false),
       criteria = criteria ?? List.filled(verifiers, '', growable: false),
       finalCode = finalCode ?? List<int?>.filled(shapes, null);

  /// A round may question at most this many verifiers.
  static const questionsPerRound = 3;

  /// A round can only be answered once its proposal is fully written.
  bool hasProposal(int round) => codes[round].every((digit) => digit != null);

  /// The handicap system fills at most 2 boxes, in round 1 only.
  static const maxHandicap = 2;

  /// Problems use 4 to 6 verifiers; E and F are struck out when unused.
  static const minVerifiers = 4;

  /// Rows on the printed sheet: one code proposal per round.
  static const rounds = 9;

  /// Blue triangle, yellow square, purple circle.
  static const shapes = 3;

  /// Verifiers A–F.
  static const verifiers = 6;
  static const verifierLetters = ['A', 'B', 'C', 'D', 'E', 'F'];

  /// Each code digit is 1–5.
  static const digitCount = 5;

  String player;
  String problem;

  /// Verifiers in play (4–6). Columns past this are struck out.
  int verifierCount;

  /// The code the player commits to at the end of the game.
  final List<int?> finalCode;

  int questionsIn(int round) =>
      results[round].where((mark) => mark != VerifierMark.none).length;

  /// Every answer box filled in so far; fewest questions wins a tie.
  int get questions => [
    for (var r = 0; r < rounds; r++) questionsIn(r),
  ].fold(0, (sum, count) => sum + count);

  /// Rounds with a proposal or an answer written on them.
  int get roundsPlayed {
    for (var r = rounds - 1; r >= 0; r--) {
      if (questionsIn(r) > 0 || codes[r].any((digit) => digit != null)) {
        return r + 1;
      }
    }
    return 0;
  }

  /// [round][shape] → proposed digit, or null when blank.
  final List<List<int?>> codes;

  /// [round][verifier] → result of testing that verifier.
  final List<List<VerifierMark>> results;

  /// [shape][digit - 1] → elimination mark.
  final List<List<DigitMark>> digits;

  /// Free notes per verifier.
  final List<String> notes;

  /// The criterion the player has deduced per verifier.
  final List<String> criteria;

  bool get isEmpty =>
      player.isEmpty &&
      problem.isEmpty &&
      codes.every((row) => row.every((digit) => digit == null)) &&
      results.every((row) => row.every((m) => m == VerifierMark.none)) &&
      digits.every((row) => row.every((m) => m == DigitMark.none)) &&
      notes.every((note) => note.isEmpty) &&
      criteria.every((note) => note.isEmpty) &&
      finalCode.every((digit) => digit == null) &&
      verifierCount == minVerifiers;

  static List<List<T>> _grid<T>(int rows, int columns, T value) => [
    for (var r = 0; r < rows; r++) List<T>.filled(columns, value),
  ];

  Map<String, dynamic> toJson() => {
    'player': player,
    'problem': problem,
    'codes': codes,
    'results': [
      for (final row in results) [for (final mark in row) mark.index],
    ],
    'digits': [
      for (final row in digits) [for (final mark in row) mark.index],
    ],
    'notes': notes,
    'criteria': criteria,
    'verifierCount': verifierCount,
    'finalCode': finalCode,
  };

  factory TuringNotes.fromJson(Map<String, dynamic> json) {
    List<List<T>> grid<T>(
      Object? raw,
      int rows,
      int columns,
      T Function(Object? value) read,
    ) {
      final source = raw is List ? raw : const [];
      return [
        for (var r = 0; r < rows; r++)
          [
            for (var c = 0; c < columns; c++)
              read(
                r < source.length && source[r] is List
                    ? ((source[r] as List).length > c
                          ? (source[r] as List)[c]
                          : null)
                    : null,
              ),
          ],
      ];
    }

    List<String> texts(Object? raw) {
      final source = raw is List ? raw : const [];
      return [
        for (var i = 0; i < verifiers; i++)
          i < source.length && source[i] is String ? source[i] as String : '',
      ];
    }

    T byIndex<T>(List<T> values, Object? value) {
      final index = readInt(value);
      return index >= 0 && index < values.length ? values[index] : values[0];
    }

    int? readDigit(Object? value) {
      final digit = value == null ? null : readInt(value, fallback: -1);
      return digit != null && digit >= 1 && digit <= digitCount ? digit : null;
    }

    return TuringNotes(
      player: json['player'] is String ? json['player'] as String : '',
      problem: json['problem'] is String ? json['problem'] as String : '',
      codes: grid(json['codes'], rounds, shapes, readDigit),
      results: grid(
        json['results'],
        rounds,
        verifiers,
        (value) => byIndex(VerifierMark.values, value),
      ),
      digits: grid(
        json['digits'],
        shapes,
        digitCount,
        (value) => byIndex(DigitMark.values, value),
      ),
      notes: texts(json['notes']),
      criteria: texts(json['criteria']),
      verifierCount: readInt(
        json['verifierCount'],
        fallback: minVerifiers,
      ).clamp(minVerifiers, verifiers),
      finalCode: grid([json['finalCode']], 1, shapes, readDigit).first,
    );
  }
}

/// Keeps the current note sheet on the device between visits.
class TuringNotesStore {
  static const storageKey = 'turing_machine.note_sheet';

  static Future<TuringNotes> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null) {
        return TuringNotes();
      }
      return TuringNotes.fromJson(readMap(jsonDecode(raw)));
    } catch (_) {
      return TuringNotes();
    }
  }

  static Future<void> save(TuringNotes notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(notes.toJson()));
    } catch (_) {
      // Notes are a convenience; a failed write must not break the sheet.
    }
  }
}
