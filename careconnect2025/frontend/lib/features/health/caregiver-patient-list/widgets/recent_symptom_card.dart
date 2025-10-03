import 'package:flutter/material.dart';
import '../models/symptom_entry.dart';

/// Patient Details → Health tab (Symptoms)
class RecentSymptomsSection extends StatelessWidget {
  final List<SymptomEntry> entries;
  final String title; // default: 'Recent Symptoms'

  const RecentSymptomsSection({
    super.key,
    required this.entries,
    this.title = 'Recent Symptoms',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // newest first (do not mutate caller list)
    final items = List<SymptomEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (items.isEmpty)
            const _EmptyState(message: 'No recent symptoms')
          else
            Column(
              children: [
                for (final e in items) _SymptomEntryTile(entry: e),
              ],
            ),
        ],
      ),
    );
  }
}

/// ---- private tile (kept inside this file) ----
class _SymptomEntryTile extends StatelessWidget {
  final SymptomEntry entry;
  const _SymptomEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, label) = _severityBadge(theme.colorScheme, entry.severity);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: date + severity pill
          Row(
            children: [
              Text(
                _fmtDate(entry.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Primary symptom name as a small chip (optional look)
          if (entry.name.trim().isNotEmpty) ...[
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                  theme.colorScheme.outline.withValues(alpha: 0.25),
                ),
              ),
              child: (() {
                final isNoSymptoms =
                    entry.name.trim().toLowerCase() == 'no symptoms reported';
                if (isNoSymptoms) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: Colors.green.shade600),
                      const SizedBox(width: 6),
                      Text(
                        entry.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade600, // green text
                        ),
                      ),
                    ],
                  );
                } else {
                  return Text(
                    entry.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
              })(),
            ),
            const SizedBox(height: 8),
          ],

          // Note/description (optional)
          if (entry.note != null && entry.note!.trim().isNotEmpty)
            Text(
              entry.note!.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                theme.colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
        ],
      ),
    );
  }

  static (Color, Color, String) _severityBadge(
      ColorScheme cs,
      String raw,
      ) {
    final s = raw.toLowerCase().trim();
    if (s == 'severe') {
    return (cs.error, cs.onError, 'severe');
    }
    if (s == 'moderate') {
    return (Colors.orange.shade600, Colors.white, 'moderate');
    }
    return (Colors.green.shade600, Colors.white, 'mild');
    }

  static String _fmtDate(DateTime d) {
    const mm = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${mm[d.month - 1]} ${d.day}';
  }
}

/// Empty state block
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.insert_comment_outlined,
              size: 28, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
