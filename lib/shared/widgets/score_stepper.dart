import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScoreStepper extends StatelessWidget {
  const ScoreStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min,
    this.max,
    this.label,
    this.large = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int step;
  final int? min;
  final int? max;
  final String? label;
  final bool large;

  int _clamp(int next) {
    var result = next;
    if (min != null && result < min!) {
      result = min!;
    }
    if (max != null && result > max!) {
      result = max!;
    }
    return result;
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    final next = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(label == null ? 'Enter score' : 'Score for $label'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Points',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (text) {
              Navigator.of(dialogContext).pop(int.tryParse(text) ?? value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(int.tryParse(controller.text) ?? value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (next != null) {
      onChanged(_clamp(next));
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = large ? 56.0 : 40.0;
    final iconSize = large ? 28.0 : 22.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (label != null) ...[
          Expanded(
            child: Text(
              label!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
        IconButton.filledTonal(
          tooltip: 'Decrease',
          onPressed: () => onChanged(_clamp(value - step)),
          style: IconButton.styleFrom(
            minimumSize: Size(buttonSize, buttonSize),
            iconSize: iconSize,
          ),
          icon: const Icon(Icons.remove),
        ),
        InkWell(
          onTap: () => _edit(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: large ? 20 : 12,
              vertical: large ? 12 : 8,
            ),
            child: Text(
              '$value',
              style: large
                  ? Theme.of(context).textTheme.displaySmall
                  : Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Increase',
          onPressed: () => onChanged(_clamp(value + step)),
          style: IconButton.styleFrom(
            minimumSize: Size(buttonSize, buttonSize),
            iconSize: iconSize,
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
