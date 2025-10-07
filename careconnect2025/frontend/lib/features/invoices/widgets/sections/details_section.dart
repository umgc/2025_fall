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
<<<<<<< HEAD
=======
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
>>>>>>> origin/team_d_ocr_textract
        ).copyWith(labelText: label);

    return ListView(
      padding: const EdgeInsets.all(16),
<<<<<<< HEAD
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
=======
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Provider
        Text('Provider Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _TwoUpOrStack(
          children: [
            TextFormField(
              enabled: isEditing,
              initialValue: p.name,
              decoration: dec('Provider Name'),
              textInputAction: TextInputAction.next,
              onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(name: v))),
            ),
            TextFormField(
              enabled: isEditing,
              initialValue: p.email ?? '',
              decoration: dec('Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(email: v))),
>>>>>>> origin/team_d_ocr_textract
            ),
          ],
        ),
        const SizedBox(height: 8),
<<<<<<< HEAD
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
=======
        _TwoUpOrStack(
          children: [
            TextFormField(
              enabled: isEditing,
              initialValue: p.phone,
              decoration: dec('Phone'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(phone: v))),
            ),
            TextFormField(
              enabled: isEditing,
              initialValue: p.address,
              maxLines: 3,
              decoration: dec('Address'),
              onChanged: (v) => onChanged(value.copyWith(provider: p.copyWith(address: v))),
            ),
          ],
        ),

        const Divider(height: 32),

        // Patient
        Text('Patient Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _TwoUpOrStack(
          children: [
            TextFormField(
              enabled: isEditing,
              initialValue: pt.name,
              decoration: dec('Patient Name'),
              textInputAction: TextInputAction.next,
              onChanged: (v) => onChanged(value.copyWith(patient: pt.copyWith(name: v))),
            ),
            TextFormField(
              enabled: isEditing,
              initialValue: pt.accountNumber ?? '',
              decoration: dec('Account Number'),
              textInputAction: TextInputAction.next,
              onChanged: (v) => onChanged(value.copyWith(patient: pt.copyWith(accountNumber: v))),
>>>>>>> origin/team_d_ocr_textract
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
<<<<<<< HEAD
        const Divider(height: 32),

=======

        const Divider(height: 32),

        // Dates & Payment
>>>>>>> origin/team_d_ocr_textract
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
<<<<<<< HEAD
          decoration: const InputDecoration(labelText: 'Payment Status', isDense: true),
=======
          decoration: const InputDecoration(
            labelText: 'Payment Status',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
>>>>>>> origin/team_d_ocr_textract
          onChanged: isEditing ? (v) => onChanged(value.copyWith(paymentStatus: v)) : null,
          items: PaymentStatus.values
              .map((e) => DropdownMenuItem(value: e, child: Text(_label(e))))
              .toList(),
        ),
      ],
    );
  }

<<<<<<< HEAD
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

=======
  // Stacks children vertically on narrow screens; side-by-side otherwise.
  Widget _TwoUpOrStack({required List<Widget> children}) {
    assert(children.length == 2);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 520;
        if (narrow) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 12),
              children[1],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 12),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }

  Widget _responsiveDateRow(BuildContext context) {
    final d = value.dates;

    final widgets = [
      DateField(
        label: 'Statement Date',
        value: d.statementDate,
        enabled: isEditing,
        onChanged: (v) => onChanged(value.copyWith(dates: d.copyWith(statementDate: v))),
      ),
      DateField(
        label: 'Due Date',
        value: d.dueDate,
        enabled: isEditing,
        onChanged: (v) => onChanged(value.copyWith(dates: d.copyWith(dueDate: v))),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 680;
>>>>>>> origin/team_d_ocr_textract
        if (narrow) {
          return Column(
            children: [
              widgets[0],
<<<<<<< HEAD
              const SizedBox(height: 8),
              widgets[1],
              const SizedBox(height: 8),
              widgets[2],
=======
              const SizedBox(height: 12),
              widgets[1],
>>>>>>> origin/team_d_ocr_textract
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: widgets[0]),
            const SizedBox(width: 12),
            Expanded(child: widgets[1]),
<<<<<<< HEAD
            const SizedBox(width: 12),
            Expanded(child: widgets[2]),
=======
>>>>>>> origin/team_d_ocr_textract
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
