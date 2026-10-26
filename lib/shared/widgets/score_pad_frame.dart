import 'package:flutter/material.dart';

import '../export/score_sheet_export.dart';

/// The rounded card around a game's score pad table.
///
/// The card is never wider than the table, so its outline (drawn in
/// [gridColor], over the clipped corners) hugs the table edges. When the
/// players don't fit, the table scrolls sideways inside it.
class ScorePadFrame extends StatelessWidget {
  const ScorePadFrame({
    super.key,
    required this.tableWidth,
    required this.color,
    required this.gridColor,
    required this.child,
  });

  final double tableWidth;
  final Color color;
  final Color gridColor;

  /// The table's rows; laid out at [tableWidth].
  final Widget child;

  static const radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: tableWidth),
      child: Card(
        // No margin: the table is sized to the full width, and a margin
        // would leave it a few pixels too wide.
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: gridColor),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // Marks the full table (even scrolled off) for "Save image".
          child: ScoreSheetExportTarget(
            child: SizedBox(width: tableWidth, child: child),
          ),
        ),
      ),
    );
  }
}
