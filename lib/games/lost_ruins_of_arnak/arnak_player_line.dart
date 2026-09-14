import '../../domain/json_values.dart';

class ArnakPlayerLine {
  const ArnakPlayerLine({
    this.research = 0,
    this.templeTiles = 0,
    this.idols = 0,
    this.guardians = 0,
    this.cards = 0,
    this.fear = 0,
  });

  /// Combined VP from both research tokens (magnifying glass + notebook).
  final int research;

  /// VP printed on collected temple tiles.
  final int templeTiles;

  /// 3 VP per idol plus empty idol-slot VP.
  final int idols;

  /// 5 VP per overcome guardian.
  final int guardians;

  /// VP in the lower-right corner of item and artifact cards.
  final int cards;

  /// −1 VP per Fear card, −2 VP per fear tile. Never positive.
  final int fear;

  static int normalizeFear(int fear) => fear > 0 ? 0 : fear;

  ArnakPlayerLine copyWith({
    int? research,
    int? templeTiles,
    int? idols,
    int? guardians,
    int? cards,
    int? fear,
  }) {
    return ArnakPlayerLine(
      research: research ?? this.research,
      templeTiles: templeTiles ?? this.templeTiles,
      idols: idols ?? this.idols,
      guardians: guardians ?? this.guardians,
      cards: cards ?? this.cards,
      fear: fear == null ? this.fear : normalizeFear(fear),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'research': research,
      'templeTiles': templeTiles,
      'idols': idols,
      'guardians': guardians,
      'cards': cards,
      'fear': fear,
    };
  }

  factory ArnakPlayerLine.fromJson(Map<String, dynamic> json) {
    return ArnakPlayerLine(
      research: readInt(json['research']),
      templeTiles: readInt(json['templeTiles']),
      idols: readInt(json['idols']),
      guardians: readInt(json['guardians']),
      cards: readInt(json['cards']),
      fear: normalizeFear(readInt(json['fear'])),
    );
  }
}
