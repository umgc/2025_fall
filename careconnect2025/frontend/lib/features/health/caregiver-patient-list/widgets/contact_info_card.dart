import 'package:flutter/material.dart';

/// Patient Details — Contact Information
/// Pure presentational widget. Pass only what you have; rows hide if null/empty.
class ContactInfoCard extends StatelessWidget {
  final String? phone;                 // e.g., "(555) 123-4567"
  final String? email;                 // e.g., "patient@example.com"
  final DateTime? dateOfBirth;         // optional
  final String? addressLine1;          // "123 Main St"
  final String? addressLine2;          // "Apt 4B"
  final String? city;                  // "Springfield"
  final String? state;                 // "MD"
  final String? postalCode;            // "20910"

  /// Optional actions
  final VoidCallback? onCallPhone;
  final VoidCallback? onTextPhone;
  final VoidCallback? onSendEmail;

  const ContactInfoCard({
    super.key,
    this.phone,
    this.email,
    this.dateOfBirth,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.onCallPhone,
    this.onTextPhone,
    this.onSendEmail,
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
          Row(children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ]),
          const SizedBox(height: 16),

          if (_hasValue(phone))
            _row(
              context,
              icon: Icons.phone,
              label: 'Phone',
              value: phone!,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCallPhone != null)
                    IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call),
                      onPressed: onCallPhone,
                    ),
                  if (onTextPhone != null)
                    IconButton(
                      tooltip: 'Text',
                      icon: const Icon(Icons.sms),
                      onPressed: onTextPhone,
                    ),
                ],
              ),
            ),

          if (_hasValue(email))
            _row(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: email!,
              trailing: onSendEmail == null
                  ? null
                  : IconButton(
                tooltip: 'Send email',
                icon: const Icon(Icons.send),
                onPressed: onSendEmail,
              ),
            ),

          if (dateOfBirth != null)
            _row(
              context,
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: _fmtDate(dateOfBirth!),
            ),

          if (_hasAnyAddress)
            _row(
              context,
              icon: Icons.home_outlined,
              label: 'Address',
              value: _addressString(),
              isMultiline: true,
            ),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        Widget? trailing,
        bool isMultiline = false,
      }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  bool _hasValue(String? s) => s != null && s.trim().isNotEmpty;

  bool get _hasAnyAddress =>
      _hasValue(addressLine1) ||
          _hasValue(addressLine2) ||
          _hasValue(city) ||
          _hasValue(state) ||
          _hasValue(postalCode);

  String _addressString() {
    final lines = <String>[];
    final l1 = addressLine1?.trim();
    final l2 = addressLine2?.trim();
    final cityStr = city?.trim();
    final stateStr = state?.trim();
    final zipStr = postalCode?.trim();

    if (_hasValue(l1)) lines.add(l1!);
    if (_hasValue(l2)) lines.add(l2!);

    final last = [
      if (_hasValue(cityStr)) cityStr,
      if (_hasValue(stateStr)) stateStr,
      if (_hasValue(zipStr)) zipStr,
    ].whereType<String>().join(', ').replaceAll(', ,', ',').replaceAll(' ,', ',');
    if (_hasValue(last)) lines.add(last);

    return lines.join('\n');
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
    // If you prefer intl: DateFormat('MMM d, y').format(d);
  }
}
