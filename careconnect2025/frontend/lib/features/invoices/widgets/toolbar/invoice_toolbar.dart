// toolbar/invoice_toolbar.dart
import 'package:flutter/material.dart';

class InvoiceToolbar extends StatelessWidget {
  const InvoiceToolbar({
    super.key,
    required this.isEditing,
    required this.isNew,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.onPdf,
    required this.onClose,
    this.showPdf = true, // NEW
  });

  final bool isEditing;
  final bool isNew;
  final bool showPdf; // NEW
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onPdf;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (isEditing)
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: Text(isNew ? 'Discard' : 'Cancel'),
            ),
          if (isEditing) const SizedBox(width: 8),
          if (isEditing)
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          if (!isEditing)
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          const SizedBox(width: 8),

          // Only show for non-new invoices
          if (showPdf)
            OutlinedButton.icon(
              onPressed: onPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),

          if (showPdf) const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
