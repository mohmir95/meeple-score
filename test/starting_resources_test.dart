import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('Arnak starting resources opens the setup chart', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final locale = await createTestLocale();
    await pumpScoreSheetApp(tester, localeController: locale);
    await pumpUntilFound(tester, find.text('Lost Ruins of Arnak'));
    await tester.tap(find.text('Lost Ruins of Arnak'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Starting Resources'));

    await tester.tap(find.text('Starting Resources'));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('arnak-starting-resources-panel')),
    );
    expect(find.byType(ArnakStartingResourcesScreen), findsOneWidget);
    expect(find.text('Player 1:'), findsOneWidget);
    expect(find.text('Player 4:'), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/games/lost_ruins_of_arnak/icons/coin.png'),
      ),
      findsNWidgets(6),
    );
    expect(
      find.image(
        const AssetImage('assets/games/lost_ruins_of_arnak/icons/compass.png'),
      ),
      findsNWidgets(4),
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('arnak-starting-deck-panel')),
    );
    expect(find.text('Your Starting Deck (Base Game)'), findsOneWidget);
    expect(find.textContaining('Playing with leaders'), findsOneWidget);
    expect(find.text('2 Funding cards'), findsOneWidget);
    expect(find.text('2 Exploration cards'), findsOneWidget);
    expect(find.text('2 Fear cards'), findsOneWidget);
    for (final card in ['funding', 'exploration', 'fear']) {
      expect(
        find.image(
          AssetImage('assets/games/lost_ruins_of_arnak/icons/card_$card.png'),
        ),
        findsNWidgets(2),
      );
    }
    expect(tester.takeException(), isNull);
  });
}
