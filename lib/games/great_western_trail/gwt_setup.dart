import 'package:flutter/material.dart';

class GwtSetup extends StatelessWidget {
  const GwtSetup({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('First Edition scoring', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Fill this pad after the last Kansas City delivery. '
          'Coins: enter dollars (5 dollars = 1 VP). '
          'Kansas City deliveries are −6. Unmet objectives score negative. '
          'Workers left in columns 5–6 on your board are 4 VP each. '
          'The job market token is 2 VP for one player. The 3-VP disc is 0 or 3.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
