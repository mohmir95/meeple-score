import '../../domain/json_values.dart';

class CobPlayerLine {
  const CobPlayerLine({this.victoryPoints = 0});

  /// Points currently on The Castles of Burgundy score track.
  final int victoryPoints;

  static int normalize(int value) => value < 0 ? 0 : value;

  CobPlayerLine copyWith({int? victoryPoints}) {
    return CobPlayerLine(
      victoryPoints: victoryPoints == null
          ? this.victoryPoints
          : normalize(victoryPoints),
    );
  }

  Map<String, dynamic> toJson() {
    return {'victoryPoints': victoryPoints};
  }

  factory CobPlayerLine.fromJson(Map<String, dynamic> json) {
    return CobPlayerLine(
      victoryPoints: normalize(readInt(json['victoryPoints'])),
    );
  }
}
