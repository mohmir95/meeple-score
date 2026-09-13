import 'package:flutter/material.dart';

class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;
  static const double contentMaxWidth = 1040;

  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < compact;
  }

  static int gameGridCount(double width) {
    if (width < medium) {
      return 2;
    }
    return 3;
  }
}
