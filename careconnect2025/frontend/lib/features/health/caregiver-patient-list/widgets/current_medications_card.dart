import 'package:flutter/material.dart';
import '../models/medication_entry.dart';

/// Patient Details → Health tab
class CurrentMedicationsSection extends StatelessWidget {
  final List<MedicationEntry> entries;
  final String title; // defaults to 'Current Medications'

  const CurrentMedicationsSection({
    super.key,
    required this.entries,
    this.title = 'Current Medications',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Critical first, then alphabetical
    final meds = List<MedicationEntry>.from(entries)
      ..sort((a, b) {
        if (a.isCritical != b.isCritical) return a.isCritical ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
          // Section header
          Row(
            children: [
              Icon(Icons.vaccines_outlined,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (meds.isEmpty)
            const _EmptyState(message: 'No current medications')
          else
            Column(
              children: List.generate(
                meds.length,
                    (i) => _MedicationBlock(med: meds[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationBlock extends StatelessWidget {
  final MedicationEntry med;
  const _MedicationBlock({required this.med});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = med.complianceClamped; // int 0..100

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
          // Name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusBadge(status: med.status, isCritical: med.isCritical),
            ],
          ),
          const SizedBox(height: 8),

          // Dosage / Frequency
          Row(
            children: [
              Expanded(child: _kv(context, 'Dosage', med.dosage)),
              const SizedBox(width: 12),
              Expanded(child: _kv(context, 'Frequency', med.frequency)),
            ],
          ),
          const SizedBox(height: 8),

          // Started / Last taken
          Row(
            children: [
              Expanded(child: _kv(context, 'Started', _formatDate(med.startedOn))),
              const SizedBox(width: 12),
              Expanded(
                child: _kv(
                  context,
                  'Last Taken',
                  _formatDateTime(med.lastTakenAt),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Compliance
          Text(
            'Compliance',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct / 100.0,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    color: _complianceColor(context, pct.toDouble()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Color _complianceColor(BuildContext context, double pct) {
    if (pct >= 90) return Colors.green.shade600;
    if (pct >= 70) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _formatDateTime(DateTime d) {
    final h = d.hour > 12 ? d.hour - 12 : d.hour == 0 ? 12 : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(d)}, $h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final MedicationStatus status;
  final bool isCritical;

  const _StatusBadge({required this.status, required this.isCritical});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color bg;
    Color fg;
    String text;

    if (isCritical) {
      bg = cs.error;
      fg = cs.onError;
      text = 'critical';
    } else {
      switch (status) {
        case MedicationStatus.active:
          bg = Colors.blue.shade900;
          fg = Colors.white;
          text = 'active';
          break;
        case MedicationStatus.paused:
          bg = cs.tertiary; // amber-like in many schemes
          fg = cs.onTertiary;
          text = 'paused';
          break;
        case MedicationStatus.discontinued:
          bg = cs.surfaceContainerHighest.withValues(alpha: 0.6);
          fg = cs.onSurface;
          text = 'discontinued';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: .2,
        ),
      ),
    );
  }
}

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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.local_pharmacy_outlined,
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
