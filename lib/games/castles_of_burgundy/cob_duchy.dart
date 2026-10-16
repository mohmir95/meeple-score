import 'dart:math' as math;

/// Which Castles of Burgundy Special Edition duchy setup to deal.
///
/// Board numbers and copy counts follow the 28-page Special Edition rulebook.
/// A double-sided board has two printed numbers, and the box holds four copies
/// of each board unless noted below.
enum CobDuchyPool {
  /// Five boards, four copies each: 1/2, 3/4, 5/6, 7/8, and 9/10.
  base,

  /// Four boards, four copies each: 11/12, 13/14, 15/16, and 17/18.
  firstExpansion,

  /// One board, four copies: 19/20.
  championship,

  /// One board, four copies: 21/22.
  specialEdition,

  /// Four boards, four copies each: 23/24, 25/26, 27/28, and 29/30.
  borderPosts,

  /// Two team boards. Beginner halves are 31a and 32a; advanced are 31b and 32b.
  team,

  /// One solo board. Side 33 is for beginners; side 34 is advanced.
  solo,
}

/// One dealt duchy face.
///
/// [boardId] is the side to play. [otherSide] is printed on the back.
class CobDuchyAssignment {
  const CobDuchyAssignment({required this.boardId, required this.otherSide});

  final String boardId;
  final String otherSide;

  bool get isBeginner =>
      boardId == '1' ||
      boardId == '2' ||
      boardId == '33' ||
      boardId == '31a & 32a';

  bool get isAdvanced => boardId == '34' || boardId == '31b & 32b';

  CobDuchyAssignment flipped() {
    return CobDuchyAssignment(boardId: otherSide, otherSide: boardId);
  }
}

class _DuchyBoard {
  const _DuchyBoard(this.sideA, this.sideB, this.copies);

  final String sideA;
  final String sideB;
  final int copies;
}

const _baseBoards = [
  _DuchyBoard('1', '2', 4),
  _DuchyBoard('3', '4', 4),
  _DuchyBoard('5', '6', 4),
  _DuchyBoard('7', '8', 4),
  _DuchyBoard('9', '10', 4),
];

const _firstExpansionBoards = [
  _DuchyBoard('11', '12', 4),
  _DuchyBoard('13', '14', 4),
  _DuchyBoard('15', '16', 4),
  _DuchyBoard('17', '18', 4),
];

const _championshipBoards = [_DuchyBoard('19', '20', 4)];

const _specialEditionBoards = [_DuchyBoard('21', '22', 4)];

const _borderPostBoards = [
  _DuchyBoard('23', '24', 4),
  _DuchyBoard('25', '26', 4),
  _DuchyBoard('27', '28', 4),
  _DuchyBoard('29', '30', 4),
];

/// Deals duchies for the Special Edition rulebook.
///
/// Each player gets one physical board, then a side. Four copies of a board
/// means up to four players may share that pair of numbers. [firstGame] gives
/// every player the beginner board and the same number, either 1 or 2.
List<CobDuchyAssignment> dealCobDuchies({
  required int playerCount,
  required CobDuchyPool pool,
  bool firstGame = false,
  math.Random? random,
}) {
  final rng = random ?? math.Random();
  switch (pool) {
    case CobDuchyPool.solo:
      if (playerCount != 1) {
        throw ArgumentError.value(
          playerCount,
          'playerCount',
          'The solo duchy is for one player.',
        );
      }
      final beginner = rng.nextBool();
      return [
        CobDuchyAssignment(
          boardId: beginner ? '33' : '34',
          otherSide: beginner ? '34' : '33',
        ),
      ];
    case CobDuchyPool.team:
      if (playerCount != 2) {
        throw ArgumentError.value(
          playerCount,
          'playerCount',
          'The team game seats two teams.',
        );
      }
      final beginner = rng.nextBool();
      final face = beginner ? '31a & 32a' : '31b & 32b';
      final other = beginner ? '31b & 32b' : '31a & 32a';
      return [
        CobDuchyAssignment(boardId: face, otherSide: other),
        CobDuchyAssignment(boardId: face, otherSide: other),
      ];
    case CobDuchyPool.base:
    case CobDuchyPool.firstExpansion:
    case CobDuchyPool.championship:
    case CobDuchyPool.specialEdition:
    case CobDuchyPool.borderPosts:
      if (playerCount < 2 || playerCount > 4) {
        throw ArgumentError.value(
          playerCount,
          'playerCount',
          'Use 2–4 players.',
        );
      }
      if (firstGame) {
        if (pool != CobDuchyPool.base) {
          throw ArgumentError.value(
            pool,
            'pool',
            'A first game uses the base beginner duchy.',
          );
        }
        final sideOne = rng.nextBool();
        final face = sideOne ? '1' : '2';
        final other = sideOne ? '2' : '1';
        return [
          for (var player = 0; player < playerCount; player++)
            CobDuchyAssignment(boardId: face, otherSide: other),
        ];
      }
      final boards = switch (pool) {
        CobDuchyPool.base => _baseBoards,
        CobDuchyPool.firstExpansion => _firstExpansionBoards,
        CobDuchyPool.championship => _championshipBoards,
        CobDuchyPool.specialEdition => _specialEditionBoards,
        CobDuchyPool.borderPosts => _borderPostBoards,
        _ => throw StateError('Unhandled $pool'),
      };
      final bag = <_DuchyBoard>[
        for (final board in boards)
          for (var copy = 0; copy < board.copies; copy++) board,
      ]..shuffle(rng);
      return [
        for (final board in bag.take(playerCount))
          if (rng.nextBool())
            CobDuchyAssignment(boardId: board.sideA, otherSide: board.sideB)
          else
            CobDuchyAssignment(boardId: board.sideB, otherSide: board.sideA),
      ];
  }
}
