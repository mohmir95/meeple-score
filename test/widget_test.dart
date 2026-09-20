import 'dart:typed_data';

import 'package:board_game_score_sheet/domain/models/game_session.dart';
import 'package:board_game_score_sheet/domain/models/game_status.dart';
import 'package:board_game_score_sheet/domain/models/player.dart';
import 'package:board_game_score_sheet/features/home/game_card.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_2e_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_argentina_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_buildings_layout.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_buildings_randomizer_screen.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_config.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_game.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_public_buildings_layout.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_player_line.dart';
import 'package:board_game_score_sheet/games/great_western_trail/gwt_state.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_config.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_game.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_player_line.dart';
import 'package:board_game_score_sheet/games/lost_ruins_of_arnak/arnak_state.dart';
import 'package:board_game_score_sheet/l10n/l10n_scope.dart';
import 'package:board_game_score_sheet/shared/export/png_save.dart';
import 'package:board_game_score_sheet/shared/export/widget_png.dart';
import 'package:board_game_score_sheet/shared/widgets/language_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_harness.dart';
import 'helpers/memory_session_repository.dart';

String _imageAssetName(WidgetTester tester, Key key) {
  final image = tester.widget<Image>(find.byKey(key));
  return (image.image as AssetImage).assetName;
}

String _publicTileOn(WidgetTester tester, String location) {
  final name = _imageAssetName(
    tester,
    ValueKey('gwt-public-tile-$location'),
  );
  return name.split('/').last.replaceAll('.jpg', '').toUpperCase();
}

void main() {
  testWidgets('home lists Great Western Trail and can start a game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await pumpScoreSheetApp(tester, repository: repository);
    await pumpUntilFound(tester, find.text('Great Western Trail'));

    expect(find.text('Meeple Score'), findsOneWidget);
    expect(find.text('Great Western Trail'), findsNWidgets(3));
    expect(find.text('Great Western Trail First Edition'), findsNothing);
    expect(find.text('Great Western Trail Second Edition'), findsNothing);
    expect(find.text('Great Western Trail Argentina'), findsNothing);
    expect(find.text('First Edition'), findsNothing);
    expect(find.text('Second Edition'), findsOneWidget);
    expect(find.text('Argentina'), findsOneWidget);
    expect(find.text('Simple Tally'), findsNothing);
    expect(find.text('فارسی'), findsOneWidget);

    await tester.tap(find.byType(GameCard).first);
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Scoresheet'));
    expect(find.text('Scoresheet'), findsOneWidget);
    expect(find.text('Buildings Randomizer'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNothing);

    await tester.tap(find.text('Scoresheet'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Start game'));

    expect(find.widgetWithText(AppBar, 'Great Western Trail'), findsWidgets);
    expect(find.byTooltip('Red'), findsOneWidget);
    expect(find.byTooltip('Blue'), findsOneWidget);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.text('Save image'), findsNothing);
    expect(await repository.load(GreatWesternTrailGame.idValue), isNotNull);
  });

  testWidgets('home shows a resume chip for a saved game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    await pumpScoreSheetApp(tester, repository: repository);
    await openGwtSetup(tester);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pumpFor(tester);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Resume'));

    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    expect(find.text('Score pad'), findsOneWidget);
    expect(find.text('Scoresheet'), findsNothing);
    expect(find.text('Buildings Randomizer'), findsNothing);
    Navigator.of(tester.element(find.text('Score pad'))).pop();
    await pumpFor(tester);
  });

  testWidgets('refresh restores an in-progress GWT game', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = MemorySessionRepository();
    final localeController = await createTestLocale();
    await pumpScoreSheetApp(
      tester,
      repository: repository,
      localeController: localeController,
    );
    await pumpUntilFound(tester, find.text('Great Western Trail'));
    await openGwtSetup(tester);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));
    expect(find.text('Score pad'), findsOneWidget);

    await pumpScoreSheetApp(
      tester,
      repository: repository,
      localeController: localeController,
    );
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Great Western Trail'), findsOneWidget);
  });

  testWidgets('home layout works on a narrow phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(tester, find.text('Great Western Trail'));

    expect(find.text('Great Western Trail'), findsWidgets);
    expect(find.text('First Edition'), findsNothing);

    final first = tester.getRect(find.byType(GameCard).at(0));
    final second = tester.getRect(find.byType(GameCard).at(1));
    expect(first.top, closeTo(second.top, 1));
    expect(first.right, lessThanOrEqualTo(second.left + 1));
    expect(first.width, closeTo(first.height, 2));
    expect(second.width, closeTo(second.height, 2));
    expect(first.width, lessThan(220));

    await openGwtSetup(tester);
    expect(find.textContaining('You are ranchers'), findsOneWidget);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Score pad'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
    expect(
      find.image(
        const AssetImage('assets/games/great_western_trail/icons/coins.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Argentina pad uses pesos, ships, and a 2-VP disc', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester, localeController: await createTestLocale());
    await pumpUntilFound(tester, find.text('Argentina'));
    await tester.tap(find.text('Argentina'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Scoresheet'));
    expect(find.text('Buildings Randomizer'), findsOneWidget);
    expect(find.text('Coming Soon'), findsNothing);
    await tester.tap(find.text('Scoresheet'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Start game'));
    expect(
      find.widgetWithText(AppBar, 'Great Western Trail Argentina'),
      findsWidgets,
    );
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Pesos'), findsOneWidget);
    expect(find.text('Ships'), findsOneWidget);
    expect(find.text('City maps'), findsOneWidget);
    expect(find.text('Farmers'), findsOneWidget);
    expect(find.text('2-VP disc'), findsOneWidget);
    expect(find.text('Deliveries'), findsNothing);
    expect(find.text('Hazards'), findsNothing);
    expect(find.text('3-VP disc'), findsNothing);
    expect(
      find.image(
        const AssetImage(
          'assets/games/great_western_trail_argentina/icons/ships.png',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage(
          'assets/games/great_western_trail_argentina/icons/city-maps.png',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage(
          'assets/games/great_western_trail_argentina/icons/farmers.png',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage(
          'assets/games/great_western_trail_argentina/icons/two-vp.png',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('GWT first edition randomizes ten building sides', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester, localeController: await createTestLocale());
    await pumpUntilFound(tester, find.text('Great Western Trail'));
    await tester.tap(find.byType(GameCard).first);
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Buildings Randomizer'));
    expect(find.text('Coming Soon'), findsNothing);

    await tester.tap(find.text('Buildings Randomizer'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Private Buildings'));
    expect(find.text('Public Buildings'), findsOneWidget);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-buildings-randomize')),
    );

    for (var n = 1; n <= 10; n++) {
      expect(find.byKey(ValueKey('gwt-building-$n')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('gwt-building-11')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-building-12')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsNothing);
    expect(
      find.text('"Rails to the North" Expansion'),
      findsOneWidget,
    );
    expect(find.text('"13th Building" Expansion'), findsOneWidget);

    final randomize = tester.getRect(
      find.byKey(const ValueKey('gwt-buildings-randomize')),
    );
    expect(randomize.width, lessThan(220));

    const allA = GwtBuildingsLayout([
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
    ]);
    const publicOrder = GwtPublicBuildingsLayout([
      'C',
      'A',
      'G',
      'B',
      'F',
      'D',
      'E',
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpWithL10n(
      tester,
      GwtBuildingsRandomizerScreen(
        game: const GreatWesternTrailGame(),
        initialLayout: allA,
        initialPublicLayout: publicOrder,
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-buildings-randomize')),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-1')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail/buildings/private/1a.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-1')),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gwt-buildings-randomize')));
    await pumpFor(tester);
    for (var n = 1; n <= 10; n++) {
      expect(find.byKey(ValueKey('gwt-building-$n')), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('gwt-rails-to-the-north')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-building-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-building-12')), findsOneWidget);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gwt-thirteenth-building')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsOneWidget);
    for (final n in [11, 12, 13]) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('gwt-building-$n')),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('gwt-rails-to-the-north')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-building-11')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-building-12')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gwt-thirteenth-building')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('gwt-tab-public')));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-public-location-A')),
    );
    for (final location in GwtPublicBuildingsLayout.classicLocations) {
      expect(
        find.byKey(ValueKey('gwt-public-location-$location')),
        findsOneWidget,
      );
    }
    expect(_publicTileOn(tester, 'A'), 'C');
    expect(_publicTileOn(tester, 'G'), 'E');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-A')),
        matching: find.text('A'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-A')),
        matching: find.text('C'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-A')),
        matching: find.byIcon(Icons.arrow_forward_rounded),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('gwt-public-buildings-randomize')),
    );
    await pumpFor(tester);
    final placed = [
      for (final location in GwtPublicBuildingsLayout.classicLocations)
        _publicTileOn(tester, location),
    ];
    expect(placed.toSet(), GwtPublicBuildingsLayout.classicLocations.toSet());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('GWT building tiles stay left-to-right in Persian', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const layout = GwtBuildingsLayout([
      GwtBuildingSide.a,
      GwtBuildingSide.b,
      GwtBuildingSide.a,
      GwtBuildingSide.b,
      GwtBuildingSide.a,
      GwtBuildingSide.b,
      GwtBuildingSide.a,
      GwtBuildingSide.b,
      GwtBuildingSide.a,
      GwtBuildingSide.b,
    ]);
    await tester.pumpWidget(
      L10nScope(
        controller: await createTestLocale(),
        child: MaterialApp(
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const GwtBuildingsRandomizerScreen(
            game: GreatWesternTrailGame(),
            initialLayout: layout,
          ),
        ),
      ),
    );
    await pumpFor(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('gwt-building-1')));

    final first = tester.getRect(find.byKey(const ValueKey('gwt-building-1')));
    final second = tester.getRect(find.byKey(const ValueKey('gwt-building-2')));
    expect(first.left, lessThan(second.left));
  });

  testWidgets(
    'GWT second edition has twelve private buildings and Rails adds 13',
    (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const allA = GwtBuildingsLayout([
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
    ], baseCount: 12);
    await pumpWithL10n(
      tester,
      const GwtBuildingsRandomizerScreen(
        game: GreatWesternTrailSecondEditionGame(),
        initialLayout: allA,
        initialPublicLayout: GwtPublicBuildingsLayout([
          'C',
          'A',
          'G',
          'B',
          'F',
          'D',
          'E',
        ]),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-buildings-randomize')),
    );
    expect(find.text('"Rails to the North" Expansion'), findsOneWidget);
    expect(find.text('"13th Building" Expansion'), findsNothing);
    expect(find.byKey(const ValueKey('gwt-thirteenth-building')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-rails-to-the-north')), findsOneWidget);
    for (var n = 1; n <= 12; n++) {
      expect(find.byKey(ValueKey('gwt-building-$n')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('gwt-building-13')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-1')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_2e/buildings/private/1a.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-12')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_2e/buildings/private/12a.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gwt-rails-to-the-north')));
    await pumpFor(tester);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-13')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gwt-tab-public')));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-public-location-A')),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-A')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_2e/buildings/public/c.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'GWT Argentina has ten private buildings, no expansions, and public A–H',
    (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const allA = GwtBuildingsLayout([
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
      GwtBuildingSide.a,
    ]);
    await pumpWithL10n(
      tester,
      const GwtBuildingsRandomizerScreen(
        game: GreatWesternTrailArgentinaGame(),
        initialLayout: allA,
        initialPublicLayout: GwtPublicBuildingsLayout(
          ['C', 'A', 'G', 'B', 'F', 'D', 'E', 'H'],
          locations: GwtPublicBuildingsLayout.argentinaLocations,
        ),
      ),
    );
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-buildings-randomize')),
    );
    expect(find.text('"Rails to the North" Expansion'), findsNothing);
    expect(find.text('"13th Building" Expansion'), findsNothing);
    expect(find.byKey(const ValueKey('gwt-thirteenth-building')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-rails-to-the-north')), findsNothing);
    expect(find.byType(Card), findsNothing);
    for (var n = 1; n <= 10; n++) {
      expect(find.byKey(ValueKey('gwt-building-$n')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('gwt-building-11')), findsNothing);
    expect(find.byKey(const ValueKey('gwt-building-13')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-1')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_argentina/buildings/private/1a.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-building-10')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_argentina/buildings/private/10a.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('gwt-tab-public')));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('gwt-public-location-A')),
    );
    for (final location in GwtPublicBuildingsLayout.argentinaLocations) {
      expect(
        find.byKey(ValueKey('gwt-public-location-$location')),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-A')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_argentina/buildings/public/c.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gwt-public-location-H')),
        matching: find.image(
          const AssetImage(
            'assets/games/great_western_trail_argentina/buildings/public/h.jpg',
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(_publicTileOn(tester, 'A'), 'C');
    expect(_publicTileOn(tester, 'H'), 'H');
  });

  testWidgets('Arnak pad uses research, idols, guardians, and fear', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester, localeController: await createTestLocale());
    await pumpUntilFound(tester, find.text('Lost Ruins of Arnak'));
    await tester.tap(find.text('Lost Ruins of Arnak'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Scoresheet'));
    expect(find.text('Scoresheet'), findsOneWidget);
    expect(find.text('Buildings Randomizer'), findsNothing);

    await tester.tap(find.text('Scoresheet'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Start game'));
    expect(find.widgetWithText(AppBar, 'Lost Ruins of Arnak'), findsWidgets);
    expect(find.byTooltip('Red'), findsOneWidget);
    await tester.tap(find.text('Add player'));
    await pumpFor(tester);
    await tester.tap(find.text('Add player'));
    await pumpFor(tester);
    await tester.tap(find.text('Add player'));
    await pumpFor(tester);
    expect(find.byTooltip('Green'), findsOneWidget);
    await tester.tap(find.text('Start game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Temple tiles'), findsOneWidget);
    expect(find.text('Idols'), findsOneWidget);
    expect(find.text('Guardians'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
    expect(find.text('Fear'), findsOneWidget);
    expect(find.text('Lost Temple first'), findsNothing);
    expect(find.text('Coins'), findsNothing);
    expect(
      find.image(
        const AssetImage('assets/games/lost_ruins_of_arnak/icons/research.png'),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage('assets/games/lost_ruins_of_arnak/icons/idols.png'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hub scoresheet banners match size on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final locale = await createTestLocale();
    await pumpScoreSheetApp(tester, localeController: locale);
    await pumpUntilFound(tester, find.text('Second Edition'));
    await tester.tap(find.text('Second Edition'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('hub-scoresheet')));
    final gwt = tester.getRect(find.byKey(const ValueKey('hub-scoresheet')));
    expect(
      find.byKey(const ValueKey('hub-buildings-randomizer')),
      findsOneWidget,
    );
    expect(find.text('Coming Soon'), findsNothing);
    expect(gwt.width, lessThan(220));
    expect(gwt.width, closeTo(gwt.height, 2));

    await pumpScoreSheetApp(tester, localeController: locale);
    await pumpUntilFound(tester, find.text('Lost Ruins of Arnak'));
    await tester.tap(find.text('Lost Ruins of Arnak'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.byKey(const ValueKey('hub-scoresheet')));
    final arnak = tester.getRect(find.byKey(const ValueKey('hub-scoresheet')));

    expect(arnak.width, closeTo(gwt.width, 1));
    expect(arnak.height, closeTo(gwt.height, 1));
    expect(find.text('Buildings Randomizer'), findsNothing);
  });

  testWidgets('Arnak finish asks who reached the Lost Temple first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
    const sam = Player(id: 'sam', name: 'Sam', colorValue: 0xFF1565C0);
    final state = ArnakState(
      players: const [ada, sam],
      config: const ArnakConfig(),
      status: GameStatus.inProgress,
      lines: const {
        'ada': ArnakPlayerLine(research: 10, cards: 10),
        'sam': ArnakPlayerLine(research: 8, cards: 12),
      },
    );
    final repository = MemorySessionRepository();
    await repository.save(
      GameSession(
        gameId: LostRuinsOfArnakGame.idValue,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        stateJson: state.toJson(),
      ),
    );

    await pumpScoreSheetApp(
      tester,
      repository: repository,
      localeController: await createTestLocale(),
    );
    await pumpUntilFound(tester, find.text('Lost Ruins of Arnak'));
    await tester.tap(find.text('Lost Ruins of Arnak'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Scoresheet'));
    await tester.tap(find.text('Scoresheet'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Continue saved game'));
    await tester.tap(find.text('Continue saved game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Score pad'));

    await tester.tap(find.text('Finish'));
    await pumpFor(tester);
    await pumpUntilFound(
      tester,
      find.text('Who reached the Lost Temple first?'),
    );
    expect(find.text('No one'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Ada')),
    );
    await pumpFor(tester);
    await tester.tap(find.text('Confirm'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Ada wins!'));
  });

  testWidgets('finished scoresheet can be saved as an image', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
    final stamped = DateTime.utc(2026, 1, 1);
    final repository = MemorySessionRepository();
    await repository.save(
      GameSession(
        gameId: GreatWesternTrailGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: GwtState(
          players: const [ada],
          config: const GwtConfig(),
          status: GameStatus.finished,
          lines: const {'ada': GwtPlayerLine(buildings: 12)},
        ).toJson(),
      ),
    );

    Uint8List? savedBytes;
    String? savedName;
    capturePngOverride = (key, {pixelRatio = 2}) async {
      return Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);
    };
    pngSaveOverride = (bytes, filename) async {
      savedBytes = bytes;
      savedName = filename;
    };
    addTearDown(() {
      capturePngOverride = null;
      pngSaveOverride = null;
    });

    await pumpScoreSheetApp(tester, repository: repository);
    await pumpUntilFound(tester, find.text('Last game'));
    await tester.tap(find.text('Last game'));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('Save image'));
    expect(find.text('Save image'), findsWidgets);

    await tester.tap(find.text('Save image').last);
    await pumpFor(tester);

    expect(savedBytes, isNotNull);
    expect(savedBytes!.sublist(0, 8), <int>[137, 80, 78, 71, 13, 10, 26, 10]);
    expect(savedName, contains(GreatWesternTrailGame.idValue));
    expect(savedName, endsWith('.png'));
    expect(
      find.text('Score sheet saved. Check Downloads or your photo gallery.'),
      findsOneWidget,
    );
  });

  testWidgets('Last Game on every banner opens the saved scoresheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const ada = Player(id: 'ada', name: 'Ada', colorValue: 0xFFC62828);
    final gwtState = GwtState(
      players: const [ada],
      config: const GwtConfig(),
      status: GameStatus.finished,
      lines: const {'ada': GwtPlayerLine()},
    );
    final arnakState = ArnakState(
      players: const [ada],
      config: const ArnakConfig(),
      status: GameStatus.finished,
      lines: const {'ada': ArnakPlayerLine(research: 10)},
      lostTempleFirstPlayerId: ada.id,
    );
    final stamped = DateTime.utc(2026, 1, 1);
    final repository = MemorySessionRepository();
    await repository.save(
      GameSession(
        gameId: GreatWesternTrailGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: gwtState.toJson(),
      ),
    );
    await repository.save(
      GameSession(
        gameId: GreatWesternTrailSecondEditionGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: gwtState.toJson(),
      ),
    );
    await repository.save(
      GameSession(
        gameId: GreatWesternTrailArgentinaGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: gwtState.toJson(),
      ),
    );
    await repository.save(
      GameSession(
        gameId: LostRuinsOfArnakGame.idValue,
        createdAt: stamped,
        updatedAt: stamped,
        stateJson: arnakState.toJson(),
      ),
    );

    await pumpScoreSheetApp(tester, repository: repository);
    await pumpUntilFound(tester, find.text('Last game'));
    expect(find.text('Last game'), findsNWidgets(4));

    const titles = [
      'Great Western Trail',
      'Great Western Trail Second Edition',
      'Great Western Trail Argentina',
      'Lost Ruins of Arnak',
    ];
    const savedKeys = [
      'home-saved-great_western_trail_1e',
      'home-saved-great_western_trail_2e',
      'home-saved-great_western_trail_argentina',
      'home-saved-lost_ruins_of_arnak',
    ];
    for (var i = 0; i < titles.length; i++) {
      await tester.tap(find.byKey(ValueKey(savedKeys[i])));
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('Score pad'));
      expect(find.text('Score pad'), findsOneWidget);
      expect(
        find.text('This game is finished. You can still review the sheet.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppBar, titles[i]), findsOneWidget);
      expect(find.text('Scoresheet'), findsNothing);
      Navigator.of(tester.element(find.text('Score pad'))).pop();
      await pumpFor(tester);
      await pumpUntilGone(tester, find.text('Score pad'));
      await pumpUntilFound(tester, find.text('Last game'));
    }
  });

  testWidgets('language toggle switches English and Persian', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await pumpScoreSheetApp(tester);
    await pumpUntilFound(tester, find.text('Meeple Score'));

    expect(find.text('Meeple Score'), findsOneWidget);
    await tester.tap(find.byType(LanguageToggle));
    await pumpFor(tester);
    await pumpUntilFound(tester, find.text('میپل اسکور'));
    expect(find.text('English'), findsWidgets);
    expect(find.text('گریت وسترن تریل'), findsWidgets);
    expect(find.text('نسخه دوم'), findsOneWidget);
    expect(find.text('آرژانتین'), findsOneWidget);
    expect(find.text('ویرانه‌های گمشده آرناک'), findsOneWidget);
  });
}
