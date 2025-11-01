import 'package:flutter/material.dart';

class ActivityEntry {
  final String title;
  final String when;

  const ActivityEntry({required this.title, required this.when});
}

class RecentActivityTab extends StatelessWidget {
  final List<ActivityEntry> items;

  const RecentActivityTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Section header
        Text(
          'Recent Activity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.primary, // keep teal
          ),
        ),
        const SizedBox(height: 12),

        // Rows
        for (int i = 0; i < items.length; i++) ...[
          _ActivityRow(
            title: items[i].title,
            when: items[i].when,
            primary: cs.primary,
          ),
          if (i != items.length - 1)
            Divider(height: 20, thickness: 0.5, color: cs.outlineVariant),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String when;
  final Color primary;

  const _ActivityRow({
    required this.title,
    required this.when,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teal accent bar
        Container(
          width: 3,
          height: 40,
          margin: const EdgeInsets.only(top: 4, right: 12),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Text block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title → now black
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black, // ← only this changed
                ),
              ),
              const SizedBox(height: 2),
              // Timestamp
              Text(
                when,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
