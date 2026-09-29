import 'package:board_game_score_sheet/features/home/game_card.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_starting_resources_screen.dart';
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

  testWidgets('GWT first edition starting resources shows dollars per seat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const coin5 = AssetImage(GwtStartingResourcesScreen.coin5Asset);
    const coin1 = AssetImage(GwtStartingResourcesScreen.coin1Asset);
    const token = AssetImage(GwtStartingResourcesScreen.exchangeTokenAsset);

    final locale = await createTestLocale();
    await pumpScoreSheetApp(tester, localeController: locale);
    await pumpUntilFound(tester, find.text('Great Western Trail'));
    await tester.tap(find.byType(GameCard).first);
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Starting Resources'));

    await tester.tap(find.text('Starting Resources'));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-starting-resources-panel')),
    );
    expect(find.byType(GwtStartingResourcesScreen), findsOneWidget);
    for (var seat = 1; seat <= 4; seat++) {
      expect(find.text('Player $seat:'), findsOneWidget);
      expect(find.text('\$${5 + seat}'), findsOneWidget);
    }
    expect(find.image(coin5), findsNWidgets(4));
    expect(find.image(coin1), findsNWidgets(1 + 2 + 3 + 4));
    // The Rails to the North panel always shows one large token.
    expect(find.image(token), findsOneWidget);
    expect(find.textContaining('exchange token'), findsOneWidget);

    final railsSwitch = find.byKey(
      const ValueKey('gwt-starting-rails-to-the-north'),
    );
    await tester.ensureVisible(railsSwitch);
    await tester.tap(railsSwitch);
    await pumpFor(tester);
    expect(find.image(token), findsNWidgets(1 + 4));
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 412.0]) {
    testWidgets('GWT player 4 resources fit one line at ${width}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final locale = await createTestLocale();
      await pumpScoreSheetApp(tester, localeController: locale);
      await pumpUntilFound(tester, find.text('Great Western Trail'));
      await tester.tap(find.byType(GameCard).first);
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('Starting Resources'));
      await tester.tap(find.text('Starting Resources'));
      await pumpFor(tester);
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('gwt-starting-resources-panel')),
      );

      final railsSwitch = find.byKey(
        const ValueKey('gwt-starting-rails-to-the-north'),
      );
      await tester.ensureVisible(railsSwitch);
      await tester.tap(railsSwitch);
      await pumpFor(tester);

      final seat4Coin5 = tester.getCenter(
        find.image(const AssetImage(GwtStartingResourcesScreen.coin5Asset)).at(3),
      );
      final seat4Token = tester.getCenter(
        find
            .image(
              const AssetImage(GwtStartingResourcesScreen.exchangeTokenAsset),
            )
            .at(3),
      );
      expect(seat4Token.dy, closeTo(seat4Coin5.dy, 1));
      expect(tester.takeException(), isNull);
    });
  }
}
