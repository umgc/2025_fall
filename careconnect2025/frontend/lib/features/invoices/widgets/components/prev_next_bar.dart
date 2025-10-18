// components/prev_next_bar.dart
import 'package:flutter/material.dart';

class PrevNextBar extends StatelessWidget {
  const PrevNextBar({
    super.key,
    required this.canPrev,
    required this.isLast,
    required this.onPrev,
    required this.onNextOrSave,
  });

  final bool canPrev;
  final bool isLast;
  final VoidCallback onPrev;
  final VoidCallback onNextOrSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: canPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Prev'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onNextOrSave,
              icon: Icon(isLast ? Icons.save : Icons.chevron_right),
              label: Text(isLast ? 'Save' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }
}
