import 'gwt_edition.dart';

class GreatWesternTrailGame extends GwtEditionGame {
  const GreatWesternTrailGame();

  static const idValue = 'great_western_trail_1e';
  static const coverAsset = 'assets/games/great_western_trail/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail First Edition';

  @override
  String? get editionLabel => 'First Edition';

  @override
  String get l10nPrefix => 'game.gwt';

  @override
  String? get released => '2016';

  @override
  String? get coverImageAsset => coverAsset;
}
