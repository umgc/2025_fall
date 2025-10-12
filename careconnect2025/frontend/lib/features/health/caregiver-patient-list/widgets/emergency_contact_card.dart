import 'package:flutter/material.dart';

/// Patient Details — Emergency Contact (
class EmergencyContactCard extends StatelessWidget {
  final String contactName;        // e.g., "Michael Johnson"
  final String relationship;       // e.g., "Spouse"
  final String? phone;             // optional
  final String? email;             // optional (shown under phone if provided)

  const EmergencyContactCard({
    super.key,
    required this.contactName,
    required this.relationship,
    this.phone,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          // Title row
          Row(
            children: [
              Icon(Icons.contact_emergency,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inner compact panel (matches mockup)
          Container(
            width: double.infinity,
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
                // Name
                Text(
                  contactName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Relationship (small, gray)
                Text(
                  relationship,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Phone
                if (_hasValue(phone))
                  Text(
                    phone!,
                    style: theme.textTheme.bodyMedium,
                    softWrap: true,
                  ),
                // Email (optional, shown under phone if you pass it)
                if (_hasValue(email)) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                    softWrap: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? s) => s != null && s.trim().isNotEmpty;
}
