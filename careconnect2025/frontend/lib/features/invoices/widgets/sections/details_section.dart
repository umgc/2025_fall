// sections/details_section.dart
import 'package:flutter/material.dart';
import '../components/date_field.dart';
import '../../models/invoice_models.dart';

class DetailsSection extends StatelessWidget {
  const DetailsSection({
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
    final p = value.provider;
    final pt = value.patient;

    InputDecoration dec(String label) => const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ).copyWith(labelText: label);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Provider Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: p.name,
                decoration: dec('Provider Name'),
                onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(name: v))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: p.email ?? '',
                decoration: dec('Email'),
                onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(email: v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: p.phone,
                decoration: dec('Phone'),
                onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(phone: v))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: p.address,
                maxLines: 2,
                decoration: dec('Address'),
                onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(address: v))),
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        Text('Patient Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: pt.name,
                decoration: dec('Patient Name'),
                onChanged: (v) => onChanged(value.copyWith(patient: pt.copyWith(name: v))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                enabled: isEditing,
                initialValue: pt.accountNumber ?? '',
                decoration: dec('Account Number'),
                onChanged: (v) => onChanged(value.copyWith(patient: pt.copyWith(accountNumber: v))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: isEditing,
          initialValue: pt.billingAddress ?? '',
          maxLines: 3,
          decoration: dec('Billing Address'),
          onChanged: (v) => onChanged(value.copyWith(patient: pt.copyWith(billingAddress: v))),
        ),
        const Divider(height: 32),

        Text('Dates & Payment', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _responsiveDateRow(context),
        const SizedBox(height: 8),
        DateField(
          label: 'Paid Date (optional)',
          value: value.dates.paidDate,
          optional: true,
          enabled: isEditing,
          onChanged: (d) => onChanged(value.copyWith(dates: value.dates.copyWith(paidDate: d))),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<PaymentStatus>(
          value: value.paymentStatus,
          decoration: const InputDecoration(labelText: 'Payment Status', isDense: true),
          onChanged: isEditing ? (v) => onChanged(value.copyWith(paymentStatus: v)) : null,
          items: PaymentStatus.values
              .map((e) => DropdownMenuItem(value: e, child: Text(_label(e))))
              .toList(),
        ),
      ],
    );
  }

  Widget _responsiveDateRow(BuildContext context) {
    final d = value.dates;

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        final widgets = [
          DateField(
            label: 'Service Date',
            value: d.serviceDate,
            enabled: isEditing,
            onChanged: (v) => onChanged(value.copyWith(dates: d.copyWith(serviceDate: v))),
          ),
          DateField(
            label: 'Billed Date',
            value: d.billedDate,
            enabled: isEditing,
            onChanged: (v) => onChanged(value.copyWith(dates: d.copyWith(billedDate: v))),
          ),
          DateField(
            label: 'Due Date',
            value: d.dueDate,
            enabled: isEditing,
            onChanged: (v) => onChanged(value.copyWith(dates: d.copyWith(dueDate: v))),
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              widgets[0],
              const SizedBox(height: 8),
              widgets[1],
              const SizedBox(height: 8),
              widgets[2],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: widgets[0]),
            const SizedBox(width: 12),
            Expanded(child: widgets[1]),
            const SizedBox(width: 12),
            Expanded(child: widgets[2]),
          ],
        );
      },
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
