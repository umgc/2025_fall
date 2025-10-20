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
    this.showPdf = true,
  });

  final bool isEditing;
  final bool isNew;
  final bool showPdf;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onPdf;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Use AppBar colors for good contrast without touching global theme.
    final cs = Theme.of(context).colorScheme;
    final onPrimary = Colors.white;

    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: onPrimary,
      side: const BorderSide(color: Colors.white70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    final filledPrimaryOnWhite = FilledButton.styleFrom(
      backgroundColor: onPrimary,
      foregroundColor: cs.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (isEditing)
            OutlinedButton.icon(
              style: outlinedStyle,
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              label: Text(isNew ? 'Discard' : 'Cancel'),
            ),
          if (isEditing) const SizedBox(width: 8),
          if (isEditing)
            FilledButton.icon(
              style: filledPrimaryOnWhite,
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          if (!isEditing)
            OutlinedButton.icon(
              style: outlinedStyle,
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
            ),
          const SizedBox(width: 8),
          if (showPdf)
            OutlinedButton.icon(
              style: outlinedStyle,
              onPressed: onPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
          if (showPdf) const SizedBox(width: 8),
          OutlinedButton.icon(
            style: outlinedStyle,
            onPressed: onClose,
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
