import 'package:care_connect_app/features/health/medication-tracker/models/medication-model.dart';
import 'package:flutter/material.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final Function(MedicationStatus) onStatusChanged;

  const MedicationCard({
    Key? key,
    required this.medication,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.dosage} • ${medication.frequency}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(medication.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Next dose: ${medication.nextDose}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Method of delivery: ${medication.deliveryMethod}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MedicationStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case MedicationStatus.upcoming:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        text = 'upcoming';
        break;
      case MedicationStatus.taken:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        text = 'taken';
        break;
      case MedicationStatus.missed:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        text = 'missed';
        break;
    }

    return GestureDetector(
      onTap: () {
        // Cycle through statuses when tapped
        MedicationStatus newStatus;
        switch (status) {
          case MedicationStatus.upcoming:
            newStatus = MedicationStatus.taken;
            break;
          case MedicationStatus.taken:
            newStatus = MedicationStatus.missed;
            break;
          case MedicationStatus.missed:
            newStatus = MedicationStatus.upcoming;
            break;
        }
        onStatusChanged(newStatus);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
