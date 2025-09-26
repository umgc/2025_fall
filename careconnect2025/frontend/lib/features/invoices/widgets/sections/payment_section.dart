// sections/payment_section.dart
import 'package:flutter/material.dart';
import '../../models/invoice_models.dart';

class PaymentSection extends StatelessWidget {
  const PaymentSection({
    super.key,
    required this.value,
    required this.isEditing,
    required this.onChanged,
  });

  final Invoice value;
  final bool isEditing;
  final ValueChanged<Invoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final paid = value.paymentStatus == PaymentStatus.paid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Payment Options', style: Theme.of(context).textTheme.titleMedium),
            Chip(
              label: Text(_label(value.paymentStatus)),
              backgroundColor: paid
                  ? const Color(0xFF059669)
                  : value.paymentStatus == PaymentStatus.rejectedInsurance
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.secondary,
              labelStyle: const TextStyle(color: Colors.white),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_money),
              label: const Text('Record Payment'),
              onPressed: () async {
                // Show your existing dialog here and update value via onChanged(...)
                // Keep this section dumb. Let page own the dialog if you prefer.
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (value.paymentReferences.paymentLink != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Online Payment Available'),
              subtitle: const Text("Pay online using the provider's secure payment portal."),
              trailing: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.open_in_new),
                label: const Text('Pay Now'),
              ),
            ),
          ),
        if (value.checkPayableTo != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Check Payment Instructions', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Make check payable to: ${value.checkPayableTo!.name}'),
                Text('Mail payment to: ${value.checkPayableTo!.address}'),
                Text('Include invoice number: ${value.invoiceNumber}'),
              ]),
            ),
          ),
      ],
    );
  }

  String _label(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.pendingInsurance:
        return 'Pending Insurance';
      case PaymentStatus.sent:
        return 'Sent';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partialPayment:
        return 'Partial Payment';
      case PaymentStatus.rejectedInsurance:
        return 'Rejected by Insurance';
    }
  }
}
