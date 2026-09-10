import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:board_game_score_sheet/shared/player_colors.dart';
import 'package:board_game_score_sheet/shared/widgets/player_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

void main() {
  final palette = const GreatWesternTrailGame().playerColors;

  test('GWT default players use unique Red then Blue', () {
    final players = defaultPlayers(count: 2, palette: palette);
    expect(players[0].colorValue, palette[0].value);
    expect(players[1].colorValue, palette[1].value);
    expect(palette.map((option) => option.name), ['Red', 'Blue', 'Yellow', 'White']);
  });

  test('next GWT player takes the first unused color', () {
    final two = defaultPlayers(count: 2, palette: palette);
    final third = nextPlayer(two, palette);
    expect(third.colorValue, palette[2].value);
  });

  testWidgets('tapping a color swatch changes the player color', (tester) async {
    var players = defaultPlayers(count: 2, palette: palette);
    await pumpWithL10n(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return PlayerEditor(
              players: players,
              minPlayers: 2,
              maxPlayers: 4,
              colorOptions: palette,
              uniqueColors: true,
              onChanged: (next) => setState(() => players = next),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Red'));
    await pumpFor(tester);
    await tester.tap(find.text('Yellow'));
    await pumpFor(tester);

    expect(players[0].colorValue, palette[2].value);
    expect(players[1].colorValue, palette[1].value);
  });

  testWidgets('choosing a taken GWT color swaps with the other player', (tester) async {
    var players = defaultPlayers(count: 2, palette: palette);
    await pumpWithL10n(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return PlayerEditor(
              players: players,
              minPlayers: 2,
              maxPlayers: 4,
              colorOptions: palette,
              uniqueColors: true,
              onChanged: (next) => setState(() => players = next),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('Red'));
    await pumpFor(tester);
    await tester.tap(find.text('Blue'));
    await pumpFor(tester);

    expect(players[0].colorValue, palette[1].value);
    expect(players[1].colorValue, palette[0].value);
  });
}
