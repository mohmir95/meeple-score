import '../../domain/json_values.dart';

class GwtPlayerLine {
  const GwtPlayerLine({
    this.dollars = 0,
    this.buildings = 0,
    this.deliveries = 0,
    this.stations = 0,
    this.hazards = 0,
    this.cattle = 0,
    this.objectives = 0,
    this.stationMasters = 0,
    this.playerBoard = 0,
    this.clearedThreeVpSpace = false,
    this.hasJobMarketToken = false,
  });

  /// Cash on hand. Victory points are `dollars ~/ 5`.
  final int dollars;
  final int buildings;
  final int deliveries;
  final int stations;
  final int hazards;
  final int cattle;
  final int objectives;
  final int stationMasters;

  /// VP from workers on the 5th/6th spaces of the worker section (4 VP each).
  final int playerBoard;
  final bool clearedThreeVpSpace;
  final bool hasJobMarketToken;

  GwtPlayerLine copyWith({
    int? dollars,
    int? buildings,
    int? deliveries,
    int? stations,
    int? hazards,
    int? cattle,
    int? objectives,
    int? stationMasters,
    int? playerBoard,
    bool? clearedThreeVpSpace,
    bool? hasJobMarketToken,
  }) {
    return GwtPlayerLine(
      dollars: dollars ?? this.dollars,
      buildings: buildings ?? this.buildings,
      deliveries: deliveries ?? this.deliveries,
      stations: stations ?? this.stations,
      hazards: hazards ?? this.hazards,
      cattle: cattle ?? this.cattle,
      objectives: objectives ?? this.objectives,
      stationMasters: stationMasters ?? this.stationMasters,
      playerBoard: playerBoard ?? this.playerBoard,
      clearedThreeVpSpace: clearedThreeVpSpace ?? this.clearedThreeVpSpace,
      hasJobMarketToken: hasJobMarketToken ?? this.hasJobMarketToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dollars': dollars,
      'buildings': buildings,
      'deliveries': deliveries,
      'stations': stations,
      'hazards': hazards,
      'cattle': cattle,
      'objectives': objectives,
      'stationMasters': stationMasters,
      'playerBoard': playerBoard,
      'clearedThreeVpSpace': clearedThreeVpSpace,
      'hasJobMarketToken': hasJobMarketToken,
    };
  }

  factory GwtPlayerLine.fromJson(Map<String, dynamic> json) {
    return GwtPlayerLine(
      dollars: readInt(json['dollars']),
      buildings: readInt(json['buildings']),
      deliveries: readInt(json['deliveries']),
      stations: readInt(json['stations']),
      hazards: readInt(json['hazards']),
      cattle: readInt(json['cattle']),
      objectives: readInt(json['objectives']),
      stationMasters: readInt(json['stationMasters']),
      playerBoard: readInt(json['playerBoard']),
      clearedThreeVpSpace: readBool(json['clearedThreeVpSpace']),
      hasJobMarketToken: readBool(json['hasJobMarketToken']),
    );
  }
}
