import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/shared_preferences_session_repository.dart';
import 'domain/game_registry.dart';
import 'l10n/locale_controller.dart';
import 'shared/update/app_update.dart';

Future<void> main() async {
  // The app syncs browser history itself (see BrowserBackSync); Flutter's
  // own single-entry history is skipped by Chrome's back gesture.
  setUrlStrategy(null);
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeController = await LocaleController.create();
  runApp(
    BoardGameScoreSheetApp(
      repository: SharedPreferencesSessionRepository(prefs),
      registry: GameRegistry(),
      localeController: localeController,
      updateController: AppUpdateController()..start(),
    ),
  );
}
