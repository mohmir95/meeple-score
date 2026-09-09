class Player {
  const Player({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final String id;
  final String name;
  final int colorValue;

  Player copyWith({
    String? name,
    int? colorValue,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Player &&
        other.id == id &&
        other.name == name &&
        other.colorValue == colorValue;
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue);
}
