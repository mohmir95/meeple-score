import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../data/game_session_repository.dart';
import '../domain/game_registry.dart';
import '../features/home/home_screen.dart';
import '../l10n/l10n_scope.dart';
import '../l10n/locale_controller.dart';
import '../shared/update/app_update.dart';
import '../shared/update/update_banner.dart';
import 'theme.dart';

class BoardGameScoreSheetApp extends StatefulWidget {
  const BoardGameScoreSheetApp({
    super.key,
    required this.repository,
    required this.registry,
    required this.localeController,
    this.updateController,
  });

  final GameSessionRepository repository;
  final GameRegistry registry;
  final LocaleController localeController;

  /// Watches for newer deployed builds; null in tests.
  final AppUpdateController? updateController;

  @override
  State<BoardGameScoreSheetApp> createState() => _BoardGameScoreSheetAppState();
}

class _BoardGameScoreSheetAppState extends State<BoardGameScoreSheetApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.localeController.addListener(_onLocaleChanged);
  }

  @override
  void didUpdateWidget(BoardGameScoreSheetApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localeController != widget.localeController) {
      oldWidget.localeController.removeListener(_onLocaleChanged);
      widget.localeController.addListener(_onLocaleChanged);
    }
  }

  @override
  void dispose() {
    widget.localeController.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.localeController.strings;
    final direction = strings.isRtl ? TextDirection.rtl : TextDirection.ltr;
    return L10nScope(
      controller: widget.localeController,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: strings.t('app.title'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.light(),
        themeMode: ThemeMode.light,
        locale: Locale(strings.language.id),
        supportedLocales: const [Locale('en'), Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final page = child ?? const SizedBox.shrink();
          final updates = widget.updateController;
          return Directionality(
            textDirection: direction,
            child: updates == null
                ? page
                : UpdateBanner(controller: updates, child: page),
          );
        },
        home: HomeScreen(
          registry: widget.registry,
          repository: widget.repository,
        ),
      ),
    );
  }
}
