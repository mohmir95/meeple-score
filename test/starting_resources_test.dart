import 'package:board_game_score_sheet/features/home/game_card.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_starting_resources_screen.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_starting_resources_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';

Future<void> _openStartingResources(
  WidgetTester tester, {
  required Finder gameCard,
}) async {
  final locale = await createTestLocale();
  await pumpScoreSheetApp(tester, localeController: locale);
  await pumpUntilFound(tester, gameCard);
  await tester.tap(gameCard);
  await pumpFor(tester);
  await pumpUntilFound(tester, find.text('Starting Resources'));
  await tester.tap(find.text('Starting Resources'));
  await pumpFor(tester);
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('gwt-starting-resources-panel')),
  );
}

final _firstEdition = find.byType(GameCard).first;
final _secondEdition = find.text('Second Edition');

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
    for (final (card, count) in [
      ('funding', 1),
      ('funding_car', 1),
      ('exploration', 1),
      ('exploration_boat', 1),
      ('fear', 2),
    ]) {
      expect(
        find.image(
          AssetImage('assets/games/lost_ruins_of_arnak/icons/card_$card.png'),
        ),
        findsNWidgets(count),
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

    const setup = GwtStartingSetup.firstEdition;
    final coin5 = AssetImage(setup.coin5Asset);
    final coin1 = AssetImage(setup.coin1Asset);
    final token = AssetImage(setup.token.asset);

    await _openStartingResources(tester, gameCard: _firstEdition);
    expect(find.byType(GwtStartingResourcesScreen), findsOneWidget);
    for (var seat = 1; seat <= 4; seat++) {
      expect(find.text('Player $seat:'), findsOneWidget);
      expect(find.text('\$${5 + seat}'), findsOneWidget);
    }
    expect(find.image(coin5), findsNWidgets(4));
    expect(find.image(coin1), findsNWidgets(1 + 2 + 3 + 4));
    expect(
      find.byKey(const ValueKey('gwt-starting-cards-panel')),
      findsOneWidget,
    );
    for (var seat = 1; seat <= 4; seat++) {
      expect(find.text('${3 + seat} cards'), findsOneWidget);
    }
    expect(find.textContaining('player deck'), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-discard-callout')), findsOneWidget);
    // The Rails to the North option always shows its own token.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-starting-resources-panel')),
        matching: find.byKey(const ValueKey('gwt-rails-to-the-north-option')),
      ),
      findsOneWidget,
    );
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

  testWidgets('GWT second edition adds cards and a token for every seat', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const setup = GwtStartingSetup.secondEdition;
    await _openStartingResources(tester, gameCard: _secondEdition);

    for (var seat = 1; seat <= 4; seat++) {
      expect(find.text('Player $seat:'), findsOneWidget);
      expect(find.text('\$${5 + seat}'), findsOneWidget);
      final cards = 3 + seat;
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '$cards cards',
        ),
        findsOneWidget,
      );
      expect(find.text('$cards cards'), findsOneWidget);
      expect(find.text('Player $seat'), findsOneWidget);
    }
    expect(find.image(AssetImage(setup.coin5Asset)), findsNWidgets(4));
    expect(
      find.image(AssetImage(setup.coin1Asset)),
      findsNWidgets(1 + 2 + 3 + 4),
    );
    expect(find.image(AssetImage(setup.token.asset)), findsNWidgets(4));
    expect(find.textContaining('player deck'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('gwt-starting-cards-panel')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Players 2, 3 and 4: discard down to 4 cards at the start of your '
        'first turn.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('gwt-rails-to-the-north-option')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final (name, gameCard, setup, railsSwitch) in [
    ('first', _firstEdition, GwtStartingSetup.firstEdition, true),
    ('second', _secondEdition, GwtStartingSetup.secondEdition, false),
  ]) {
    for (final width in [360.0, 412.0]) {
      testWidgets('GWT $name edition player 4 fits one line at ${width}px', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await _openStartingResources(tester, gameCard: gameCard);
        if (railsSwitch) {
          final toggle = find.byKey(
            const ValueKey('gwt-starting-rails-to-the-north'),
          );
          await tester.ensureVisible(toggle);
          await tester.tap(toggle);
          await pumpFor(tester);
        }

        final seat4Coin5 = tester.getCenter(
          find.image(AssetImage(setup.coin5Asset)).at(3),
        );
        final seat4Token = tester.getCenter(
          find.image(AssetImage(setup.token.asset)).at(3),
        );
        expect(seat4Token.dy, closeTo(seat4Coin5.dy, 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
