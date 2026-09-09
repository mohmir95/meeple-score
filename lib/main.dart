import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/shared_preferences_session_repository.dart';
import 'domain/game_registry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    BoardGameScoreSheetApp(
      repository: SharedPreferencesSessionRepository(prefs),
      registry: GameRegistry(),
    ),
  );
}
