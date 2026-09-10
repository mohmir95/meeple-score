import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/shared_preferences_session_repository.dart';
import 'domain/game_registry.dart';
import 'l10n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeController = await LocaleController.create();
  runApp(
    BoardGameScoreSheetApp(
      repository: SharedPreferencesSessionRepository(prefs),
      registry: GameRegistry(),
      localeController: localeController,
    ),
  );
}
