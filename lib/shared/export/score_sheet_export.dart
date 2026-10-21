import 'package:flutter/widgets.dart';

/// Provided by the play screen so a game's sheet can mark the part that
/// "Save image" captures.
class ScoreSheetExportScope extends InheritedWidget {
  const ScoreSheetExportScope({
    super.key,
    required this.captureKey,
    required super.child,
  });

  final GlobalKey captureKey;

  static GlobalKey? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ScoreSheetExportScope>()
        ?.captureKey;
  }

  @override
  bool updateShouldNotify(ScoreSheetExportScope oldWidget) {
    return captureKey != oldWidget.captureKey;
  }
}

/// Wrap a sheet's score table in this to make it the saved image. Captures
/// the whole table even when it scrolls horizontally on a phone.
class ScoreSheetExportTarget extends StatelessWidget {
  const ScoreSheetExportTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final captureKey = ScoreSheetExportScope.maybeOf(context);
    if (captureKey == null) {
      return child;
    }
    return RepaintBoundary(key: captureKey, child: child);
  }
}
