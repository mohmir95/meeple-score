import 'gwt_edition.dart';

class GreatWesternTrailSecondEditionGame extends GwtEditionGame {
  const GreatWesternTrailSecondEditionGame();

  static const idValue = 'great_western_trail_2e';
  static const coverAsset = 'assets/games/great_western_trail_2e/cover.webp';

  @override
  String get id => idValue;

  @override
  String get name => 'Great Western Trail Second Edition';

  @override
  String? get editionLabel => 'Second Edition';

  @override
  String get l10nPrefix => 'game.gwt2';

  @override
  String get description =>
      'Wrangle your herd of cows across the prairie and deliver it to Kansas City. '
      'Second Edition adds solo play, new art by Chris Quilliams, Simmental cattle, '
      'extra buildings, exchange tokens, and new station master tiles.';

  @override
  int get minPlayers => 1;

  @override
  String? get released => '2021';

  @override
  String? get coverImageAsset => coverAsset;
}
