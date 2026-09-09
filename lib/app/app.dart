import 'package:flutter/material.dart';

import '../data/game_session_repository.dart';
import '../domain/game_registry.dart';
import '../features/home/home_screen.dart';
import 'theme.dart';

class BoardGameScoreSheetApp extends StatelessWidget {
  const BoardGameScoreSheetApp({
    super.key,
    required this.repository,
    required this.registry,
  });

  final GameSessionRepository repository;
  final GameRegistry registry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Board Game Score Sheet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      home: HomeScreen(
        registry: registry,
        repository: repository,
      ),
    );
  }
}
