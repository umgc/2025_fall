import 'package:flutter/material.dart';

/// Header card for Patient Details.
/// Mirrors the mockup: bordered container, avatar, name/age/sex,
/// "Current Mood" with emoji/label, primary diagnoses chips, and red allergy pills.
class PatientHeaderCard extends StatelessWidget {
  final String fullName;
  final String mrn;
  final int age;
  final String sex;
  final String currentMoodLabel;
  final String currentMoodEmoji;
  final List<String> diagnoses;
  final List<String> allergies;

  const PatientHeaderCard({
    super.key,
    required this.fullName,
    required this.mrn,
    required this.age,
    required this.sex,
    required this.currentMoodLabel,
    required this.currentMoodEmoji,
    required this.diagnoses,
    required this.allergies,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final border = cs.outlineVariant.withValues(alpha: .35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name + MRN
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primary.withValues(alpha: .12),
                child: Text(
                  (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full name
                    Text(
                      fullName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Age • Sex
                    Text(
                      'Age $age • $sex',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
              ),
              // MRN (small, muted) as in the app bar subtitle; here we keep it subtle
            ],
          ),

          const SizedBox(height: 10),

          // Current Mood row
          Row(
            children: [
              Text(
                'Current Mood:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: .8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(currentMoodEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                currentMoodLabel,
                style: theme.textTheme.bodyMedium,
              ),
              // optional tiny alert icon (matches the red hint in mock)
              const SizedBox(width: 6),
              Icon(Icons.trending_down, size: 16, color: cs.error),
            ],
          ),

          const SizedBox(height: 14),

          // Primary Diagnoses
          if (diagnoses.isNotEmpty) ...[
            Text(
              'Primary Diagnoses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: diagnoses.map((d) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    d,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Allergies (solid red pills with white text)
          if (allergies.isNotEmpty) ...[
            Text(
              'Allergies',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergies.map((a) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    a,
                    style: TextStyle(
                      color: cs.onError,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: .2,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
