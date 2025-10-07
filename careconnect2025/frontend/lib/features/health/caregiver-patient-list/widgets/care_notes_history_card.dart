import 'package:flutter/material.dart';
import '../models/care_note.dart';

/// Card: "Care Notes History"
class CareNotesHistoryCard extends StatelessWidget {
  final List<CareNote> notes;

  const CareNotesHistoryCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Newest first (UI-friendly default)
    final items = List<CareNote>.from(notes)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.10),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Care Notes History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (items.isEmpty)
            const _NotesEmptyState(message: 'No care notes yet')
          else
          // Better for long lists than a big Column
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _CareNoteTile(note: items[i]),
            ),
        ],
      ),
    );
  }
}

/// Internal tile for a single care note row.
class _CareNoteTile extends StatelessWidget {
  final CareNote note;
  const _CareNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, label) = _badgeColors(theme.colorScheme, note.type);

    return Semantics(
      label:
      'Care note ${label.isEmpty ? "" : "type $label, "}by ${note.author}, on ${_formatFullDateTime(note.createdAt)}',
      child: Container(
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
            // First row: badge • author • role • timestamp
            Row(
              children: [
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
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: .2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          note.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if ((note.role ?? '').isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          note.role!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.60),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatFullDateTime(note.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Body text
            Text(
              note.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color, String) _badgeColors(ColorScheme cs, String typeRaw) {
    final type = typeRaw.toLowerCase().trim();
    switch (type) {
      case 'urgent':
        return (Colors.red.shade600, Colors.white, 'urgent');
      case 'assessment':
        return (Colors.blue.shade800, Colors.white, 'assessment');
      case 'medication':
        return (Colors.orange.shade600, Colors.white, 'medication');
      default:
        return (
        Colors.grey.shade300,
        Colors.black87,
        'general'
        );
    }
  }

  static String _formatFullDateTime(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} • $h:$mm $amPm';
  }
}

/// Empty state used when there are no notes.
class _NotesEmptyState extends StatelessWidget {
  final String message;
  const _NotesEmptyState({required this.message});

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
          Icon(Icons.note_alt_outlined,
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
