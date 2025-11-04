import 'package:flutter/material.dart';

class PainLevelCard extends StatelessWidget {
  const PainLevelCard({
    super.key,
    required this.lastReportedText,
    required this.currentPain, // 0–10
    required this.location,
    required this.dizziness, // 0–10
    required this.fatigue, // 0–10
  });

  final String lastReportedText;
  final int currentPain;
  final String location;
  final int dizziness;
  final int fatigue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget barRow({
      required String title,
      required int score, // 0–10
      String? subLabelLeft,
      String? subLabelRight,
    }) {
      final value = (score.clamp(0, 10)) / 10.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + score (e.g., "4/10")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '$score/10',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8, // smaller to match symptom card
                color: cs.primary,
                backgroundColor: cs.surfaceVariant.withOpacity(.6),
              ),
            ),
            const SizedBox(height: 4),

            // Range labels (optional)
            if (subLabelLeft != null || subLabelRight != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subLabelLeft ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.7),
                    ),
                  ),
                  Text(
                    subLabelRight ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(.7),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Pain Level',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last reported $lastReportedText',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(.7),
              ),
            ),
            const SizedBox(height: 12),

            // Current Pain
            barRow(
              title: 'Current Pain',
              score: currentPain,
              subLabelLeft: 'No Pain',
              subLabelRight: 'Severe',
            ),
            Text(
              'Location: $location',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Dizziness
            barRow(
              title: 'Dizziness',
              score: dizziness,
              subLabelLeft: 'None',
              subLabelRight: 'Severe',
            ),

            // Fatigue
            barRow(
              title: 'Fatigue',
              score: fatigue,
              subLabelLeft: 'None',
              subLabelRight: 'Severe',
            ),
          ],
        ),
      ),
    );
  }
}
