import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// When null, the button fills the width on phones and hugs its label on PC.
  final bool? expanded;

  @override
  Widget build(BuildContext context) {
    final fill = expanded ?? Breakpoints.isCompact(context);
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.check),
      label: Text(label),
    );

    if (!fill) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}
