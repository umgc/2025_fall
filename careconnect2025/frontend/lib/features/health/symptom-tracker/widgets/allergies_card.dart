import 'package:flutter/material.dart';

class AllergyCard extends StatelessWidget {
  final String drug;
  final String reaction;
  final String severity;
  final String note;
  final VoidCallback onDelete;

  const AllergyCard({
    Key? key,
    required this.drug,
    required this.reaction,
    required this.severity,
    required this.note,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onDelete,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drug,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text('Reaction: $reaction'),
              Text('Severity: $severity'),
              Text(note),
            ],
          ),
        ],
      ),
    );
  }
}
